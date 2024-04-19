// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./deps/IERC20.sol";
import "./deps/SafeERC20.sol";
import "./deps/Utils.sol";
import "./deps/SafeMath.sol";
import "./IFleetContract.sol";

/**
 * DiodeRegistry
 *
 * This registry implements
 *
 * 1. Registering Fleets
 * 2. Submitting Service Tickets for Traffic and Connections
 *
 */

contract DiodeRegistryLight {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint64 constant SecondsPerEpoch = 2_592_000;
    uint64 constant Fractionals = 1000;
    address immutable Foundation;
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
     * FleetContracts => Relays => Devices(aka Client)
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

    uint256 public currentEpoch;
    uint256 currentEpochStart;
    uint256 previousEpochStart;

    uint256 foundationTaxRate;
    uint256 foundationWithdrawableBalance;
    uint256 connectionScore;
    uint256 byteScore;

    // These two together form an iterable map for this Epochs activity
    IFleetContract[] public fleetArray;
    mapping(address => FleetStats) fleetStats;

    // ==================== DATA STRUCTURES ==================
    struct FleetStats {
        bool exists;
        uint256 currentBalance;
        uint256 withdrawRequestSize;
        uint256 withdrawableBalance;
        uint256 currentEpoch;
        uint256 score;
        // These two together form an iterable map
        address[] nodeArray;
        mapping(address => NodeStats) nodeStats;
    }

    struct NodeStats {
        bool exists;
        uint256 score;
        // These two together form an iterable map
        address[] clientArray;
        mapping(address => ClientStats) clientStats;
    }

    struct ClientStats {
        bool exists;
        uint256 score;
    }

    modifier onlyFoundation() {
        require(msg.sender == Foundation, "Foundation only");
        _;
    }

    constructor(address _foundation, IERC20 _token) {
        Foundation = _foundation;
        Token = _token;
        currentEpoch = Epoch();
        currentEpochStart = block.number;
        previousEpochStart = block.number;
        foundationTaxRate = 10;
    }

    function ContractStake(IFleetContract _fleet, uint256 amount) public {
        require(
            _fleet.Accountant() == msg.sender,
            "Only the fleet accountant can do this"
        );

        FleetStats storage fleet = fleetStats[address(_fleet)];

        if (fleet.exists == false) {
            fleet.exists = true;
            fleetArray.push(_fleet);
        }

        Token.safeTransferFrom(msg.sender, address(this), amount);
        fleet.currentBalance += amount;
    }

    function ContractUnstake(IFleetContract _fleet, uint256 amount) public {
        require(
            _fleet.Accountant() == msg.sender,
            "Only the fleet accountant can do this"
        );
        FleetStats storage fleet = fleetStats[address(_fleet)];
        require(fleet.exists, "Only existing fleets can be unstaked");
        fleet.withdrawRequestSize = amount;
    }

    function ContractWithdraw(IFleetContract _fleet) public {
        require(
            _fleet.Accountant() == msg.sender,
            "Only the fleet accountant can do this"
        );
        FleetStats storage fleet = fleetStats[address(_fleet)];
        require(fleet.withdrawableBalance > 0, "Nothing to withdraw");
        Token.safeTransfer(msg.sender, fleet.withdrawableBalance);
        fleet.withdrawableBalance = 0;
    }

    function setFoundationTax(uint256 _taxRate) external onlyFoundation {
        foundationTaxRate = _taxRate;
    }

    function setByteScore(uint256 _byteScore) external onlyFoundation {
        byteScore = _byteScore;
    }

    function setConnectionScore(
        uint256 _connectionScore
    ) external onlyFoundation {
        connectionScore = _connectionScore;
    }

    // One Epoch should be roughly one month
    function Epoch() public view returns (uint256) {
        return block.timestamp.div(SecondsPerEpoch);
    }

    function EndEpoch() public {
        // This call is private and only done in the per block call
        if (currentEpoch == Epoch()) revert("Can't end the current epoch");

        // Update epoch
        currentEpoch = Epoch();
        previousEpochStart = currentEpochStart;
        currentEpochStart = block.number;
    }

    function EndEpochForAllFleets() public {
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
        EndEpoch();
        for (uint f = 0; f < fleetArray.length; f++) {
            EndEpochForFleet(fleetArray[f]);
        }
        // Global cleanup
        delete fleetArray;
    }

    function EndEpochForFleet(IFleetContract fleetContract) public {
        FleetStats storage fleet = fleetStats[address(fleetContract)];
        if (!fleet.exists) return;

        uint256 epoch = fleet.currentEpoch + 1;
        if (epoch >= currentEpoch) return;

        uint256 fleetBalance = fleet.currentBalance;
        uint256 reward = fleetBalance / 100;
        // No traffic => no reward, and no tax
        if (fleet.score == 0) reward = 0;

        uint256 foundationTax = (reward * foundationTaxRate) / 100;

        // Still updating the withdrawable balance even if there is no reward
        fleet.currentBalance -= reward;
        if (fleet.currentBalance > fleet.withdrawRequestSize) {
            fleet.withdrawableBalance += fleet.withdrawRequestSize;
            fleet.currentBalance -= fleet.withdrawRequestSize;
        } else {
            fleet.currentBalance = 0;
            fleet.withdrawableBalance += fleet.currentBalance;
        }

        // No need to continue beyond this point, if there is nothing to distribute
        if (reward == 0) return;

        for (uint256 n = 0; n < fleet.nodeArray.length; n++) {
            address nodeAddress = fleet.nodeArray[n];
            NodeStats storage node = fleet.nodeStats[nodeAddress];

            // Summarizing in one reward per node to be applying capping and allow fractionals
            _rollup(nodeAddress, node.score);

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
    ) public {
        require(blockHeight < block.number, "Ticket from the future?");
        require(blockHeight > previousEpochStart, "Wrong epoch");
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
    }

    // ====================================================================================
    // ============================= EXPLORATIVE ACCESSORS ================================
    // ====================================================================================

    // These types only exist for external accessors, hence avoid using mappings
    struct FleetStat {
        bool exists;
        uint256 currentBalance;
        uint256 withdrawRequestSize;
        uint256 withdrawableBalance;
        uint256 currentEpoch;
        uint256 score;
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
    function FleetArray() external view returns (IFleetContract[] memory) {
        return fleetArray;
    }

    function FleetArrayLength() external view returns (uint) {
        return fleetArray.length;
    }

    function GetFleet(IFleetContract _fleet) external view returns (FleetStat memory) {
        FleetStats storage f = fleetStats[address(_fleet)];
        return
            FleetStat(
                f.exists,
                f.currentBalance,
                f.withdrawRequestSize,
                f.withdrawableBalance,
                f.currentEpoch,
                f.score
            );
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
        FleetStats storage fleet = fleetStats[address(fleetContract)];
        uint256 score = totalConnections *
            connectionScore +
            totalBytes *
            byteScore;

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

        if (score > client.score) {
            client.score = score;
        }
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
