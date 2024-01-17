pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/Group.sol";

contract GroupTest {
    Group group;
    address member1;

    constructor() public {
        group = new Group();
        member1 = address(new CallForwarder(address(group)));
    }

    function checkOwner() public {
        Assert.equal(address(this), group.owner(), "owner() should be this");

        group.SetOwnerValue(1, 15);
        Assert.equal(15, group.OwnerValue(1), "OwnerValue should be 15");
        Assert.equal(15, group.DataValue(RoleType.Owner, 1), "DataValue should be 15");

        group.SetMemberValue(1, 36);
        Assert.equal(36, group.MemberValue(address(this), 1), "MemberValue should be 36");
        Assert.equal(36, group.DataValue(uint256(address(this)), 1), "DataValue should be 36");
    }

    // function checkMember() public {

    // }
}
