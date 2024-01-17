// Diode Contracts
// Copyright 2023 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./RoleGroup.sol";

/**
 * Chat Smart Contract
 */
contract Chat is RoleGroup {
    // List of group keys, only the most recent key should be
    // used for encryption
    uint256 constant GROUP_KEYS = uint256(keccak256("GROUP_KEYS"));

    function initialize(address payable owner, address initial_key) public {
        list_push(GROUP_KEYS, uint256(initial_key));
        super.initialize(owner);
    }

    function AddKey(address key) external onlyAdmin {
        list_push(GROUP_KEYS, uint256(key));
    }

    function Key(uint256 index) external view returns (address) {
        return address(list_at(GROUP_KEYS, index));
    }

    function AddMember(address _member) external onlyAdmin {
        add(_member, RoleType.Member);
    }

    function AddMember(address _member, uint256 role) external onlyOwner {
        add(_member, role);
    }
    
}