// Diode Contracts
// Copyright 2020 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;

contract ProxyResolver {
    address owner = msg.sender;
    mapping(bytes32 => address) delegates;

    function update(bytes32 ref, address newDelegateAddress) public {
        require(msg.sender == owner, "Permission denied");
        delegates[ref] = newDelegateAddress;
    }

    function resolve(bytes32 ref) external view returns (address) {
        return delegates[ref];
    }
}