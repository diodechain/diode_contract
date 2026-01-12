// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./ProtectedRoleGroup.sol";

/**
 * Chat Smart Contract
 */
contract ChatGroup is ProtectedRoleGroup {
    using Set for Set.Data;
    // List of group keys, only the most recent key should be
    // used for encryption

    uint256 constant GROUP_KEYS = uint256(keccak256("GROUP_KEYS"));
    uint256 constant ZONE = uint256(keccak256("ZONE"));

    function requireReader(address _member) internal view virtual override {
        require(_member == address(zone()) || role(_member) >= RoleType.None, "Read access not allowed");
    }

    function initialize(address payable owner, address _zone, address initial_key) public initializer {
        set_at(ZONE, uint256(_zone));
        list_push(GROUP_KEYS, uint256(initial_key));
        super.initialize(owner);
    }

    function ElectNewOwner(address payable newOwner) external {
        require(zone().Role(msg.sender) >= RoleType.Admin, "Only zone admins can elect a new owner");
        require(!zone().IsMember(owner()), "Only deleted owners can be replaced");
        moveOwnership(newOwner);
    }

    function Zone() external view onlyReader returns (RoleGroup) {
        return zone();
    }

    function zone() internal view returns (RoleGroup) {
        return RoleGroup(address(at(ZONE)));
    }

    function AddKey(address key) external onlyAdmin {
        list_push(GROUP_KEYS, uint256(key));
    }

    function Key(uint256 index) external view onlyReader returns (address) {
        return address(list_at(GROUP_KEYS, index));
    }

    function Keys() external view onlyReader returns (address[] memory) {
        return list_all_address(GROUP_KEYS);
    }

    struct Info {
        address chat;
        address owner;
        address[] members;
        uint256 member_count;
    }

    function InfoAggregateV1(uint256 max_size) external returns (Info memory) {
        if (!members.IsMember(msg.sender)) {
            return Info({chat: address(this), owner: address(0), members: new address[](0), member_count: 0});
        } else {
            address[] memory _members = Members(0, max_size);
            return Info({chat: address(this), owner: owner(), members: _members, member_count: members.Size()});
        }
    }
}
