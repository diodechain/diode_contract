pragma solidity ^0.6.5;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/Drive.sol";

contract DriveTest {
    Drive drive;
    address number1;
    address number2;
    address number3;

    constructor() public {
        drive = new Drive();
        number1 = address(new CallForwarder(address(drive)));
        number2 = address(new CallForwarder(address(drive)));
        number3 = address(new CallForwarder(address(drive)));
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


}
