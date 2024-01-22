// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
import "./FleetContract.sol";
import "./deps/Set.sol";

/**
 * ManagableFleetContract
 */
contract ManagableFleetContract is FleetContract {
  using Set for Set.Data;

  Set.Data members;

  constructor (DiodeRegistry _registry, address _operator, address payable _accountant) FleetContract(_registry, _operator, _accountant) {
  }

  function SetDeviceAllowlist(address _client, bool _value) public override onlyOperator {
    super.SetDeviceAllowlist(_client, _value);
    if (_value) {
      members.add(_client);
    } else {
      members.remove(_client);
    }
  }

  function DeviceList() external view returns (address[] memory) {
    return members.items;
  }

}