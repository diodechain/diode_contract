// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2023 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;

/**
 * IFleetContract
 */
interface IFleetContract {
    function Accountant() external view returns (address payable);
    function deviceWhitelist(address _client) external view returns (bool);
}
