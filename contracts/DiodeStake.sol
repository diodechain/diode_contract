// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity 0.4.26;

import "./Utils.sol";
import "./SafeMath.sol";
import "./Address.sol";
/*TEST_IF
import "./TestFleetContract.sol";
/*TEST_ELSE*/
import "./FleetContract.sol";
/*TEST_END*/


/**
 * DiodeStake
 *
 * Use ether as diode token
 * 1 diode token is 1 ether
 * should we care about miner fee?
 * deduct stake value first?
 *
 * It's a implementation of ticket mapping version.
 * The gas used:
 * submitTraficTicket: 419392
 * claimRewards: 139635
 *
 * TODO:
 * 1. Split Miner Stake & Wallet
 * 2. Events
 */

library TimeLockedStake {
  using SafeMath for uint256;
  /*TEST_IF
  uint64 constant StakeWaitingTime = 3;
  /*TEST_ELSE*/
  uint64 constant StakeWaitingTime = 175200;
  /*TEST_END*/

  struct Data {
    uint256 pendingAmount;
    uint256 startTime;
    uint256 doneAmount;
  }
  function isLocked(Data memory dat) internal view returns(bool) {
    return block.number - dat.startTime < StakeWaitingTime;
  }
  function pendingValue(Data memory dat) internal view returns(uint256) {
    return add(dat, 0).pendingAmount;
  }
  function value(Data memory dat) internal view returns(uint256) {
    return add(dat, 0).doneAmount;
  }
  function add(Data memory dat, uint256 _value) internal view returns(Data memory) {
    if (!isLocked(dat)) {
      // Previous pending amount is not locked anymore
      // adding pending amount to done amount before making new amount pending
      return Data(_value, block.number, dat.doneAmount.add(dat.pendingAmount));
    } else {
      // Reseting pending time to current block number
      return Data(dat.pendingAmount.add(_value), block.number, dat.doneAmount);
    }
  }
  function deduct(Data memory dat, uint256 _value) internal view returns(Data memory ret) {
    ret = add(dat, 0);
    require(ret.doneAmount >= _value, "Insufficent funds to deduct");
    ret.doneAmount = ret.doneAmount - _value;
  }
}

library Stake {
  using SafeMath for uint256;
  using TimeLockedStake for TimeLockedStake.Data;
  struct Data {
    TimeLockedStake.Data staked;
    TimeLockedStake.Data unstaked;
  }
  function addStake(Data memory dat, uint256 _stake) internal view returns(Data memory) {
    dat.staked = dat.staked.add(_stake);
    return dat;
  }
  // This function skips the time lock - is used for added stake from mining
  function addStakeNow(Data memory dat, uint256 _stake) internal pure returns(Data memory) {
    dat.staked.doneAmount = dat.staked.doneAmount.add(_stake);
    return dat;
  }
  /* Stake runs through the four phases:
   * 1. Pending (for StakeWaitingTime)
   * 2. Staked
   * 3. Locked (for stakeWaiting Time)
   * 4. Claimable
   */
  function pendingValue(Data memory dat) internal view returns(uint256) {
    return dat.staked.pendingValue();
  }
  function stakedValue(Data memory dat) internal view returns(uint256) {
    return dat.staked.value();
  }
  function lockedValue(Data memory dat) internal view returns(uint256) {
    return dat.unstaked.pendingValue();
  }
  function claimableValue(Data memory dat) internal view returns(uint256) {
    return dat.unstaked.value();
  }
  function subStake(Data memory dat, uint256 _stake) internal view returns(Data memory) {
    require(dat.staked.value() >= _stake, "Can't unstake more than is staked");
    dat.staked = dat.staked.deduct(_stake);
    dat.unstaked = dat.unstaked.add(_stake);
    return dat;
  }
  function claimStake(Data memory dat, uint256 _stake) internal view returns(Data memory) {
    require(dat.unstaked.value() >= _stake, "Insufficent free stake");

    dat.unstaked = dat.unstaked.deduct(_stake);
    return dat;
  }
}

