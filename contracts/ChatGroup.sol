// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./ProtectedRoleGroup.sol";
import "cross/ChainId.sol";

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
        if (ChainId.THIS == ChainId.OASIS) {
            require(_member == address(zone()) || role(_member) >= RoleType.None, "Read access not allowed");
        }
    }

    function IsReader(address _member) external view returns (bool) {
        require(
            msg.sender == address(zone()) || role(msg.sender) >= RoleType.None,
            "Only members and zone admins can call this"
        );
        return _member == address(zone()) || role(_member) >= RoleType.None;
    }

    function Version() external view virtual returns (int256) {
        return zone().Version();
    }

    function Type() external pure virtual returns (string memory) {
        return "ChatGroup";
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

    function Zone() external view onlyReader returns (address) {
        return address(zone());
    }

    function zone() internal view returns (ChatGroup) {
        return ChatGroup(address(at(ZONE)));
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
        MemberInfo[] members;
        uint256 member_count;
        uint256 last_update;
        address[] keys;
        bytes32 label_proof;
        bytes32 description_proof;
    }

    function InfoAggregateV1(uint256 max_size) external returns (Info memory) {
        address _zone = address(zone());
        if (_zone == address(0) || msg.sender == _zone || role(msg.sender) >= RoleType.None) {
            MemberInfo[] memory _member_infos = MemberRoles(Members(0, max_size));
            return Info({
                chat: address(this),
                owner: owner(),
                members: _member_infos,
                member_count: members.Size(),
                last_update: change_tracker(),
                keys: list_all_address(GROUP_KEYS),
                label_proof: LabelProof(),
                description_proof: DescriptionProof()
            });
        } else {
            return Info({
                chat: address(this),
                owner: address(0),
                members: new MemberInfo[](0),
                member_count: 0,
                last_update: 0,
                keys: new address[](0),
                label_proof: bytes32(0),
                description_proof: bytes32(0)
            });
        }
    }

    function DescriptionProof() public view onlyReader returns (bytes32) {
        return bytes32(dataValue(RoleType.Admin, 0x1596dc38e2ac5a6ddc5e019af4adcc1e017a04f510d57e69d6879d5d2996bb8e));
    }

    function LabelProof() public view onlyReader returns (bytes32) {
        return bytes32(dataValue(RoleType.Admin, 0x1b036544434cea9770a413fd03e0fb240e1ccbd10a452f7dba85c8eca9ca3eda));
    }
}
