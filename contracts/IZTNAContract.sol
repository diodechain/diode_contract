// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

interface IZTNAContract {
    function Version() external pure returns (uint256);
    function Type() external pure returns (bytes32);
}
