pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";
import "../contracts/Drive.sol";
import "../contracts/DriveInvites.sol";
import "../contracts/DriveFactory.sol";

contract TestDrive is Drive {
    BNS bns_addr;
    function SetBNS(BNS _bns) public { bns_addr = _bns; }
    function bns() internal override view returns (IBNS) { return bns_addr; }
}

contract TestDriveInvites is DriveInvites {
    IDriveFactory f_addr;
    function SetFactory(IDriveFactory addr) public { f_addr = addr; }
    function factory() internal override view returns (IDriveFactory) { return f_addr; }
}

contract DriveTest {
    BNS bns;
    TestDriveInvites invites;
    DriveFactory factory;
    address salt;
    bytes32 salt32;
    TestDrive drive;
    address number1;
    address number2;
    address number3;

    constructor() public {
        bns = new BNS();
        factory = new DriveFactory();
        TestDrive code = new TestDrive();
        salt = address(code);
        salt32 = bytes32(uint256(salt));
        drive = TestDrive(factory.Create(payable(address(this)), salt32, address(code)));
        drive.SetBNS(bns);
        invites = new TestDriveInvites();
        invites.SetFactory(IDriveFactory(address(factory)));
        number1 = address(new CallForwarder(address(drive)));
        number2 = address(new CallForwarder(address(drive)));
        number3 = address(new CallForwarder(address(invites)));
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
}
