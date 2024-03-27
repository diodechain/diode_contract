// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./deps/IERC20.sol";
import "./deps/Diode.sol";
import "./deps/Utils.sol";
import "./deps/SafeMath.sol";
import "./IFleetContract.sol";
import "./DiodeStakeLight.sol";

/**
 * DiodeRegistry
 *
 * This registry implements
 *
 * 1. Registering Fleets & Devices
 *
 * 2. Submitting Service Tickets for Traffic and Connections
 *
 * 3. Per block evaluation
 * 3. 1. including distributing block rewards
 * 3. 2. including end of epoch distribution of service rewards
 *
 * NOTES:
 *    submitTicket is not secure because it depends on Fleetcontract.checkDevice
 *
 */

contract DiodeRegistryLight is DiodeStakeLight {
    using SafeMath for uint256;

    uint256 currentEpoch;
    uint64 constant SecondsPerEpoch = 2_592_000;
    uint64 constant Fractionals = 1000;
    address payable immutable Foundation;
    IERC20 immutable Token;

    /**
     * Accounting Epochs run in two phases:
     *
     * EPOCH 0        | EPOCH 1       | EPOCH 2 ...
     * ============================================
     * 1. Collecting  |               |
     * 2. Submitting  | 1. Collecting |
     *    Payout      | 2. Submitting |  1. Collecting
     *                |    Payout     |  2. Submitting
     *                                |     Payout
     *
     * For accounting the activity from devices we maintain a three
     * level tree of iterable maps:
     *
     * FleetContracts => Miners(aka Nodes) => Devices(aka Client)
     *
     *   fleetStats[fleet].nodeStats[node].clientStats[client]
     *
     * Each device ticket is stored into this tree ensuring that
     * device activity is deduplicated on a per-node basis.
     *
     * Rollups of the total counts are done on the Nodes level as
     * well as on the Fleet level.
     *
     */
    address[] public rollupArray;
    mapping(address => uint256) rollupReward;

    // These two together form an iterable map for this Epochs activity
    IFleetContract[] fleetArray;
    mapping(address => FleetStats) fleetStats;
    function _fleetStats(
        IFleetContract _fleet
    ) internal view returns (FleetStats storage) {
        return fleetStats[address(_fleet)];
    }

    uint256 currentEpochStart;
    uint256 previousEpochStart;

    // ==================== DATA STRUCTURES ==================
    struct FleetStats {
        bool exists;
        uint256 totalConnections;
        uint256 totalBytes;
        // These two together form an iterable map
        address[] nodeArray;
        mapping(address => NodeStats) nodeStats;
    }

    struct NodeStats {
        bool exists;
        uint256 totalConnections;
        uint256 totalBytes;
        // These two together form an iterable map
        address[] clientArray;
        mapping(address => ClientStats) clientStats;
    }

    struct ClientStats {
        bool exists;
        uint256 clientIndex;
        uint256 totalConnections;
        uint256 totalBytes;
    }

    modifier lastEpoch(uint256 blockHeight) {
        require(blockHeight < block.number, "Ticket from the future?");
        require(blockHeight > previousEpochStart, "Wrong epoch");
        _;
    }

    event Ticket(
        IFleetContract indexed fleetContract,
        address indexed node,
        address indexed client
    );

    event Rewards(address indexed node, uint256 indexed amount);

    constructor(address payable _foundation, IERC20 _token) DiodeStakeLight() {
        Foundation = _foundation;
        Token = _token;
        currentEpoch = Epoch();
        currentEpochStart = block.number;
        previousEpochStart = block.number;
    }

    // BlockTimeGoal is 15 seconds
    // One Epoch should be roughly one month
    function Epoch() public view returns (uint256) {
        return block.timestamp.div(SecondsPerEpoch);
    }

    function endEpoch() private {
        // This call is private and only done in the per block call
        if (currentEpoch == Epoch()) revert("Can't end the current epoch");

        // Each fleet has a total value
        // We do have a fixed amount of revenue to distribute
        // Each fleets value should be distributed by share
        // We need to calculcate those shares first, by generating the total sum

        // ==ConnectionTickets (CTs)
        // CTs are calculcated as worth 1kb or traffic or 1024 totalBytes in
        // TrafficTickets (TTs)

        // ==Reward
        // Is either the sum of all active Fleet Contracts or the Value of all
        // each registered...
        // It's easier to just calculcate the value of each fleet contract
        // We distribute each round %1 percent of Fleet Contract Stake

        // Q: Is it better to copy fleetArray.length into a uint256 local var first?
        for (uint f = 0; f < fleetArray.length; f++) {
            endEpochForFleet(fleetArray[f]);
        }
        // Global cleanup
        delete fleetArray;

        // Update epoch
        currentEpoch = Epoch();
        currentEpochStart = block.timestamp;
    }

    function endEpochForFleet(IFleetContract fleetContract) internal {
        uint256 fleetValue = _contractValue(fleetContract);
        uint256 reward = fleetValue.div(100);

        if (reward == 0) return;

        FleetStats storage fleet = _fleetStats(fleetContract);
        uint256 fleetPoints = fleet.totalBytes.add(
            fleet.totalConnections.mul(1024)
        );
        if (fleetPoints == 0) return;

        for (uint256 n = 0; n < fleet.nodeArray.length; n++) {
            address nodeAddress = fleet.nodeArray[n];
            NodeStats storage node = fleet.nodeStats[nodeAddress];

            uint256 nodePoints = node.totalBytes.add(
                node.totalConnections.mul(1024)
            );
            // Out of all delivered fleetPoints the nodePoints are attributable to this node
            // next we're calculcating the corresponding reward from the reward pool of this fleet.
            // This nodes reward = nodePoints * (reward / fleetPoints)
            // This is multipled with 1000 to account for fractionals, needs to be divided
            // after summation.
            // uint256 nodeReward = nodePoints.mul(Fractionals).mul(reward).div(fleetPoints);
            nodePoints = nodePoints.mul(Fractionals).mul(reward).div(
                fleetPoints
            );

            // Summarizing in one reward per node to be applying capping and allow fractionals
            _rollup(nodeAddress, nodePoints);

            for (uint256 c = 0; c < node.clientArray.length; c++) {
                // Client Map Cleanup
                delete node.clientStats[node.clientArray[c]];
            }
            // Node Cleanup
            delete fleet.nodeStats[nodeAddress];
        }
        // Fleet Cleanup
        delete fleetStats[address(fleetContract)];
    }

    function _rollup(address miner, uint256 value) internal {
        if (value > 0) {
            if (rollupReward[miner] == 0) {
                rollupArray.push(miner);
            }
            rollupReward[miner] = rollupReward[miner].add(value);
        }
    }

    /**
     * Submit one or more connection tickets raw
     *
     * Connection tickets
     *
     * [0] block height
     * [1] fleet contract address
     * [2] node address
     * [3] total connections
     * [4] total bytes
     * [5] local address
     * [6] client sig r
     * [7] client sig s
     * [8] client sig v
     *
     * Requires an array with a length multiple of 9. Each 9 elements representing
     * a single connection ticket.
     */
    function SubmitTicketRaw(bytes32[] calldata _connectionTicket) external {
        if (_connectionTicket.length == 0 || _connectionTicket.length % 9 != 0)
            revert("Invalid ticket length");

        for (uint256 i = 0; i < _connectionTicket.length; i += 9) {
            bytes32[3] memory deviceSignature = [
                _connectionTicket[i + 6],
                _connectionTicket[i + 7],
                _connectionTicket[i + 8]
            ];
            SubmitTicket(
                uint256(_connectionTicket[i + 0]),
                IFleetContract(
                    Utils.bytes32ToAddress(_connectionTicket[i + 1])
                ),
                Utils.bytes32ToAddress(_connectionTicket[i + 2]),
                uint256(_connectionTicket[i + 3]),
                uint256(_connectionTicket[i + 4]),
                _connectionTicket[i + 5],
                deviceSignature
            );
        }
    }

    function SubmitTicket(
        uint256 blockHeight,
        IFleetContract fleetContract,
        address nodeAddress,
        uint256 totalConnections,
        uint256 totalBytes,
        bytes32 localAddress,
        bytes32[3] memory signature
    ) public lastEpoch(blockHeight) {
        require(totalConnections | totalBytes != 0, "Invalid ticket value");

        // ======= CLIENT SIGNATURE RECOVERY =======
        bytes32[] memory message = new bytes32[](6);
        message[0] = blockhash(blockHeight);
        message[1] = Utils.addressToBytes32(address(fleetContract));
        message[2] = Utils.addressToBytes32(nodeAddress);
        message[3] = bytes32(totalConnections);
        message[4] = bytes32(totalBytes);
        message[5] = localAddress;

        address client = ecrecover(
            Utils.bytes32Hash(message),
            uint8(uint256(signature[2])),
            signature[0],
            signature[1]
        );
        // ======= END =======

        validateFleetAccess(fleetContract, client);
        updateTrafficCount(
            fleetContract,
            nodeAddress,
            client,
            totalConnections,
            totalBytes
        );

        emit Ticket(fleetContract, nodeAddress, client);
    }

    // ====================================================================================
    // ============================= EXPLORATIVE ACCESSORS ================================
    // ====================================================================================

    // These types only exist for external accessors, hence avoid using mappings
    struct Fleet {
        IFleetContract fleet;
        uint256 totalConnections;
        uint256 totalBytes;
        address[] nodes;
    }

    struct Node {
        address node;
        uint256 totalConnections;
        uint256 totalBytes;
        Client[] clients;
    }

    struct Client {
        address client;
        uint256 totalConnections;
        uint256 totalBytes;
    }

    // These functions are only called by Web3 contract explorers
    function EpochFleets() external view returns (IFleetContract[] memory) {
        return fleetArray;
    }

    function EpochFleet(
        IFleetContract _fleet
    ) external view returns (Fleet memory) {
        FleetStats storage stats = _fleetStats(_fleet);
        return
            Fleet(
                _fleet,
                stats.totalConnections,
                stats.totalBytes,
                stats.nodeArray
            );
    }

    function EpochFleetNode(
        IFleetContract _fleet,
        address _node
    ) external view returns (Node memory) {
        FleetStats storage stats = _fleetStats(_fleet);
        NodeStats storage nstats = stats.nodeStats[_node];
        uint len = nstats.clientArray.length;
        Node memory node = Node(
            _node,
            nstats.totalConnections,
            nstats.totalBytes,
            new Client[](len)
        );

        for (uint i = 0; i < len; i++) {
            address client = nstats.clientArray[i];
            ClientStats memory cstats = nstats.clientStats[client];
            node.clients[i] = Client(
                client,
                cstats.totalConnections,
                cstats.totalBytes
            );
        }

        return node;
    }

    function CurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    // ====================================================================================
    // ============================= INTERNAL FUNCTIONS ===================================
    // ====================================================================================
    function updateTrafficCount(
        IFleetContract fleetContract,
        address nodeAddress,
        address clientAddress,
        uint256 totalConnections,
        uint256 totalBytes
    ) internal {
        FleetStats storage fleet = _fleetStats(fleetContract);

        if (fleet.exists == false) {
            fleet.exists = true;
            fleetArray.push(fleetContract);
        }

        NodeStats storage node = fleet.nodeStats[nodeAddress];
        if (node.exists == false) {
            node.exists = true;
            fleet.nodeArray.push(nodeAddress);
        }

        ClientStats storage client = node.clientStats[clientAddress];
        if (client.exists == false) {
            client.exists = true;
            node.clientArray.push(clientAddress);
        }

        if (totalConnections > client.totalConnections) {
            uint256 newConnections = totalConnections - client.totalConnections;

            client.totalConnections = totalConnections;
            node.totalConnections = node.totalConnections.add(newConnections);
            fleet.totalConnections = fleet.totalConnections.add(newConnections);
        }

        if (totalBytes > client.totalBytes) {
            uint256 newBytes = totalBytes - client.totalBytes;

            client.totalBytes = totalBytes;
            node.totalBytes = node.totalBytes.add(newBytes);
            fleet.totalBytes = fleet.totalBytes.add(newBytes);
        }

        // Question should we revert() when there is no change ?
        //    Reverting might be cleaner but would also make batch submission of tickets
        //    more complicated.
    }

    function validateFleetAccess(
        IFleetContract fleetContract,
        address client
    ) internal view {
        IFleetContract fc = IFleetContract(fleetContract);
        requiref(fc.deviceWhitelist(client), "Unregistered device", client);
    }

    /* TEST_IF
  function requiref(bool _test, string memory _format, address _arg) internal pure {
    if (!_test) {
      string memory output = string(abi.encodePacked(_format, " (", tohex(_arg), ")"));
      revert(output);
    }
  }
  bytes constant hexchars = "0123456789abcdef";
  function tohex(address _arg) internal pure returns (bytes memory) {
    bytes memory ret = new bytes(42);
    bytes20 b = bytes20(_arg);
    ret[0] = '0';
    ret[1] = 'x';
    for (uint i = 0; i < 20; i++) {
      ret[2*i+2] = hexchars[uint8(b[i]) / 16];
      ret[2*i+3] = hexchars[uint8(b[i]) % 16];
    }
    return ret;
  }
  /*TEST_ELSE*/
    function requiref(
        bool _test,
        string memory _format,
        address
    ) internal pure {
        require(_test, _format);
    }
    /*TEST_END*/
}
