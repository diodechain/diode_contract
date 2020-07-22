pragma solidity ^0.6.5;
import "./Assert.sol"; // this import is automatically injected by Remix.
import "../contracts/BNS.sol";

contract BNSTest {
    BNS BNSToTest;
    constructor() public {
        // proposalNames.push("short");
        // proposalNames.push("looooooooooooong");
        BNSToTest = new BNS(msg.sender);
    }

    function checkGoodname() public {
        string memory name = "loooooooong";
        BNSToTest.Register(name, msg.sender);
        Assert.equal(BNSToTest.Resolve(name), msg.sender, "name should resolve to msg.sender");
    }

    function checkGoodname2 () public returns (bool) {
        string memory name = "loooooooong2";
        (bool success, bytes memory error) = address(BNSToTest).call{gas: gasleft()}(
            abi.encodeWithSignature("Register(string,address)", name, msg.sender)
        );
        Assert.equal(BNSToTest.Resolve(name), msg.sender, "name should resolve to msg.sender");
        return Assert.equal(success, true, string(error));
    }

    function checkShortnameReverts () public returns (bool) {
        string memory name = "short";
        (bool success, ) = address(BNSToTest).call{gas: gasleft()}(
            abi.encodeWithSignature("Register(string,address)", name, msg.sender)
        );
        Assert.equal(success, false, "call should revert");
    }
}
