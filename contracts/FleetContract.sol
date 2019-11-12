// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity 0.4.26;

/**
 * FleetContract
 *
 * TODO: emit event
 */
contract FleetContract {
  address private diodeRegistry;
  address /*payable*/ public operator;
  address public accountant;
  uint256 private value;
  bytes32 private accessRoot;
  bytes32 private deviceRoot;
  mapping(address => bool) public deviceWhitelist;
  mapping(address => mapping(address => bool)) public accessWhitelist;

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  constructor (address _diodeRegistry, address _operator, address _accountant) public {
    operator = _operator;
    diodeRegistry = _diodeRegistry;
    accountant = _accountant;
  }

  /*TEST_IF
  function SetDeviceWhitelist(address _client, bool _value) public {
  /*TEST_ELSE*/
  function SetDeviceWhitelist(address _client, bool _value) public onlyOperator {
  /*TEST_END*/
    deviceWhitelist[_client] = _value;
  }

  /*TEST_IF
  function SetAccessWhitelist(address _device, address _client, bool _value) public {
  /*TEST_ELSE*/
  function SetAccessWhitelist(address _device, address _client, bool _value) public onlyOperator {
  /*TEST_END*/
    accessWhitelist[_device][_client] = _value;
  }
}