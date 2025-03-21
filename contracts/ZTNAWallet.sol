// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "./sapphire/auth/SiweAuth.sol";

contract ZTNAWallet is SiweAuth {
    address owner;

    constructor() SiweAuth("ZTNAWallet") {
        owner = msg.sender;
    }

    function initialize(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
        siwe_initialize("ZTNAWallet");
    }

    function submit(address destination, bytes memory token, bytes memory data) external payable {
        require(authMsgSender(token) == owner, "Unauthorized");
        uint256 dataLength = data.length;
        uint256 value = msg.value;

        assembly {
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            let result := call(sub(gas(), 34710), destination, value, d, dataLength, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 { revert(0, 0) }
            default { return(0, returndatasize()) }
        }
    }

    function submit(address destination, bytes memory data) external payable {
        require(msg.sender == owner, "Unauthorized");
        uint256 dataLength = data.length;
        uint256 value = msg.value;

        assembly {
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            let result := call(sub(gas(), 34710), destination, value, d, dataLength, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 { revert(0, 0) }
            default { return(0, returndatasize()) }
        }
    }
}