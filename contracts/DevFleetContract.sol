// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;

import "./FleetContract.sol";

/**
 * DevFleetContract
 */
contract DevFleetContract is FleetContract {
    constructor(address payable _admin) FleetContract(_admin, _admin) {}

    function initialize(address _operator, address _accountant) public {
        require(operator == address(0) && accountant == address(0), "Already initialized");
        operator = _operator;
        accountant = _accountant;
    }

    function DeviceAllowlist(address) public pure override returns (bool) {
        return true;
    }

    function Version() public pure returns (int256) {
        return 110;
    }
}
