// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;
import "./DiodeRegistry.sol";
import "./IFleetContract.sol";

/**
 * FleetContract
 */
contract FleetContract is IFleetContract {
  DiodeRegistry private registry;
  address public operator;
  address payable public accountant;
  uint256 private _reserved_1;
  bytes32 private _reserved_2;
  bytes32 private _reserved_3;
  mapping(address => bool) private allowlist;
  mapping(address => mapping(address => bool)) private _reserved_4;

  modifier onlyOperator {
    require(msg.sender == operator, "Only the operator can call this method");
    _;
  }

  modifier onlyAccountant {
    require(msg.sender == accountant, "Only the accountant can call this method");
    _;
  }

  constructor (DiodeRegistry _registry, address _operator, address payable _accountant) public payable {
    registry = _registry;
    operator = _operator;
    accountant = _accountant;
    if (msg.value > 0)
      _registry.ContractStake{value: msg.value, gas: gasleft()}(this);
  }

  function Accountant() external view returns (address payable) {
    return accountant;
  }

  function Operator() external view returns (address) {
    return operator;
  }

  function SetDeviceAllowlist(address _client, bool _value) public virtual onlyOperator {
    allowlist[_client] = _value;
  }

  function DeviceAllowlist(address _client) public view virtual returns (bool) {
    return allowlist[_client];
  }


  /*******************************
   **   DEPRECATED FUNCTIONS    **
   *******************************/
  function SetDeviceWhitelist(address _client, bool _value) external {
    SetDeviceAllowlist(_client, _value);
  }

  function deviceWhitelist(address _client) override external view returns (bool) {
    return DeviceAllowlist(_client);
  }

}
