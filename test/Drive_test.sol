pragma solidity ^0.6.5;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/Drive.sol";
import "../contracts/DriveInvites.sol";

contract DriveTest {
    DriveInvites invites;
    Drive drive;
    address number1;
    address number2;
    address number3;

    constructor() public {
        drive = new Drive();
        invites = new DriveInvites();
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
        invites.Invite(drive, number3);
        
        address[] memory none  = invites.Invites();
        Assert.equal(none.length, 0, "This should have no invites");
        address[] memory recvd = DriveInvites(number3).Invites();
        Assert.equal(recvd.length, 1, "number3 should have 1 invite");
        Assert.equal(recvd[0], address(drive), "number3s invites should be for drive");

    }


}
