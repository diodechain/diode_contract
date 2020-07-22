pragma solidity ^0.6.5;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";

contract BNSTest {
    BNS BNSToTest;
    CallForwarder BNSVia2; // used as second account 
    constructor() public {
        BNSToTest = new BNS(msg.sender);
        BNSVia2 = new CallForwarder(address(BNSToTest));
    }

    function _register2(string memory name, address target) internal returns (bool) {
        (bool success, ) = address(BNSVia2).call{gas: gasleft()}(
            abi.encodeWithSignature("Register(string,address)", name, target)
        );
        return success;
    }

    function _register(string memory name, address target) internal returns (bool) {
        (bool success, ) = address(BNSToTest).call{gas: gasleft()}(
            abi.encodeWithSignature("Register(string,address)", name, target)
        );
        return success;
    }

    function checkGoodname() public {
        string memory name = "loooooooong";
        BNSToTest.Register(name, msg.sender);
        Assert.equal(BNSToTest.Resolve(name), msg.sender, "name should resolve to msg.sender");
    }

    function checkGoodname2 () public returns (bool) {
        string memory name = "loooooooong2";
        bool success = _register(name, msg.sender);
        Assert.equal(BNSToTest.Resolve(name), msg.sender, "name should resolve to msg.sender");
        return Assert.ok(success, "Registering should succeed");
    }

    function checkShortnameReverts () public returns (bool) {
        string memory name = "short";
        bool success = _register(name, msg.sender);
        Assert.notOk(success, "registering a too short name should revert");
    }

    function checkDoubleRegister() public {
        string memory name = "sample-name";
        Assert.equal(_register(name, msg.sender), true, "registering once should work");
        Assert.equal(BNSToTest.Resolve(name), msg.sender, "name should resolve to msg.sender");
        Assert.equal(_register(name, address(this)), true, "registering again from same ");
        Assert.equal(BNSToTest.Resolve(name), address(this), "name should resolve to this");
    }

    function checkReRegisterFails() public {
        string memory name = "sample-name";
        address prev = BNSToTest.Resolve(name);
        address test = address(msg.sender);
        Assert.notEqual(prev, test, "before test runs prev and test should not be equal");
        bool success = _register2(name, test);
        Assert.notEqual(prev, test, "after test runs prev and test should still not be equal");
        Assert.notOk(success, "register should have failed");
    }

    function checkReverse() public {
        string memory name = "sample-name";
        address current = BNSToTest.Resolve(name);
        
        string memory empty;
        Assert.equal(empty, BNSToTest.ResolveReverse(current), "should be empty");
        BNSToTest.RegisterReverse(current, name);
        Assert.equal(name, BNSToTest.ResolveReverse(current), "should match address");
    }
}
