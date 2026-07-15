// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "./sapphire/auth/SiweAuth.sol";
import "./IZTNAContract.sol";

contract ZTNAUsage {
    uint256 public totalUsage;
    uint256 public limit;

    function Type() external pure returns (bytes32) {
        return "ZTNAUsage";
    }

    function Version() external pure returns (uint256) {
        return 100;
    }
}
