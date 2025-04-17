// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/DriveMember.sol";
import "../contracts/BNS.sol";
import "../contracts/DriveFactory.sol";
import "../contracts/Drive.sol";

contract Dummy {}

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

    function testMembership() public {
        bytes32 salt = hex"0011001100110011001100110011001100110011001100110011001100110011";

        address raw_member = factory.Create(payable(address(this)), salt, address(member_impl));
        Assert.notEqual(raw_member, address(0), "raw_member should not be 0");

        DriveMember member = DriveMember(raw_member);
        Assert.equal(member.IsMember(address(this)), true, "this should be considered a member");

        Assert.equal(member.IsMember(number1), false, "number1 should not yet be a member");
        member.AddMember(number1);
        Assert.equal(member.IsMember(number1), true, "number1 should now be a member");
    }

    function testStorageLocation() public {
        // Create a new DriveMember instance for testing storage
        DriveMember storageTestMember = new DriveMember();

        // Add a drive to test with
        address testDrive = address(0x1234567890123456789012345678901234567890);
        storageTestMember.AddDrive(testDrive);

        // Test using the Drives() accessor method
        address[] memory drives = storageTestMember.Drives();
        Assert.equal(drives.length, 1, "Should have 1 drive in the array");
        Assert.equal(drives[0], testDrive, "Drive address should match the added drive");

        // Test using the low-level storage access
        // The additional_drives array is stored at slot 55 in the DriveMember contract
        uint256 driveCount = storageTestMember.list_size(55);
        Assert.equal(driveCount, 1, "Should have 1 drive in storage");

        // Get the drive address from storage
        address storedDrive = address(uint160(storageTestMember.list_at(55, 0)));
        Assert.equal(storedDrive, testDrive, "Drive address in storage should match");

        // Add another drive to test multiple entries
        address testDrive2 = address(0x2345678901234567890123456789012345678901);
        storageTestMember.AddDrive(testDrive2);

        // Verify with Drives() method
        drives = storageTestMember.Drives();
        Assert.equal(drives.length, 2, "Should have 2 drives in the array");
        Assert.equal(drives[1], testDrive2, "Second drive address should match");

        // Verify with storage access
        driveCount = storageTestMember.list_size(55);
        Assert.equal(driveCount, 2, "Should have 2 drives in storage");
        storedDrive = address(uint160(storageTestMember.list_at(55, 1)));
        Assert.equal(storedDrive, testDrive2, "Second drive address in storage should match");
    }
}
