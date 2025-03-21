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
        assembly {
            _value := bns_name.slot
        }
    }
}

contract DriveTest {
    BNS bns;
    DriveInvites invites;
    DriveFactory factory;
    address salt;
    bytes32 salt32;
    Drive drive;
    address number1;
    address number2;
    address number3;

    constructor() {
        bns = new BNS();
        factory = new DriveFactory();
        Drive code = new Drive(address(bns));
        salt = address(code);
        salt32 = bytes32(uint256(salt));
        drive = Drive(factory.Create(payable(address(this)), salt32, address(code)));
        invites = new DriveInvites(address(factory));
        number1 = address(new CallForwarder(address(drive)));
        number2 = address(new CallForwarder(address(drive)));
        number3 = address(new CallForwarder(address(invites)));
    }

    function testOwner() public {
        Assert.equal(address(this), drive.owner(), "address(this) should be owner");
        Assert.ok(drive.Role(address(this)) == RoleType.Owner, "address(this) should be RoleType.Owner");
        drive.AddMember(number1, RoleType.Admin);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 1, "Members() should return one member");
        Assert.equal(members[0], number1, "Members() should return [number1]");
    }

    function testAdmin() public {
        drive.AddMember(number1, RoleType.Admin);
        Assert.ok(drive.Role(number1) == RoleType.Admin, "number1 should be RoleAdmin");
        Drive(number1).AddMember(number2);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 2, "Members() should return two members");
        Assert.equal(members[0], number1, "Members()[0] should return [number1]");
        Assert.equal(members[1], number2, "Members()[1] should return [number2]");
    }

    function testMember() public {
        drive.AddMember(number1, RoleType.Admin);
        Drive(number1).AddMember(number2);
        Assert.ok(drive.Role(number2) == RoleType.Member, "number2 should be RoleMember");
    }

    function testInvite() public {
        Assert.equal(address(this), drive.owner(), "address(this) should be owner");
        invites.Invite(salt, number3);

        address[] memory none = invites.Invites();
        Assert.equal(none.length, 0, "This should have no invites");
        address[] memory recvd = DriveInvites(number3).Invites();
        Assert.equal(recvd.length, 1, "number3 should have 1 invite");
        Assert.equal(recvd[0], address(salt), "number3s invites should be for drive");
    }

    function testMigrate() public {
        drive.AddMember(number1, RoleType.Admin);
        drive.AddMember(number2);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 2, "Members() should return two members");
        drive.Migrate();
        members = drive.Members();
        Assert.equal(members.length, 3, "Members() should return three members");
        Assert.equal(members[2], drive.owner(), "members[2] should be the owner");
        Assert.equal(members[2], address(this), "members[2] should be (this)");
    }

    function testDomain() public {
        string memory name = drive.Name();
        Assert.greaterThan(bytes(name).length, uint256(0), "name should be longer than 0");
        address[] memory members = drive.Members();
        address[] memory results = bns.ResolveEntry(name).destinations;
        for (uint256 i = 0; i < members.length; i++) {
            Assert.equal(results[i], members[i], "name should resolve to drive members");
        }
    }

    function testTransfer() public {
        drive.AddMember(number1, RoleType.Admin);
        drive.AddMember(number2);
        drive.Migrate();

        address[] memory members = drive.Members();
        Assert.equal(members[2], drive.owner(), "members[2] should be the owner");
        drive.transferOwnership(payable(members[1]));
        Assert.equal(members[1], drive.owner(), "members[1] should be the owner");
        Assert.equal(RoleType.Admin, drive.Role(members[2]), "members[2] should be admin now");
    }

    function testChat() public {
        drive.AddChat(address(this), number2);
        ChatGroup chat = ChatGroup(drive.Chat(number2));
        Assert.notEqual(address(chat), address(0), "Chat should not be 0");
        Assert.equal(number2, chat.Key(0), "Initial key should match number2");

        address[] memory chats = drive.Chats();
        Assert.equal(chats.length, 1, "There should be exactly one chat");
        Assert.equal(chats[0], address(chat), "chat == chats[0]");

        drive.RemoveChat(address(chat));
        address[] memory chats2 = drive.Chats();
        Assert.equal(chats2.length, 0, "Chat should be removed now");

        Assert.equal(chat.owner(), address(this), "Chat owner should be (this)");
        chat.AddMember(number1);
        chat.transferOwnership(payable(number1));
        Assert.equal(chat.owner(), number1, "Chat owner should be number1");
        Assert.equal(drive.Role(address(this)) >= RoleType.Admin, true, "(this) should be role admin");
        drive.RemoveMember(number1);
        chat.ElectNewOwner(payable(address(this)));
        Assert.equal(chat.owner(), address(this), "Chat owner be reset to (this)");
    }

    function testSlotPos() public {
        TestDrive test = new TestDrive();
        Assert.equal(test.name_slot(), 57, "name_slot should be at 57");
    }
}
