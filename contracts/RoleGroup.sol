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
        require(role(msg.sender) >= RoleType.Admin, "Only Admins and Owners can call this");

        _;
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

    function Role(address _member) external view virtual returns (uint256) {
        return role(_member);
    }

    struct MemberInfo {
        address member;
        uint256 role;
    }

    function MemberRoles() public view virtual returns (MemberInfo[] memory) {
        address[] memory members = this.Members();
        MemberInfo[] memory memberInfos = new MemberInfo[](members.length);
        for (uint256 i = 0; i < members.length; i++) {
            memberInfos[i] = MemberInfo(members[i], role(members[i]));
        }

        return memberInfos;
    }

    function MemberWithRole(uint256 _role) public view virtual returns (MemberInfo[] memory) {
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