contract DiodeStake {
  using Stake for Stake.Data;
  using SafeMath for uint256;
  using Address for address;
  address public owner;
  // diode accountant
  address /*payable*/ public accountant;
  uint256 public stakeCount;
  uint256 public unstakeCount;
  mapping(address => FleetContract) public delegators;
  mapping(address => Stake.Data) private minerStake;
  mapping(address => Stake.Data) private contractStake;

  modifier onlyOwner() {
    if (msg.sender != owner) revert();
    _;
  }

  modifier onlyAccountant() {
    if (msg.sender != accountant) revert();
    _;
  }

  event Staked(
    bool indexed isContract,
    address indexed target,
    uint256 indexed amount
  );

  event Unstaked(
    bool indexed isContract,
    address indexed target,
    uint256 indexed amount
  );

  event Withdrawn(
    bool indexed isContract,
    address indexed target,
    uint256 indexed amount
  );

  constructor(address /*payable*/ _accountant) public {
    owner = msg.sender;
    accountant = _accountant;
  }

  // for cron job function
  function DelegateContractCreate(address _owner) public payable onlyAccountant {
    if (delegators[_owner] != address(0)) revert("Delegate already has a fleet contract");
    FleetContract _fleetContract = new FleetContract(address(this), _owner, accountant);
    delegators[_owner] = _fleetContract;
    ContractStake(address(_fleetContract));
  }

  function checkAccountant(address _id) internal view returns(FleetContract) {
    FleetContract fleetContract = delegators[_id];

    // Handle delegated contracts
    if (fleetContract != address(0)) {
      if (accountant != msg.sender) revert ("Only the cron accountant can call this");

    // Handle direct fleet contracts
    } else {
      if (!_id.IsContract()) revert("Invalid fleet contract address");
      fleetContract = FleetContract(_id);
      address contractAccountant = fleetContract.accountant();
      if (contractAccountant != msg.sender) revert("Only the fleet accountant can do this");
    }

    return fleetContract;
  }

  function ContractValue(uint8 pending, address _id) public view returns (uint256) {
    if (pending == 0)
      return contractStake[_id].stakedValue();
    else if (pending == 1)
      return contractStake[_id].pendingValue();
    else if (pending == 2)
      return contractStake[_id].lockedValue();
    else if (pending == 3)
      return contractStake[_id].claimableValue();
    revert("Unhandled argument");
  }

  function ContractStake(address _id) public payable {
    FleetContract fleetContract = checkAccountant(_id);
    contractStake[fleetContract] = contractStake[fleetContract].addStake(msg.value);
    emit Staked(true, fleetContract, msg.value);
  }

  function _contractValue(address fleetContract) internal view returns(uint256) {
    return contractStake[fleetContract].stakedValue();
  }

  function ContractUnstake(address _id, uint256 _value) public {
    FleetContract fleetContract = checkAccountant(_id);
    contractStake[fleetContract] = contractStake[fleetContract].subStake(_value);
    emit Unstaked(true, fleetContract, _value);
  }

  function ContractWithdraw(address _id) public {
    FleetContract fleetContract = checkAccountant(_id);
    address /*payable*/ contractAccountant = fleetContract.accountant();
    Stake.Data storage stake = contractStake[fleetContract];
    uint256 _value = stake.claimableValue();
    require(_value > 0, "Can't withdraw 0");
    contractStake[fleetContract] = stake.claimStake(_value);
    contractAccountant.transfer(_value);
    emit Withdrawn(true, fleetContract, _value);
  }

  function MinerValue(uint8 pending, address miner) public view returns (uint256) {
    return _miner(pending, miner);
  }

  function _miner(uint8 pending, address miner) internal view returns (uint256) {
    if (pending == 0)
      return minerStake[miner].stakedValue();
    else if (pending == 1)
      return minerStake[miner].pendingValue();
    else if (pending == 2)
      return minerStake[miner].lockedValue();
    else if (pending == 3)
      return minerStake[miner].claimableValue();
    revert("Unhandled argument");
  }

  function MinerStake() public payable {
    _minerStake(msg.sender, msg.value);
  }

  function _minerStake(address miner, uint256 _value) internal {
    minerStake[miner] = minerStake[miner].addStake(_value);
    emit Staked(false, miner, _value);
  }
  function _minerStakeNow(address miner, uint256 _value) internal {
    minerStake[miner] = minerStake[miner].addStakeNow(_value);
  }

  function MinerUnstake(uint256 _value) public {
    address miner = msg.sender;
    minerStake[miner] = minerStake[miner].subStake(_value);
    emit Unstaked(false, miner, _value);
  }

  function MinerWithdraw() public {
    address /*payable*/ miner = msg.sender;
    Stake.Data storage stake = minerStake[miner];
    uint256 _value = stake.claimableValue();
    require(_value > 0, "Can't withdraw 0");
    minerStake[miner] = stake.claimStake(_value);
    miner.transfer(_value);
    emit Withdrawn(false, miner, _value);
  }
}
