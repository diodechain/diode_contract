// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./deps/IERC20.sol";
import "./deps/SafeERC20.sol";
import "./deps/Utils.sol";
import "./deps/Initializable.sol";
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
contract DiodeRegistryLight is Initializable {
    using SafeERC20 for IERC20;

    uint64 public constant SecondsPerEpoch = 2_592_000;
    address public immutable Foundation;
    IERC20 public immutable Token;

    /**
     * The reward system works like a 3-step assembly line 🏭
     *
     * Each "batch" of rewards goes through these steps:
     * 1. 📊 COLLECT: Nodes count traffic for 30 days (off-chain)
     * 2. 📤 SUBMIT: Nodes send their counts to the smart contract
     * 3. 💰 PAYOUT: Contract calculates and pays rewards
     *
     * The key insight: PAYOUT is triggered BY the first SUBMIT of the new epoch!
     *
     *           EPOCH N     | EPOCH N+1   | EPOCH N+2   | EPOCH N+3
     *           =========================================================
     * Batch A:  📊 COLLECT  | 📤 SUBMIT   | 💰 PAYOUT ← | ✅ (done)
     *           (count A)   | (send A)    | (pay A)     |
     *                       |             | triggered   |
     * Batch B:  -           | 📊 COLLECT  | 📤 SUBMIT   | 💰 PAYOUT ←
     *                       | (count B)   | (send B)    | (pay B)
     *                       |             |             | triggered
     * Batch C:  -           | -           | 📊 COLLECT  | 📤 SUBMIT
     *                       |             | (count C)   | (send C)
     *
     * ⚡ When epoch changes, the FIRST SubmitTicket() call:
     *    1. Detects new epoch → calls doEndEpoch()
     *    2. Triggers EndEpochForFleet() → pays out previous epoch
     *    3. Then processes the new ticket → starts submitting current epoch
     *
     * Think of it like: "Hey, new month started! Let me pay last month's
     * rewards first, then I'll process your new ticket."
     *
     * Activity is keyed by epoch so epoch finalization does not delete storage:
     *
     *   fleetStats[fleet].epochActivity[epoch].nodes[node].clients[client]
     *
     * Each device ticket is stored into the current epoch bucket ensuring that
     * device activity is deduplicated on a per-node basis. When an epoch is
     * settled, its bucket is left in storage (orphaned) and a new bucket is used.
     *
     */
    address[] public relayArray;
    mapping(address => RelayReward) public relayRewards;

    struct RelayReward {
        bool exists;
        uint256 reward;
    }

    uint256 public currentEpoch;
    uint256 public currentEpochStart;
    uint256 public previousEpochStart;

    uint256 public foundationTaxRate;
    uint256 public foundationWithdrawableBalance;
    uint256 public connectionScore;
    uint256 public byteScore;

    // These two together form an iterable map for this Epochs activity
    IFleetContract[] public fleetArray;
    mapping(address => FleetStats) fleetStats;

    /// @dev v113+ lazy relayArray registration (must remain after fleetStats for proxy layout)
    mapping(address => bool) internal relayInArray;

    // ==================== DATA STRUCTURES ==================
    /// @dev Reserved for proxy storage compatibility with v111 (do not use in logic).
    struct ClientStats {
        bool exists;
        uint256 score;
    }

    /// @dev Reserved for proxy storage compatibility with v111 (do not use in logic).
    struct NodeStats {
        bool exists;
        uint256 score;
        address[] clientArray;
        mapping(address => ClientStats) clientStats;
    }

    struct ClientEpochStats {
        uint256 score;
    }

    struct NodeEpochStats {
        mapping(address => ClientEpochStats) clients;
    }

    struct EpochActivity {
        uint256 score;
        address[] nodeArray;
        uint256[] nodeScores;
        mapping(address => uint256) nodeIndex;
        mapping(address => NodeEpochStats) nodes;
    }

    struct FleetStats {
        bool exists;
        uint256 currentBalance;
        uint256 withdrawRequestSize;
        uint256 withdrawableBalance;
        uint256 currentEpoch;
        uint256 score;
        address[] _reservedNodeArray;
        mapping(address => NodeStats) _reservedNodeStats;
        mapping(uint256 => EpochActivity) epochActivity;
    }

    modifier onlyFoundation() {
        require(msg.sender == Foundation, "Foundation only");
        _;
    }

    constructor(address _foundation, IERC20 _token) {
        Foundation = _foundation;
        Token = _token;
        initialize();
    }

    function initialize() public initializer {
        foundationTaxRate = 1;
        connectionScore = 1024;
        byteScore = 1;
        currentEpoch = Epoch();
        currentEpochStart = block.number;
        previousEpochStart = block.number;
    }

    function ContractStake(IFleetContract _fleet, uint256 amount) public {
        require(_fleet.Accountant() == msg.sender, "Only the fleet accountant can do this");

        FleetStats storage fleet = fleetStats[address(_fleet)];

        if (fleet.exists == false) {
            fleet.exists = true;
            fleetArray.push(_fleet);
        }

        Token.safeTransferFrom(msg.sender, address(this), amount);
        fleet.currentBalance += amount;
    }

    function ContractUnstake(IFleetContract _fleet, uint256 amount) public {
        require(_fleet.Accountant() == msg.sender, "Only the fleet accountant can do this");
        FleetStats storage fleet = fleetStats[address(_fleet)];
        require(fleet.exists, "Only existing fleets can be unstaked");
        fleet.withdrawRequestSize = amount;
    }

    function ContractWithdraw(IFleetContract _fleet) public {
        require(_fleet.Accountant() == msg.sender, "Only the fleet accountant can do this");
        FleetStats storage fleet = fleetStats[address(_fleet)];
        Token.safeTransfer(msg.sender, fleet.withdrawableBalance);
        fleet.withdrawableBalance = 0;
    }

    function FoundationWithdraw() public {
        Token.safeTransfer(Foundation, foundationWithdrawableBalance);
        foundationWithdrawableBalance = 0;
    }

    function RelayWithdraw(address nodeAddress) public {
        uint256 amount = relayRewards[nodeAddress].reward;
        require(amount > 0, "No rewards to withdraw");
        if (!relayInArray[nodeAddress]) {
            relayInArray[nodeAddress] = true;
            relayArray.push(nodeAddress);
        }
        Token.safeTransfer(nodeAddress, amount);
        relayRewards[nodeAddress].reward = 0;
    }

    function SetFoundationTax(uint256 _taxRate) external onlyFoundation {
        foundationTaxRate = _taxRate;
    }

    function SetByteScore(uint256 _byteScore) external onlyFoundation {
        byteScore = _byteScore;
    }

    function SetConnectionScore(uint256 _connectionScore) external onlyFoundation {
        connectionScore = _connectionScore;
    }

    // One Epoch should be roughly one month
    function Epoch() public view returns (uint256) {
        return block.timestamp / SecondsPerEpoch;
    }

    function EndEpoch() public {
        require(currentEpoch != Epoch(), "Can't end the current epoch");
        doEndEpoch();
    }

    function doEndEpoch() internal {
        // Update epoch
        currentEpoch = Epoch();
        previousEpochStart = currentEpochStart;
        currentEpochStart = block.number;
    }

    function EndEpochForAllFleets() public {
        EndEpoch();
        for (uint256 f = 0; f < fleetArray.length; f++) {
            EndEpochForFleet(fleetArray[f]);
        }
    }

    function EndEpochForFleet(IFleetContract fleetContract) public {
        FleetStats storage fleet = fleetStats[address(fleetContract)];
        if (!fleet.exists) return;
        if (fleet.currentEpoch >= currentEpoch) return;

        uint256 settleEpoch = fleet.currentEpoch;
        EpochActivity storage act = fleet.epochActivity[settleEpoch];
        uint256 fleetScore = act.score;

        fleet.currentEpoch = currentEpoch;
        fleet.score = 0;

        uint256 reward = fleet.currentBalance / 100;
        // No traffic => no reward, and no tax
        if (fleetScore == 0) reward = 0;

        uint256 foundationTax = (reward * foundationTaxRate) / 100;

        // Still updating the withdrawable balance even if there is no reward
        fleet.currentBalance -= reward;
        if (fleet.currentBalance > fleet.withdrawRequestSize) {
            fleet.withdrawableBalance += fleet.withdrawRequestSize;
            fleet.currentBalance -= fleet.withdrawRequestSize;
        } else {
            fleet.withdrawableBalance += fleet.currentBalance;
            fleet.currentBalance = 0;
        }
        fleet.withdrawRequestSize = 0;

        reward -= foundationTax;

        if (reward > 0 && fleetScore > 0) {
            uint256 nodeLen = act.nodeArray.length;
            uint256 totalPaid = 0;

            for (uint256 n = 0; n < nodeLen;) {
                address nodeAddress = act.nodeArray[n];
                uint256 nodeScore = act.nodeScores[n];

                unchecked {
                    uint256 value = (reward * nodeScore) / fleetScore;
                    if (value > 0) {
                        RelayReward storage relay = relayRewards[nodeAddress];
                        if (!relay.exists) {
                            relay.exists = true;
                        }
                        relay.reward += value;
                        totalPaid += value;
                    }
                    ++n;
                }
            }

            foundationWithdrawableBalance += foundationTax + reward - totalPaid;
        } else if (reward > 0 || foundationTax > 0) {
            foundationWithdrawableBalance += foundationTax + reward;
        }
    }

    /**
     * Submit one or more connection tickets raw
     *
     * Connection tickets
     *
     * [0] epoch
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
        if (_connectionTicket.length == 0 || _connectionTicket.length % 9 != 0) {
            revert("Invalid ticket length");
        }

        for (uint256 i = 0; i < _connectionTicket.length; i += 9) {
            bytes32[3] memory deviceSignature =
                [_connectionTicket[i + 6], _connectionTicket[i + 7], _connectionTicket[i + 8]];
            SubmitTicket(
                uint256(_connectionTicket[i + 0]),
                IFleetContract(Utils.bytes32ToAddress(_connectionTicket[i + 1])),
                Utils.bytes32ToAddress(_connectionTicket[i + 2]),
                uint256(_connectionTicket[i + 3]),
                uint256(_connectionTicket[i + 4]),
                _connectionTicket[i + 5],
                deviceSignature
            );
        }
    }

    function SubmitTicket(
        uint256 epoch,
        IFleetContract fleetContract,
        address nodeAddress,
        uint256 totalConnections,
        uint256 totalBytes,
        bytes32 localAddress,
        bytes32[3] memory signature
    ) public {
        if (Epoch() != currentEpoch) {
            doEndEpoch();
        }
        EndEpochForFleet(fleetContract);
        require(epoch + 1 == currentEpoch, "Wrong epoch");
        require((totalConnections | totalBytes) != 0, "Invalid ticket value");

        // ======= CLIENT SIGNATURE RECOVERY =======
        bytes32[] memory message = new bytes32[](7);
        message[0] = bytes32(block.chainid);
        message[1] = bytes32(epoch);
        message[2] = Utils.addressToBytes32(address(fleetContract));
        message[3] = Utils.addressToBytes32(nodeAddress);
        message[4] = bytes32(totalConnections);
        message[5] = bytes32(totalBytes);
        message[6] = localAddress;

        address client = ecrecover(Utils.bytes32Hash(message), uint8(uint256(signature[2])), signature[0], signature[1]);
        // ======= END =======

        validateFleetAccess(fleetContract, client);
        updateTrafficCount(fleetContract, nodeAddress, client, totalConnections, totalBytes);
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
        uint256 score;
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

    function FleetArrayLength() external view returns (uint256) {
        return fleetArray.length;
    }

    function RelayArray() external view returns (address[] memory) {
        return relayArray;
    }

    function RelayArrayLength() external view returns (uint256) {
        return relayArray.length;
    }

    function GetFleet(IFleetContract _fleet) external view returns (FleetStat memory) {
        FleetStats storage f = fleetStats[address(_fleet)];
        return
            FleetStat(f.exists, f.currentBalance, f.withdrawRequestSize, f.withdrawableBalance, f.currentEpoch, f.score);
    }

    function GetClientScore(IFleetContract _fleet, address nodeAddress, address clientAddress)
        external
        view
        returns (uint256)
    {
        FleetStats storage f = fleetStats[address(_fleet)];
        return f.epochActivity[f.currentEpoch].nodes[nodeAddress].clients[clientAddress].score;
    }

    function GetClientScoreForEpoch(IFleetContract _fleet, uint256 epoch, address nodeAddress, address clientAddress)
        external
        view
        returns (uint256)
    {
        return fleetStats[address(_fleet)].epochActivity[epoch].nodes[nodeAddress].clients[clientAddress].score;
    }

    function GetNode(IFleetContract _fleet, address nodeAddress) external view returns (Node memory) {
        FleetStats storage f = fleetStats[address(_fleet)];
        EpochActivity storage act = f.epochActivity[f.currentEpoch];
        return Node(nodeAddress, _nodeScore(act, nodeAddress));
    }

    function GetNodeForEpoch(IFleetContract _fleet, uint256 epoch, address nodeAddress)
        external
        view
        returns (Node memory)
    {
        EpochActivity storage act = fleetStats[address(_fleet)].epochActivity[epoch];
        return Node(nodeAddress, _nodeScore(act, nodeAddress));
    }

    function RelayRewards(address nodeAddress) external view returns (uint256) {
        return relayRewards[nodeAddress].reward;
    }

    function _nodeScore(EpochActivity storage act, address nodeAddress) private view returns (uint256) {
        uint256 idx = act.nodeIndex[nodeAddress];
        if (idx == 0) return 0;
        return act.nodeScores[idx - 1];
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
        uint256 score = totalConnections * connectionScore + totalBytes * byteScore;

        if (fleet.exists == false) {
            fleet.exists = true;
            fleetArray.push(fleetContract);
        }

        EpochActivity storage act = fleet.epochActivity[currentEpoch];
        uint256 nodeIdx = act.nodeIndex[nodeAddress];
        if (nodeIdx == 0) {
            act.nodeArray.push(nodeAddress);
            act.nodeScores.push(0);
            nodeIdx = act.nodeArray.length;
            act.nodeIndex[nodeAddress] = nodeIdx;
        }

        NodeEpochStats storage node = act.nodes[nodeAddress];
        ClientEpochStats storage client = node.clients[clientAddress];

        if (score > client.score) {
            uint256 delta = score - client.score;
            unchecked {
                client.score += delta;
                act.score += delta;
                act.nodeScores[nodeIdx - 1] += delta;
                fleet.score += delta;
            }
        }
    }

    function validateFleetAccess(IFleetContract fleetContract, address client) internal view {
        require(
            fleetContract.DeviceAllowlist(client), string(abi.encodePacked("Unregistered device\x00", address(client)))
        );
    }

    function Version() external pure returns (uint256) {
        return 114;
    }
}
