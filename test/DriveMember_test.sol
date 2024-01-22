// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/DriveMember.sol";
import "../contracts/BNS.sol";
import "../contracts/DriveFactory.sol";
import "../contracts/Drive.sol";

contract Dummy {
}

contract DriveMemberTest {
    BNS bns;
    Drive drive_impl;
    DriveMember member_impl;
    address number1;
    DriveFactory factory;

    constructor() {
        drive_impl = new Drive(address(bns));
        member_impl = new DriveMember();
        factory = new DriveFactory();
    
        number1 = address(new Dummy());
    }

    function checkMembership() public {
        bytes32 salt = hex"0011001100110011001100110011001100110011001100110011001100110011";

        address raw_member = factory.Create(payable(address(this)), salt, address(member_impl));
        Assert.notEqual(raw_member, address(0), "raw_member should not be 0");


        DriveMember member = DriveMember(raw_member);
        Assert.equal(member.IsMember(address(this)), true, "this should be considered a member");

        Assert.equal(member.IsMember(number1), false, "number1 should not yet be a member");
        member.AddMember(number1);
        Assert.equal(member.IsMember(number1), true, "number1 should now be a member");
    }
}
