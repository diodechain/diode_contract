// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./BridgeIn.sol";
import "./BridgeOut.sol";

/**
 * Bridge contract
 */
contract Bridge is BridgeIn, BridgeOut {
    constructor(
        address _foundation,
        address[] memory _validators,
        uint256 _threshold
    ) BridgeIn(_foundation, _validators, _threshold) BridgeOut(block.chainid, address(diode)) {}
}
