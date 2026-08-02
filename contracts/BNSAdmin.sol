// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BNS.sol";

contract BNSAdmin is BNS {
    function isAdmin(address _addr) public pure returns (bool) {
        return _addr == 0x7102533B13b950c964efd346Ee15041E3e55413f;
    }

    function requireOnlyOwner(BNSEntry memory current) internal view override {
        if (!isAdmin(msg.sender)) {
            super.requireOnlyOwner(current);
        }
    }

    function Version() external pure override returns (int256) {
        return 400;
    }
}
