pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/DrivePointers.sol";

contract DrivePointersTest {
    DrivePointers ptrs;
    address number1;
    address number2;
    address person1;
    address person2;

    constructor() public {
        ptrs = new DrivePointers();
        number1 = address(new CallForwarder(address(ptrs)));
        number2 = address(new CallForwarder(address(ptrs)));
        person1 = address(new CallForwarder(address(ptrs)));
        person2 = address(new CallForwarder(address(ptrs)));
    }

    function checkSet() public {
        uint256 key = 123;

        ptrs.Set(key, number1);
        Assert.equal(address(this), ptrs.GetOwner(key), "address(this) should be the ptr owner");
        Assert.equal(number1, ptrs.GetDrive(key), "number1 should be the ptr value");
    }

    function checkUpdate() public {
        uint256 key = 123;

        Assert.equal(number1, ptrs.GetDrive(key), "number1 should be the ptr value");
        ptrs.Set(key, number2);
        Assert.equal(number2, ptrs.GetDrive(key), "number2 should be updated the ptr value");
    }

    function checkConflict() public {
        uint256 key = 234;

        Assert.ok(_setVia(person1, key, number1), "setting 234 from person1 should work");
        Assert.equal(person1, ptrs.GetOwner(key), "owner should be person1");
        Assert.notOk(_setVia(person2, key, number2), "updating 234 from person 2 should fail");
        Assert.equal(number1, ptrs.GetDrive(key), "key 234 should still point to number1");
    }

    function _setVia(address via, uint256 key, address drive) internal returns (bool) {
        (bool success, ) = via.call{gas: gasleft()}(
            abi.encodeWithSignature("Set(uint256,address)", key, drive)
        );
        return success;
    }
}
