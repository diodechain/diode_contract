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
    function at(uint256 slot) public view returns (uint256 _value) {
        assembly {
            _value := sload(slot)
        }
    }

    function set_at(uint256 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function hash_at(uint256 base, uint256 key) public view returns (uint256 _value) {
        uint256 slot = hash_slot(base, key);
        _value = at(slot);
    }

    function hash_set_at(uint256 base, uint256 key, uint256 value) public {
        uint256 slot = hash_slot(base, key);
        set_at(slot, value);
    }

    function hash_slot(uint256 base, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(key, base)));
    }
}