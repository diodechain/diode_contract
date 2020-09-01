pragma solidity ^0.6.5;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";
import "../contracts/Proxy.sol";

contract BNSTest {
    BNS instance;
    CallForwarder instanceVia; // used as second account 
    Proxy proxy; // test proxy 
    constructor() public {
        instance = new BNS();
        instanceVia = new CallForwarder(address(instance));
        proxy = new Proxy(address(instance), address(this));
    }

    function checkGoodname() public {
        string memory name = "loooooooong";
        instance.Register(name, msg.sender);
        Assert.equal(instance.Resolve(name), msg.sender, "name should resolve to msg.sender");
    }

    function checkGoodnameProxy() public {
        string memory name = "loooooooong";
        BNS proxied = BNS(address(proxy));
        proxied.Register(name, msg.sender);
        Assert.equal(proxied.Resolve(name), msg.sender, "name should resolve to msg.sender");
    }

    function checkGoodname2 () public returns (bool) {
        string memory name = "loooooooong2";
        bool success = _register(name, msg.sender);
        Assert.equal(instance.Resolve(name), msg.sender, "name should resolve to msg.sender");
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
        Assert.equal(instance.Resolve(name), msg.sender, "name should resolve to msg.sender");
        Assert.equal(_register(name, address(this)), true, "registering again from same ");
        Assert.equal(instance.Resolve(name), address(this), "name should resolve to this");
    }

    function checkReRegisterFails() public {
        string memory name = "sample-name";
        address prev = instance.Resolve(name);
        address test = address(msg.sender);
        Assert.notEqual(prev, test, "before test runs prev and test should not be equal");
        bool success = _register2(name, test);
        Assert.notEqual(prev, test, "after test runs prev and test should still not be equal");
        Assert.notOk(success, "register should have failed");
    }

    function checkReverse() public {
        string memory name = "sample-name";

        // Setting up registered name to points to two different addresses
        address[] memory addresses = new address[](2);
        addresses[0] = address(msg.sender);
        addresses[1] = address(this);
        instance.RegisterMultiple(name, addresses);
        
        // Initially both should return an empty string
        string memory empty;
        Assert.equal(empty, instance.ResolveReverse(address(msg.sender)), "ResolveReverse(address(msg.sender)) should be empty");
        Assert.equal(empty, instance.ResolveReverse(address(this)), "ResolveReverse(address(this)) should be empty");

        // Both should RegisterReverse fine, because both are in the forward entry: 
        Assert.ok(_registerReverse(address(msg.sender), name), "registering address(msg.sender) should work");
        Assert.ok(_registerReverse(address(this), name), "registering address(this) should work");
        // Registering another a not forward mapped address should fail
        Assert.notOk(_registerReverse(address(0), name), "registering not mapped address should fail");

        // After setting should return that new value
        Assert.equal(name, instance.ResolveReverse(address(msg.sender)), "ResolveReverse(address(msg.sender)) should match address");
        Assert.equal(name, instance.ResolveReverse(address(this)), "ResolveReverse(address(this)) should match address");

        // Overriding should be protected for address(this)
        string memory name2 = "sample-name2";
        instance.RegisterMultiple(name2, addresses);

        Assert.ok(_registerReverse2(address(msg.sender), name2), "overriding msg.sender assignment should succeed");
        Assert.notOk(_registerReverse2(address(this), name2), "overriding this assignment should fail");
    }

    function checkProperties() public {
        string memory name = "sample-name-props";

        // Setting up registered name
        instance.Register(name, address(this));

        // Storing some props
        string memory prop0 = "404=https://www.lego.com/404";
        instance.AddProperty(name, prop0);
        Assert.equal(prop0, instance.GetProperty(name, 0), "should match set-0 value");

        string memory prop1 = "author=Dominic Letz";
        instance.AddProperty(name, prop1);
        Assert.equal(prop1, instance.GetProperty(name, 1), "should match set-1 value");
        
        // Getting prop array (does not seem to work in solidity tests)
        // string[] memory props = instance.GetProperties(name);
        // Assert.equal(props[0], prop0, "[0] should match 0 prop");
        // Assert.equal(props[1], prop1, "[1] should match 1 prop");
        // Assert.equal(props.length, 2, "we should only have two props");


        // Deleting a prop
        Assert.equal(instance.GetPropertyLength(name), 2, "we should have two props");
        instance.DeleteProperty(name, 0);
        Assert.equal("author=Dominic Letz", instance.GetProperty(name, 0), "should match set-0 value after delete");
        Assert.equal(instance.GetPropertyLength(name), 1, "we should have one prop left");
    }


    // HELPER FUNCTIONS TO MAKE REVERT CHECKABLE AND PROXY CALLS
    function _register(string memory name, address target) internal returns (bool) {
        (bool success, ) = address(instance).call{gas: gasleft()}(
            abi.encodeWithSignature("Register(string,address)", name, target)
        );
        return success;
    }
    
    function _register2(string memory name, address target) internal returns (bool) {
        (bool success, ) = address(instanceVia).call{gas: gasleft()}(
            abi.encodeWithSignature("Register(string,address)", name, target)
        );
        return success;
    }

    function _registerReverse(address target, string memory name) internal returns (bool) {
        (bool success, ) = address(instance).call{gas: gasleft()}(
            abi.encodeWithSignature("RegisterReverse(address,string)", target, name)
        );
        return success;
    }

    function _registerReverse2(address target, string memory name) internal returns (bool) {
        (bool success, ) = address(instanceVia).call{gas: gasleft()}(
            abi.encodeWithSignature("RegisterReverse(address,string)", target, name)
        );
        return success;
    }
}
