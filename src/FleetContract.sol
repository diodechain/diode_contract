// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;
import "./FleetContractInterface.sol";
import "./DiodeRegistry.sol";

/**
 * FleetContract
 */
contract FleetContract is FleetContractInterface {
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

  constructor (DiodeRegistry _registry, address _operator, address payable _accountant) public {
    _registry.ContractStake(_accountant);
    registry = _registry;
    operator = _operator;
    accountant = _accountant;
  }

  function Accountant() external view override returns (address payable) {
    return accountant;
  }

  function SetDeviceAllowlist(address _client, bool _value) external override onlyOperator {
    allowlist[_client] = _value;
  }

  function DeviceAllowlist(address _client) external view override virtual returns (bool) {
    return allowlist[_client];
  }


  /*******************************
   **   DEPRECATED FUNCTIONS    **
   *******************************/
  function SetDeviceWhitelist(address _client, bool _value) external {
    this.SetDeviceAllowlist(_client, _value);
  }
  function deviceWhitelist(address _client) external view returns (bool) {
    return this.DeviceAllowlist(_client);
  }

}