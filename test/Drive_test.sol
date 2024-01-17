pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";
import "../contracts/Chat.sol";
import "../contracts/Drive.sol";
import "../contracts/DriveInvites.sol";
import "../contracts/DriveFactory.sol";

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
    address number4;

    constructor() public {
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
        number4 = address(new CallForwarder(address(drive)));
    }

    function checkOwner() public {
        Assert.equal(address(this), drive.owner(), "address(this) should be owner");
        Assert.ok(drive.Role(address(this)) == RoleType.Owner, "address(this) should be RoleType.Owner");
        drive.AddMember(number1, RoleType.Admin);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 1, "Members() should return one member");
        Assert.equal(members[0], number1, "Members() should return [number1]");
    }

    function checkAdmin() public {
        Assert.ok(drive.Role(number1) == RoleType.Admin, "number1 should be RoleAdmin");
        Drive(number1).AddMember(number2);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 2, "Members() should return two members");
        Assert.equal(members[0], number1, "Members()[0] should return [number1]");
        Assert.equal(members[1], number2, "Members()[1] should return [number2]");
    }

    function checkMember() public view {
        Assert.ok(drive.Role(number2) == RoleType.Member, "number2 should be RoleMember");
    }

    function checkInvite() public {
        Assert.equal(address(this), drive.owner(), "address(this) should be owner");
        invites.Invite(salt, number3);
        
        address[] memory none  = invites.Invites();
        Assert.equal(none.length, 0, "This should have no invites");
        address[] memory recvd = DriveInvites(number3).Invites();
        Assert.equal(recvd.length, 1, "number3 should have 1 invite");
        Assert.equal(recvd[0], address(salt), "number3s invites should be for drive");
    }

    function checkMigrate() public {
        address[] memory members = drive.Members();
        Assert.equal(members.length, 2, "Members() should return two members");
        drive.Migrate();
        members = drive.Members();
        Assert.equal(members.length, 3, "Members() should return three members");
        Assert.equal(members[2], drive.owner(), "members[2] should be the owner");
    }

    function checkDomain() public {
        string memory name = drive.Name();
        Assert.greaterThan(bytes(name).length, uint256(0), "name should be longer than 0");
        address[] memory members = drive.Members(); 
        address[] memory results = bns.ResolveEntry(name).destinations;
        for (uint i = 0; i < members.length; i++) {
            Assert.equal(results[i], members[i], "name should resolve to drive members");
        }
    }

    function checkJoin() public {
        // This is a pregenerated signature, during test runs the msg.sender() check
        // in Drive.sol is disabled (fixed to 0) to make this possible with dynamic accounts
        // Password: lol => 0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc
        address pass = address(0x2B502D064Bd908805EA02E6A6F799c11F87AeCcc);
        uint8 rec = 27;
        bytes32 r = bytes32(0x0a81ebd45fca048189ad7c022750a55d4d506a10d34164183e207d71c4350b98);
        bytes32 s = bytes32(0x5617d73d70019ccb2612aba50f32d4a965b02d095d2b4f78b828e0e24ba9f8a0);
        
        drive.SetPasswordPublic(pass);
        Drive(number4).Join(rec, r, s);

        address[] memory members = drive.Members();
        Assert.equal(members.length, 4, "Members() should return four members");
        Assert.equal(members[3], number4, "members[3] should be the number4");
    }

    function checkTransfer() public {
        address[] memory members = drive.Members();
        Assert.equal(members[2], drive.owner(), "members[2] should be the owner");
        drive.transferOwnership(payable(members[1]));
        Assert.equal(members[1], drive.owner(), "members[1] should be the owner");
        Assert.equal(RoleType.Admin, drive.Role(members[2]), "members[2] should be admin now");
    }

    function checkChat() public {
        drive.AddChat(address(this), number1);
        Chat chat = Chat(drive.Chat(number1));
        Assert.notEqual(address(chat), address(0), "Chat should not be 0");
        Assert.equal(number1, chat.Key(0), "Initial key should match number1");
    }
}
