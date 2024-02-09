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

contract TestDrive is Drive {
    constructor() Drive(address(0x0)) {}
    function name_slot() public pure returns (uint256 _value) {
        assembly { _value := bns_name.slot }
    }
}

contract DriveJoinTest {
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

    function checkJoin() public {
        Assert.equal(drive.IsMember(number1), false, "number1 shouldn't be a member yet");

        // This is a pregenerated signature, during test runs the msg.sender() check
        // in Drive.sol is disabled (fixed to 0) to make this possible with dynamic accounts
        // Password: lol => 0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc
        address pass = address(0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc);
        uint8 rec = 27;
        bytes32 r = bytes32(0x0a81ebd45fca048189ad7c022750a55d4d506a10d34164183e207d71c4350b98);
        bytes32 s = bytes32(0x5617d73d70019ccb2612aba50f32d4a965b02d095d2b4f78b828e0e24ba9f8a0);
        
        drive.SetPasswordPublic(pass);
        Drive(number1).Join(rec, r, s);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 1, "Members() should return 1 members");
        Assert.equal(members[0], number1, "members[0] should be the number1");
        Assert.equal(drive.IsMember(number1), true, "number1 should be a member now");
        Assert.equal(drive.Role(number1), RoleType.Member, "number1 should be a member now");
    }

    function checkJoinTwo() public {
        drive.RemoveMember(number1);
        Assert.equal(drive.IsMember(number1), false, "number1 shouldn't be a member yet");

        // This is a pregenerated signature, during test runs the msg.sender() check
        // in Drive.sol is disabled (fixed to 0) to make this possible with dynamic accounts
        // Password: lol => 0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc
        address pass = address(0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc);
        uint8 rec = 27;
        bytes32 r = bytes32(0x0a81ebd45fca048189ad7c022750a55d4d506a10d34164183e207d71c4350b98);
        bytes32 s = bytes32(0x5617d73d70019ccb2612aba50f32d4a965b02d095d2b4f78b828e0e24ba9f8a0);
        
        drive.AddJoinCode(pass, uint256(-1), 1, RoleType.Reader);
        Drive(number1).Join(pass, rec, r, s);

        address[] memory members = drive.Members();
        Assert.equal(drive.IsMember(number1), true, "number1 be a member now");
        Assert.equal(drive.Role(number1), RoleType.Reader, "number1 be a reader now");
    }
}
