// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./RoleGroup.sol";

/**
 * Protected Role Group
 */
contract ProtectedRoleGroup is RoleGroup {
    using Set for Set.Data;

    modifier onlyReader() {
        requireReader(msg.sender);
        _;
    }

    function requireReader(address _member) internal view virtual {
        require(role(_member) >= RoleType.None, "Read access not allowed");
    }

    function OwnerValue(uint256 _key) public view virtual override onlyReader returns (uint256) {
        return super.OwnerValue(_key);
    }

    function MemberValue(address _member, uint256 _key) public view virtual override onlyReader returns (uint256) {
        return super.MemberValue(_member, _key);
    }

    function DataValue(uint256 _class, uint256 _key) public view virtual override onlyReader returns (uint256) {
        return super.DataValue(_class, _key);
    }

    function RoleValue(uint256 _role, uint256 _key) public view virtual override onlyReader returns (uint256) {
        return super.RoleValue(_role, _key);
    }

    function Role(address _member) external view virtual override onlyReader returns (uint256) {
        return role(_member);
    }

    function Members() public view virtual override onlyReader returns (address[] memory) {
        return super.Members();
    }

    function MemberRoles() public view override onlyReader returns (MemberInfo[] memory) {
        return super.MemberRoles();
    }

    function MemberWithRole(uint256 _role) public view override onlyReader returns (MemberInfo[] memory) {
        return super.MemberWithRole(_role);
    }

    function IsMember(address _member) public view override onlyReader returns (bool) {
        return super.IsMember(_member);
    }
}
