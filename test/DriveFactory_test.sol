// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";
import "../contracts/DriveFactory.sol";
import "../contracts/Drive.sol";

contract TestDrive2 is Drive {
    constructor(address _bns) Drive(_bns) {}

    function Version() external pure override returns (int256) {
        return 200;
    }
}

contract Dummy {}

contract DriveFactoryTest {
    BNS bns;
    Drive version1;
    Drive version2;
    address number1;
    address number2;
    DriveFactory factory;

    constructor() {
        version1 = new Drive(address(bns));
        version2 = new TestDrive2(address(bns));
        factory = new DriveFactory();

        number1 = address(new Dummy());
        number2 = address(new Dummy());
    }

    function testCreate2() public {
        bytes32 salt = hex"0011001100110011001100110011001100110011001100110011001100110011";
        address should = factory.Create2Address(salt);
        address raw = factory.Create(payable(address(this)), salt, address(version1));

        Assert.notEqual(raw, address(0), "Create2() should not return 0");
        Assert.equal(raw, should, "Create2() and Create2Address() should return the same address");

        Drive drive = Drive(raw);

        drive.AddMember(number1, RoleType.Admin);

        // Factory created contract should work normally
        Assert.equal(drive.Version(), 146, "Version() should be equal 144");
        acceptanceTest(drive);

        // Upgrade
        factory.Upgrade(salt, address(version2));

        // and test again
        Assert.equal(drive.Version(), 200, "Version() should be equal 200");
        acceptanceTest(drive);
    }

    function acceptanceTest(Drive drive) internal {
        Assert.equal(address(this), drive.owner(), "address(this) should be owner");
        Assert.ok(drive.Role(address(this)) == RoleType.Owner, "address(this) should be RoleType.Owner");
        drive.AddMember(number1, RoleType.Admin);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 1, "Members() should return one member");
        Assert.equal(members[0], number1, "Members() should return [number1]");

        Drive.MemberInfo[] memory memberInfos = drive.MemberRoles();
        Assert.equal(memberInfos.length, 1, "MemberRoles() should return one member");
        Assert.equal(memberInfos[0].member, number1, "MemberRoles() should return [number1]");
        Assert.equal(memberInfos[0].role, RoleType.Admin, "MemberRoles() should return [RoleType.Admin]");
    }

    function testMemberWithRole() public {
        Drive drive = new Drive(address(bns));

        drive.AddMember(number1, RoleType.Admin);
        drive.AddMember(number2, RoleType.Member);

        Drive.MemberInfo[] memory memberInfos = drive.MemberWithRole(RoleType.Admin);
        Assert.equal(memberInfos.length, 1, "MemberWithRole() should return one member");
        Assert.equal(memberInfos[0].member, number1, "MemberWithRole() should return [number1]");
        Assert.equal(memberInfos[0].role, RoleType.Admin, "MemberWithRole() should return [RoleType.Admin]");

        memberInfos = drive.MemberWithRole(RoleType.Member);
        Assert.equal(memberInfos.length, 1, "MemberWithRole() should return one member");
        Assert.equal(memberInfos[0].member, number2, "MemberWithRole() should return [number2]");
        Assert.equal(memberInfos[0].role, RoleType.Member, "MemberWithRole() should return [RoleType.Member]");
    }
}
