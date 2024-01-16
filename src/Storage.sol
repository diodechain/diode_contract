// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./Storage.sol";

/**
 * Generic Group
 */
contract Storage {
    function uint256_at(uint256 slot) public view returns (uint256 _value) {
        assembly {
            _value := sload(slot)
        }
    }
}