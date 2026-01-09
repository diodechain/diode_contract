// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Storage.sol";
import "./Roles.sol";
import "./deps/OwnableInitializable.sol";
import "./deps/Set.sol";
import "./ChangeTracker.sol";

/**
 * Generic Group
 */
contract Group is Storage, OwnableInitializable, ChangeTracker {
    using Set for Set.Data;

    Set.Data members;
    uint256 constant DATA_SLOT = uint256(keccak256("DATA_SLOT"));

    struct DataKey {
        uint256 class;
        uint256 key;
    }

    modifier onlyMember() virtual {
        requireMember(msg.sender);
        _;
    }

    function requireMember(address _member) internal view virtual {
        require(IsMember(_member), "Only members can call this");
    }

    constructor() {
        initialize(msg.sender);
    }

    function initialize(address payable arg_owner) public override initializer {
        update_change_tracker();
        super.initialize(arg_owner);
    }

    function IsMember(address _member) public view virtual returns (bool) {
        return _member == owner() || members.IsMember(_member);
    }

    function Members() public view virtual returns (address[] memory) {
        return members.Members();
    }

    function SetMemberValue(uint256 key, uint256 value) public onlyMember {
        setDataValue(uint256(msg.sender), key, value);
    }

    function MemberValue(address member, uint256 key) public view virtual returns (uint256) {
        return dataValue(uint256(member), key);
    }

    function SetOwnerValue(uint256 key, uint256 value) public {
        require(owner() == msg.sender, "Only owners can set owner values");
        setDataValue(RoleType.Owner, key, value);
    }

    function OwnerValue(uint256 key) public view virtual returns (uint256) {
        return dataValue(RoleType.Owner, key);
    }

    function setDataValue(uint256 class, uint256 key, uint256 value) internal {
        hash_set_at(DATA_SLOT, uint256(keccak256(abi.encodePacked(class, key))), value);
        update_change_tracker();
    }

    function dataValue(uint256 class, uint256 key) internal view returns (uint256) {
        return hash_at(DATA_SLOT, uint256(keccak256(abi.encodePacked(class, key))));
    }

    function DataValue(uint256 class, uint256 key) public view virtual returns (uint256) {
        return hash_at(DATA_SLOT, uint256(keccak256(abi.encodePacked(class, key))));
    }

    function DataValues(DataKey[] memory _keys) public view virtual returns (uint256[] memory) {
        uint256[] memory values = new uint256[](_keys.length);
        for (uint256 i = 0; i < _keys.length; i++) {
            values[i] = DataValue(_keys[i].class, _keys[i].key);
        }
        return values;
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint256 _dataLength, bytes memory _data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(_data, 32) // First 32 bytes are the padded length of data, so exclude that
            result :=
                call(
                    gas(),
                    destination,
                    0, // value is always zero
                    d,
                    _dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                    x,
                    0 // Output is ignored, therefore the output size is zero
                )
        }
        return result;
    }
}
