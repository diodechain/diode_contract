// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
import "./Assert.sol";
import "../contracts/BNS.sol";
import "../contracts/Packages.sol";

contract PackagesTest {
    BNS bns;
    Packages packages;
    constructor() {
        bns = new BNS();
        packages = new Packages(bns);
    }

    function checkPackage() public {
        string memory domain_name = "loooooooong";
        bns.Register(domain_name, msg.sender);
        Assert.equal(bns.Resolve(domain_name), msg.sender, "domain_name should resolve to msg.sender");

        string memory package_name = "file.zip";
        bytes32 package_hash = keccak256("this is amazing");

        packages.AddPackage(domain_name, package_name, package_hash);

        Assert.equal(packages.LookupHash(domain_name, package_name), package_hash, "package_hash should match");
        Assert.notEqual(packages.LookupHash("other_name", package_name), package_hash, "package_hash should not match");
        Assert.notEqual(packages.LookupHash(domain_name, "other_package"), package_hash, "package_hash should not match");
    }
}
