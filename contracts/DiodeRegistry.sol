pragma solidity 0.4.26;

import "./Utils.sol";
import "./SafeMath.sol";
import "./FleetContract.sol";
/*TEST_IF
import "./TestDiodeStake.sol";
/*TEST_ELSE*/
import "./DiodeStake.sol";
/*TEST_END*/

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
 * UPDATES NEEDED:
 * -- No check for EPOCH right now, need to update
 * ====> HOW to make submitTicket secure when it depends on Fleetcontract.checkDevice ? Possible?
 * -- Update register device to just use device addr
 * -- Finish writing blockReward function
 * -- Fix stack depth issue in SubmitTrafficTicket
 * -- UNIT Tests
 * -- Deploy to Server (Genesis Block)

 * OTHER:
 * -- Check submit ticket from device in diode server
LATER:
 * -- Block Header use signature or add public key
 */

/*TEST_IF
contract TestDiodeRegistry is DiodeStake {
/*TEST_ELSE*/
contract DiodeRegistry is DiodeStake {
/*TEST_END*/
  using SafeMath for uint256;

  uint256 currentEpoch = 0;
  uint8 constant blockSeconds = 15;
  /*TEST_IF
  uint64 constant blocksPerEpoch = 4;
  /*TEST_ELSE*/
  uint64 constant blocksPerEpoch = 4 weeks / blockSeconds;
  /*TEST_END*/
  uint64 constant blockRewards = 3 ether;
  uint64 constant fractionals = 10000;

  // ==================== DATA STRUCTURES ==================

  /**
   * For accounting the activity from devices we maintain a three
   * level tree of iterable maps:
   *
   * FleetContracts => Miners(aka Nodes) => Devices(aka Client)
   *
   * Each device ticket is stored into this tree ensuring that
   * device activity is deduplicated on a per-node basis.
   *
   * Rollups of the total counts are done on the Nodes level as
   * well as on the Fleet level.
   *
   */
  address[] rollupArray;
  mapping(address => uint256) rollupReward;

  // These three together form an iterable map for this Epochs activity
  address[] fleetArray;
  mapping(address => FleetStats) fleetStats;

  struct FleetStats {
    bool exists;

    uint256 totalConnections;
    uint256 totalBytes;

    // These three together form an iterable map
    address[] nodeArray;
    mapping(address => NodeStats) nodeStats;
  }

  struct NodeStats {
    bool exists;

    uint256 totalConnections;
    uint256 totalBytes;

    // These three together form an iterable map
    address[] clientArray;
    mapping(address => ClientStats) clientStats;
  }

  struct ClientStats {
    bool exists;
    uint256 clientIndex;

    uint256 totalConnections;
    uint256 totalBytes;
  }

  // ============= MODIFIERS ===============
  modifier onlyMiner() {
    /*TEST_IF
    /* ganache bug https://github.com/trufflesuite/ganache-core/issues/201 */
    if (msg.sender != block.coinbase && block.coinbase != address(0)) revert("Only the miner of the block can call this method");
    /*TEST_ELSE*/
    if (msg.sender != block.coinbase) revert("Only the miner of the block can call this method");
    /*TEST_END*/
    _;
  }

  modifier thisEpoch(uint256 blockHeight) {
    if (blockHeight >= block.number) revert("Ticket from the future?");
    /*TEST_IF
    /*TEST_ELSE*/
    if (blockHeight.div(blocksPerEpoch) != currentEpoch) revert("Wrong epoch");
    /*TEST_END*/
    _;
  }

  event Connection(
    address indexed fleetContract,
    address indexed node,
    address indexed client
  );

  event Traffic(
    address indexed fleetContract,
    address indexed node,
    address indexed device,
    address client
  );

  event Rewards(
    address indexed node,
    uint256 indexed amount
  );

  constructor(address /*payable*/ _accountant) DiodeStake(_accountant) public {
  }


  // BlockTimeGoal is 15 seconds
  // One Epoch should be roughly one month
  function Epoch() public view returns (uint256) {
    return block.number % blocksPerEpoch;
  }

  /**
   * rewardTransaction() -- needs to be called every block.
   */
  function blockReward() public onlyMiner {
    // Calculcating per epoch service rewards
    if (currentEpoch != Epoch()) {
      endEpoch();
    }

    // TODO: fee calculation based on old blocks here?
    // Fixed block reward (5 ether?)
    uint256 miningReward = 5 ether;
    _minerRollup(block.coinbase, miningReward.mul(fractionals));


    // At this point all rewards and  service tickets should be accounted for and cleaned up.
    // rollupRewards should contain the final sum * fractionals of reward for each miner.
    for (uint256 r = 0; r < rollupArray.length; r++) {
      address miner = rollupArray[r];
      uint256 reward = rollupReward[miner].div(fractionals);

      uint256 maxReward = _miner(0, miner);
      if (reward > maxReward) {
        reward = maxReward;
      }
      if (reward > 0) {
        _minerStakeNow(miner, reward);
        emit Rewards(miner, reward);
      }
      delete rollupReward[miner];
    }
    delete rollupArray;
  }

  function endEpoch() private {
    address nodeAddress;
    uint256 reward;
    uint256 f;

    // This call is private and only done in the per block call
    // if (currentEpoch == Epoch()) revert("Can't end the current epoch");

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
    for (f = 0; f < fleetArray.length; f++) {
      address fleetContract = fleetArray[f];

      uint256 fleetValue = _contractValue(fleetContract);
      reward = fleetValue.div(100);

      FleetStats storage fleet = fleetStats[fleetContract];
      uint256 fleetPoints = fleet.totalBytes.add(fleet.totalConnections.mul(1024));

      for (uint256 n = 0; n < fleet.nodeArray.length; n++) {
        nodeAddress = fleet.nodeArray[n];
        NodeStats storage node = fleet.nodeStats[nodeAddress];

        uint256 nodePoints = node.totalBytes.add(node.totalConnections.mul(1024));
        // Out of all delivered fleetPoints the nodePoints are attributable to this node
        // next we're calculcating the corresponding reward from the reward pool of this fleet.
        // This nodes reward = nodePoints * (reward / fleetPoints)
        // This is multipled with 1000 to account for fractionals, needs to be divided
        // after summation.
        // uint256 nodeReward = nodePoints.mul(fractionals).mul(reward).div(fleetPoints);
        nodePoints = nodePoints.mul(fractionals).mul(reward).div(fleetPoints);

        // Summarizing in one reward per node to be applying capping and allow fractionals
        _minerRollup(nodeAddress, nodePoints);

        for (uint256 c = 0; c < node.clientArray.length; c++) {
          // Client Map Cleanup
          delete node.clientStats[node.clientArray[c]];
        }
        // Node Cleanup
        delete fleet.nodeStats[nodeAddress];
      }
      // Fleet Cleanup
      delete fleetStats[fleetContract];
    }
    // Global cleanup
    delete fleetArray;

    // Update epoch
    currentEpoch = Epoch();
  }

  function _minerRollup(address miner, uint256 value) private {
    if (value > 0) {
      if (rollupReward[miner] == 0) {
        rollupArray.push(miner);
      }
      rollupReward[miner] = rollupReward[miner].add(value);
    }
  }

  function SubmitConnectionTicket(uint256 blockHeight, address fleetContract, address nodeAddress, uint256 totalConnections,
                                  bytes32 localAddress, bytes32[3] memory signature) public thisEpoch(blockHeight) {
    if (totalConnections == 0) revert("Invalid ticket value");

    // ======= CLIENT SIGNATURE RECOVERY =======
    bytes32[] memory message = new bytes32[](5);
    message[0] = bytes32(blockHeight);
    message[1] = bytes32(fleetContract);
    message[2] = bytes32(nodeAddress);
    message[3] = bytes32(totalConnections);
    message[4] = localAddress;

    address client = ecrecover(Utils.bytes32Hash(message), uint8(uint256(signature[2])), signature[0], signature[1]);
    // ======= END =======

    validateFleetAccess(fleetContract, client);
    updateTrafficCount(fleetContract, nodeAddress, client, totalConnections, 0);

    emit Connection(fleetContract, nodeAddress, client);
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
   * [4] local address
   * [5] client sig r
   * [6] client sig s
   * [7] client sig v
   *
   * Requires an array with a length multiple of 8. Each 8 elements representing
   * a single connection ticket.
   */
  function SubmitConnectionTicketRaw(bytes32[] /*calldata*/ _connectionTicket) external {
    if (_connectionTicket.length == 0 || _connectionTicket.length % 8 != 0) revert("Invalid ticket length");

    for (uint256 i = 0; i < _connectionTicket.length; i += 8) {
      bytes32[3] memory deviceSignature = [_connectionTicket[i+5], _connectionTicket[i+6], _connectionTicket[i+7]];
      SubmitConnectionTicket(uint256(_connectionTicket[i+0]), Utils.bytes32ToAddress(_connectionTicket[i+1]),
                             Utils.bytes32ToAddress(_connectionTicket[i+2]), uint256(_connectionTicket[i+3]),
                             _connectionTicket[i+4], deviceSignature);
    }
  }

  /**
   * Submit one or more traffic tickets raw
   *
   * Submit traffic tickets
   *
   * [0] block height
   * [1] fleet contract address
   * [2] node address
   * [3] total bytes
   * [4] destination id
   * [5] device sig r
   * [6] device sig s
   * [7] device sig v
   * [8] destination sig r
   * [9] destination sig s
   * [10] destination sig v
   */
  function SubmitTrafficTicketRaw(bytes32[] /*calldata*/ _trafficTicket) external {
    if (_trafficTicket.length == 0 || _trafficTicket.length % 11 != 0) revert("Invalid traffic ticket length");

    for (uint256 i = 0; i < _trafficTicket.length; i += 11) {
      bytes32[3] memory deviceSignature = [_trafficTicket[i+5], _trafficTicket[i+6], _trafficTicket[i+7]];
      bytes32[3] memory destSignature = [_trafficTicket[i+8], _trafficTicket[i+9], _trafficTicket[i+10]];

      SubmitTrafficTicket(uint256(_trafficTicket[i+0]), Utils.bytes32ToAddress(_trafficTicket[i+1]),
                          Utils.bytes32ToAddress(_trafficTicket[i+2]), uint256(_trafficTicket[i+3]),
                          Utils.bytes32ToAddress(_trafficTicket[i+4]), deviceSignature, destSignature);
    }
  }

  function SubmitTrafficTicket(uint256 blockHeight, address fleetContract, address nodeAddress, uint256 totalBytes,
                               address destAddress, bytes32[3] memory deviceSignature, bytes32[3] memory destSignature) public thisEpoch(blockHeight) {
    // ======= CLIENT SIGNATURE RECOVERY =======
    bytes32[] memory deviceMessage = new bytes32[](5);
    deviceMessage[0] = bytes32(blockHeight);
    deviceMessage[1] = bytes32(fleetContract);
    deviceMessage[2] = bytes32(nodeAddress);
    deviceMessage[3] = bytes32(totalBytes);
    deviceMessage[4] = bytes32(destAddress);

    address device = ecrecover(Utils.bytes32Hash(deviceMessage), uint8(uint256(deviceSignature[2])), deviceSignature[0], deviceSignature[1]);
    // ======= END =======
    validateFleetAccess(fleetContract, device);

    // ======= DESTINATION SIGNATURE RECOVERY =======
    bytes32[] memory clientMessage = new bytes32[](8);
    clientMessage[0] = bytes32(blockHeight);
    clientMessage[1] = bytes32(fleetContract);
    clientMessage[2] = bytes32(nodeAddress);
    clientMessage[3] = bytes32(totalBytes);
    clientMessage[4] = bytes32(destAddress);
    clientMessage[5] = deviceSignature[0];
    clientMessage[6] = deviceSignature[1];
    clientMessage[7] = deviceSignature[2];

    address dest = ecrecover(Utils.bytes32Hash(clientMessage), uint8(uint256(destSignature[2])), destSignature[0], destSignature[1]);
    if (dest != destAddress) revert("Invalid destination signature");
    // ======= END =======

    updateTrafficCount(fleetContract, nodeAddress, device, 0, totalBytes);
    emit Traffic(fleetContract, nodeAddress, device, dest);
    return;
  }

  // ====================================================================================
  // ============================= INTERNAL FUNCTIONS ===================================
  // ====================================================================================
  function updateTrafficCount(address fleetContract, address nodeAddress, address clientAddress,
                              uint256 totalConnections, uint256 totalBytes) internal {
    FleetStats storage fleet = fleetStats[fleetContract];

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

  function validateFleetAccess(address fleetContract, address client) internal view {
    FleetContract fc = FleetContract(fleetContract);
    if (fc.deviceWhitelist(client) == false) revert("Unregistered device");
  }
}
