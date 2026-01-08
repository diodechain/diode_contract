// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/DriveMember.sol";
import "../contracts/BNS.sol";
import "../contracts/DriveFactory.sol";
import "../contracts/Drive.sol";
import "./forge-std/Test.sol";

contract Dummy {}

// Simple contract to receive and track meta transaction calls
contract MetaTransactionReceiver {
    bool public called;
    address public caller;
    bytes public data;
    uint256 public value;

    function testCall() public {
        called = true;
        caller = msg.sender;
    }

    function testCallWithData(bytes memory _data) public {
        called = true;
        caller = msg.sender;
        data = _data;
    }

    function testCallWithValue() public payable {
        called = true;
        caller = msg.sender;
        value = msg.value;
    }
}

// New implementation contract for testing upgrades
contract DriveMemberV2 {
    function Version() external pure returns (int256) {
        return 200; // Different version number
    }

    // Include a minimal interface to be compatible
    function initialize(address payable arg_owner) public {}
    function owner() public view returns (address payable) {}
    function IsMember(address _member) public view returns (bool) {}
}

contract DriveMemberTest is Test {
    BNS bns;
    Drive drive;
    DriveMember member_impl;
    address number1;
    address number2;
    DriveFactory factory;

    constructor() {
        drive = new Drive(address(bns));
        member_impl = new DriveMember();
        factory = new DriveFactory();

        number1 = address(new Dummy());
        number2 = address(new Dummy());
    }

    function testMembership() public {
        bytes32 salt = hex"0011001100110011001100110011001100110011001100110011001100110011";

        address raw_member = factory.Create(payable(address(this)), salt, address(member_impl));
        Assert.notEqual(raw_member, address(0), "raw_member should not be 0");

        DriveMember member = DriveMember(raw_member);
        Assert.equal(member.owner(), address(this), "owner should be the deployer");
        Assert.equal(member.IsMember(address(this)), true, "this should be considered a member");

        Assert.equal(member.IsMember(number1), false, "number1 should not yet be a member");
        member.AddMember(number1);
        Assert.equal(member.IsMember(number1), true, "number1 should now be a member");

        address member_address = address(member);
        drive.AddMember(member_address, RoleType.Member);
        Assert.equal(drive.IsMember(member_address), true, "member should be a member of the drive");

        Drive.MemberInfoExtended[] memory memberInfos = drive.MembersExtended();
        Assert.equal(memberInfos.length, 1, "MembersExtended() should return one member");
        Assert.equal(memberInfos[0].member, member_address, "MembersExtended() should return [member]");
        Assert.equal(memberInfos[0].role, RoleType.Member, "MembersExtended() should return [RoleType.Member]");
        Assert.equal(memberInfos[0].devices.length, 1, "MembersExtended() should return [1 devices]");
        Assert.equal(memberInfos[0].devices[0], number1, "MembersExtended() should return [number1]");

        drive.AddMember(number2, RoleType.Member);
        memberInfos = drive.MembersExtended();
        Assert.equal(memberInfos.length, 2, "MembersExtended() should return two members");
        Assert.equal(memberInfos[0].member, member_address, "MembersExtended() should return [member]");
        Assert.equal(memberInfos[0].role, RoleType.Member, "MembersExtended() should return [RoleType.Member]");
        Assert.equal(memberInfos[0].devices.length, 1, "MembersExtended() should return [1 devices]");
        Assert.equal(memberInfos[0].devices[0], number1, "MembersExtended() should return [number1]");
        Assert.equal(memberInfos[1].member, number2, "MembersExtended() should return [number2]");
        Assert.equal(memberInfos[1].role, RoleType.Member, "MembersExtended() should return [RoleType.Member]");
        Assert.equal(memberInfos[1].devices.length, 0, "MembersExtended() should return [0 devices]");
    }

    function testSubmitMetaTransaction() public {
        bytes32 salt = hex"0011001100110011001100110011001100110011001100110011001100110011";

        address raw_member = factory.Create(payable(address(this)), salt, address(member_impl));
        DriveMember member = DriveMember(raw_member);

        // Create a signer with a known private key
        uint256 signerKey = 0x1234567890123456789012345678901234567890123456789012345678901234;
        address signer = vm.addr(signerKey);

        // Add the signer as a member
        member.AddMember(signer);
        Assert.equal(member.IsMember(signer), true, "signer should be a member");

        // Create a receiver contract to test the meta transaction
        MetaTransactionReceiver receiver = new MetaTransactionReceiver();
        Assert.equal(receiver.called(), false, "receiver should not be called yet");

        // Get the current nonce for the signer
        uint256 nonce = member.Nonce(signer);
        Assert.equal(nonce, 0, "nonce should start at 0");

        // Set a deadline in the future
        uint256 deadline = block.timestamp + 1 hours;

        // Prepare the call data to call testCall() on the receiver
        bytes memory callData = abi.encodeWithSignature("testCall()");

        // Compute the transaction digest
        bytes32 digest = member.TransactionDigest(nonce, deadline, address(receiver), callData);

        // Sign the digest
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);

        // Submit the meta transaction
        member.SubmitMetaTransaction(nonce, deadline, address(receiver), callData, v, r, s);

        // Verify the transaction was executed
        Assert.equal(receiver.called(), true, "receiver should have been called");
        Assert.equal(receiver.caller(), address(member), "caller should be the DriveMember contract");

        // Verify the nonce was incremented
        uint256 newNonce = member.Nonce(signer);
        Assert.equal(newNonce, nonce + 1, "nonce should have been incremented");
    }

    function testFactoryUpgrade() public {
        uint256 ownerKey = 0x1111111111111111111111111111111111111111111111111111111111111111;
        address owner = vm.addr(ownerKey);

        bytes32 salt = hex"0022002200220022002200220022002200220022002200220022002200220022";
        address raw_member = factory.Create(payable(owner), salt, address(member_impl));
        DriveMember member = DriveMember(raw_member);

        Assert.equal(member.owner(), owner, "owner should be the deployer");
        Assert.equal(member.Version(), 122, "initial version should be 122");

        DriveMemberV2 newImpl = new DriveMemberV2();

        // Use vm.prank to call Nonce as the owner (required for onlyReader modifier)
        vm.prank(owner);
        uint256 nonce = member.Nonce(owner);
        Assert.equal(nonce, 0, "nonce should start at 0");

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory data = abi.encode(address(newImpl));
        bytes32 digest = member.TransactionDigest(nonce, deadline, address(factory), data);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, digest);
        member.FactoryUpgrade(salt, address(newImpl), v, nonce, deadline, r, s);

        Assert.equal(member.Version(), 200, "version should be upgraded to 200");
    }

    /**
     * function testStorageLocation() public {
     *     // Create a new DriveMember instance for testing storage
     *     DriveMember storageTestMember = new DriveMember();
     *
     *     // Add a drive to test with
     *     address testDrive = address(0x1234567890123456789012345678901234567890);
     *     storageTestMember.AddDrive(testDrive);
     *
     *     // Test using the Drives() accessor method
     *     address[] memory drives = storageTestMember.Drives();
     *     Assert.equal(drives.length, 1, "Should have 1 drive in the array");
     *     Assert.equal(drives[0], testDrive, "Drive address should match the added drive");
     *
     *     // Test using the low-level storage access
     *     // The additional_drives array is stored at slot 55 in the DriveMember contract
     *     uint256 driveCount = storageTestMember.list_size(55);
     *     Assert.equal(driveCount, 1, "Should have 1 drive in storage");
     *
     *     // Get the drive address from storage
     *     address storedDrive = address(uint160(storageTestMember.list_at(55, 0)));
     *     Assert.equal(storedDrive, testDrive, "Drive address in storage should match");
     *
     *     // Add another drive to test multiple entries
     *     address testDrive2 = address(0x2345678901234567890123456789012345678901);
     *     storageTestMember.AddDrive(testDrive2);
     *
     *     // Verify with Drives() method
     *     drives = storageTestMember.Drives();
     *     Assert.equal(drives.length, 2, "Should have 2 drives in the array");
     *     Assert.equal(drives[1], testDrive2, "Second drive address should match");
     *
     *     // Verify with storage access
     *     driveCount = storageTestMember.list_size(55);
     *     Assert.equal(driveCount, 2, "Should have 2 drives in storage");
     *     storedDrive = address(uint160(storageTestMember.list_at(55, 1)));
     *     Assert.equal(storedDrive, testDrive2, "Second drive address in storage should match");
     * }
     */
}
