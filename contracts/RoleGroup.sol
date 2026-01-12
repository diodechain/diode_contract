// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Group.sol";

/**
 * Generic Group
 */
contract RoleGroup is Group {
    using Set for Set.Data;

    mapping(address => uint256) roles;

    modifier onlyAdmin() {
        requireAdmin(msg.sender);
        _;
    }

    function requireAdmin(address _member) internal view virtual {
        require(role(_member) >= RoleType.Admin, "Only Admins and Owners can call this");
    }

    function transferOwnership(address payable newOwner) public override onlyOwner {
        _add(owner(), RoleType.Admin);
        super.transferOwnership(newOwner);
        _add(owner(), RoleType.Owner);
    }

    function SetRoleValue(uint256 _role, uint256 _key, uint256 _value) public {
        require(role(msg.sender) >= _role, "Only higher roles can set this");
        setDataValue(_role, _key, _value);
    }

    function RoleValue(uint256 _role, uint256 _key) public view virtual returns (uint256) {
        return dataValue(_role, _key);
    }

    function RoleValues(DataKey[] memory _keys) public view virtual returns (uint256[] memory) {
        uint256[] memory values = new uint256[](_keys.length);
        for (uint256 i = 0; i < _keys.length; i++) {
            values[i] = RoleValue(_keys[i].class, _keys[i].key);
        }
        return values;
    }

    function _add(address _member, uint256 _role) internal virtual {
        members.Add(_member);
        roles[_member] = _role;
        update_change_tracker();
    }

    function remove(address _member) internal virtual {
        members.Remove(_member);
        delete roles[_member];
        update_change_tracker();
    }

    function role(address _member) internal view returns (uint256) {
        if (_member == owner()) return RoleType.Owner;
        return roles[_member];
    }

    function devices(address _member) internal returns (address[] memory) {
        // Try/catch would be better, but the Diode L1 doesn't support it (still reverts)
        uint32 _size;
        assembly { _size := extcodesize(_member) }
        if (_size == 0) {
            return new address[](0);
        }
        Group device_group = Group(_member);
        address[] memory _devices = device_group.Members();
        address[] memory _devices_with_owner = new address[](_devices.length + 1);
        address _owner = device_group.owner();
        _devices_with_owner[0] = _owner;
        for (uint256 i = 0; i < _devices.length; i++) {
            if (_devices[i] == _owner) {
                // If the owner is also a member, return the devices without duplicated owner
                return _devices;
            }
            _devices_with_owner[i + 1] = _devices[i];
        }
        return _devices_with_owner;
    }

    function Role(address _member) external view virtual returns (uint256) {
        return role(_member);
    }

    struct MemberInfo {
        address member;
        uint256 role;
    }

    struct MemberInfoExtended {
        address member;
        uint256 role;
        address[] devices;
    }

    function MemberRoles() public virtual returns (MemberInfo[] memory) {
        address[] memory members = this.Members();
        MemberInfo[] memory memberInfos = new MemberInfo[](members.length);
        for (uint256 i = 0; i < members.length; i++) {
            memberInfos[i] = MemberInfo(members[i], role(members[i]));
        }

        return memberInfos;
    }

    function MembersExtended() public virtual returns (MemberInfoExtended[] memory) {
        address[] memory _members = this.Members();
        MemberInfoExtended[] memory memberInfos = new MemberInfoExtended[](_members.length);
        for (uint256 i = 0; i < _members.length; i++) {
            memberInfos[i] = MemberInfoExtended(_members[i], role(_members[i]), devices(_members[i]));
        }
        return memberInfos;
    }

    function MembersExtended(address[] memory _members) public virtual returns (MemberInfoExtended[] memory) {
        MemberInfoExtended[] memory memberInfos = new MemberInfoExtended[](_members.length);
        for (uint256 i = 0; i < _members.length; i++) {
            memberInfos[i] = MemberInfoExtended(_members[i], role(_members[i]), devices(_members[i]));
        }
        return memberInfos;
    }

    function MemberWithRole(uint256 _role) public virtual returns (MemberInfo[] memory) {
        address[] memory members = this.Members();
        MemberInfo[] memory memberInfos = new MemberInfo[](members.length);
        uint256 index = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (role(members[i]) == _role) {
                memberInfos[index] = MemberInfo(members[i], role(members[i]));
                index++;
            }
        }
        // Use inline assembly to resize the array to only return filled elements
        assembly {
            mstore(memberInfos, index)
        }
        return memberInfos;
    }

    function AddMember(address _member) external virtual onlyAdmin {
        _add(_member, RoleType.Member);
    }

    function AddMember(address _member, uint256 _role) external virtual onlyOwner {
        _add(_member, _role);
    }

    function RemoveSelf() external virtual {
        remove(msg.sender);
    }

    function RemoveMember(address _member) external virtual onlyAdmin {
        remove(_member);
    }
}
