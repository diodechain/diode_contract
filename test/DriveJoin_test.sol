// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";
import "../contracts/ChatGroup.sol";
import "../contracts/Drive.sol";
import "../contracts/DriveInvites.sol";
import "../contracts/DriveFactory.sol";
import "./forge-std/Test.sol";

contract TestDrive is Drive {
    constructor() Drive(address(0x0)) {}

    function name_slot() public pure returns (uint256 _value) {
        assembly {
            _value := bns_name.slot
        }
    }
}

contract DriveJoinTest is Test {
    BNS bns;
    DriveFactory factory;
    address salt;
    bytes32 salt32;
    Drive drive;
    address number1;

    constructor() {
        bns = new BNS();
        factory = new DriveFactory();
        Drive code = new Drive(address(bns));
        salt = address(code);
        salt32 = bytes32(uint256(salt));
        drive = Drive(factory.Create(payable(address(this)), salt32, address(code)));
        number1 = address(new CallForwarder(address(drive)));
    }

    function testJoin() public {
        address newMember = address(0);
        Assert.equal(drive.IsMember(newMember), false, "newMember shouldn't be a member yet");

        // This is a pregenerated signature, for address(0) during test runs the msg.sender() check
        // in Drive.sol is tricked using vm.prank() from forge
        // Password: lol => 0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc
        address pass = address(0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc);
        uint8 rec = 27;
        bytes32 r = bytes32(0x0a81ebd45fca048189ad7c022750a55d4d506a10d34164183e207d71c4350b98);
        bytes32 s = bytes32(0x5617d73d70019ccb2612aba50f32d4a965b02d095d2b4f78b828e0e24ba9f8a0);

        drive.SetPasswordPublic(pass);
        vm.prank(newMember);
        drive.Join(rec, r, s);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 1, "Members() should return 1 members");
        Assert.equal(members[0], newMember, "members[0] should be the newMember");
        Assert.equal(drive.IsMember(newMember), true, "newMember should be a member now");
        Assert.equal(drive.Role(newMember), RoleType.Member, "newMember should be a member now");
    }

    function testJoinTwo() public {
        address newMember = address(0);
        Assert.equal(drive.IsMember(newMember), false, "newMember shouldn't be a member yet");

        // This is a pregenerated signature, for address(0) during test runs the msg.sender() check
        // in Drive.sol is tricked using vm.prank() from forge
        // Password: lol => 0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc
        address pass = address(0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc);
        uint8 rec = 27;
        bytes32 r = bytes32(0x0a81ebd45fca048189ad7c022750a55d4d506a10d34164183e207d71c4350b98);
        bytes32 s = bytes32(0x5617d73d70019ccb2612aba50f32d4a965b02d095d2b4f78b828e0e24ba9f8a0);

        drive.AddJoinCode(pass, uint256(-1), 1, RoleType.Reader);
        vm.prank(newMember);
        drive.Join(pass, rec, r, s);

        address[] memory members = drive.Members();
        Assert.equal(members[0], newMember, "members[0] should be the newMember");
        Assert.equal(drive.IsMember(newMember), true, "newMember be a member now");
        Assert.equal(drive.Role(newMember), RoleType.Reader, "newMember be a reader now");
    }
}
