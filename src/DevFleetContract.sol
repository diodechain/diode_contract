// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;
import "./FleetContract.sol";

/**
 * DevFleetContract
 */
contract DevFleetContract is FleetContract {
  constructor (DiodeRegistry _registry, address _operator, address payable _accountant) FleetContract(_registry, _operator, _accountant) public {
  }

  function DeviceAllowlist(address) public view override returns (bool) {
    return true;
  }
}