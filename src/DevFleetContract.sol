// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;
import "./FleetContract.sol";

/**
 * DevFleetContract
 */
contract DevFleetContract is FleetContract {
  constructor (DiodeRegistry _registry, address payable _admin) FleetContract(_registry, _admin, _admin) public {
  }

  function DeviceAllowlist(address) public view override returns (bool) {
    return true;
  }
}