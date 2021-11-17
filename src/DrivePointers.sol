// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/**
 * DrivePointers Smart Contract
 */
contract DrivePointers {
    struct Pointer {
        address drive;
        address owner;
    }

    mapping(uint256 => Pointer) ptrs;

    constructor() public {
    }

    function Set(uint256 key, address drive) external {
        Pointer memory ptr = ptrs[key];
        require(ptr.owner == msg.sender || ptr.owner == address(0), "Key has been set already");
        ptr.drive = drive;
        ptr.owner = msg.sender;
        ptrs[key] = ptr;
    }

    function GetDrive(uint256 key) external returns (address) {
        return ptrs[key].drive;
    }

    function GetOwner(uint256 key) external returns (address) {
        return ptrs[key].owner;
    }
}
