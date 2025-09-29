// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * Generic Group
 */
contract Storage {
    function at(uint256 slot) internal view returns (uint256 _value) {
        assembly {
            _value := sload(slot)
        }
    }

    function set_at(uint256 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function hash_at(uint256 base, uint256 key) internal view returns (uint256) {
        return at(hash_slot(base, key));
    }

    function hash_set_at(uint256 base, uint256 key, uint256 value) internal {
        set_at(hash_slot(base, key), value);
    }

    function hash_slot(uint256 base, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(key, base)));
    }

    function list_size(uint256 base) internal view returns (uint256) {
        return at(base);
    }

    function list_set_size(uint256 base, uint256 size) internal {
        set_at(base, size);
    }

    function list_at(uint256 base, uint256 key) internal view returns (uint256) {
        return at(list_slot(base, key));
    }

    function list_all_address(uint256 base) internal view returns (address[] memory) {
        uint256 size = list_size(base);
        address[] memory addresses = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            addresses[i] = address(list_at(base, i));
        }
        return addresses;
    }

    function list_page_address(uint256 base, uint256 page, uint256 pageSize) internal view returns (address[] memory) {
        uint256 start = page * pageSize;
        uint256 end = start + pageSize;
        address[] memory addresses = new address[](pageSize);
        for (uint256 i = start; i < end; i++) {
            addresses[i - start] = address(list_at(base, i));
        }
        return addresses;
    }

    function list_all_uint256(uint256 base) internal view returns (uint256[] memory) {
        uint256 size = list_size(base);
        uint256[] memory values = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            values[i] = list_at(base, i);
        }
        return values;
    }

    function list_page_uint256(uint256 base, uint256 page, uint256 pageSize) internal view returns (uint256[] memory) {
        uint256 start = page * pageSize;
        uint256 end = start + pageSize;
        uint256[] memory values = new uint256[](pageSize);
        for (uint256 i = start; i < end; i++) {
            values[i - start] = list_at(base, i);
        }
        return values;
    }

    function list_set_at(uint256 base, uint256 key, uint256 value) internal {
        set_at(list_slot(base, key), value);
    }

    function list_push(uint256 base, uint256 value) internal {
        uint256 size = list_size(base);
        list_set_at(base, size, value);
        list_set_size(base, size + 1);
    }

    function list_pop(uint256 base) internal returns (uint256) {
        uint256 size = list_size(base) - 1;
        list_set_size(base, size);
        return list_at(base, size);
    }

    function list_slot(uint256 base, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(base))) + key;
    }
}
