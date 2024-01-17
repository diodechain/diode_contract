// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./Group.sol";

/**
 * DriveMember and Identity Smart Contract
 *  
 * When used as a DriveMember the `drive` member variable should point to the address of the drive "zone"
 * that this contract is a member of.
 *
 * When used as Identity the `drive` member variable will be `0`.
 *
 * The "owner" will always be the initial "master key". The contract is being deployed using the DriveFactory.sol
 * and thus upgradeable by the `owner()` only. 
 *
 * "additional_drives" is temporary to store multiple Zones all used with this same identity. Will be replaced
 * once the client can handle multiple identity connections.
 *
 * TODO:
 * Implement fallback recovery options, such as social recovery or a PIN/PUK style cold storage backup master to
 * recover from cases when the "master key" got stolen.
 */
contract DriveMember is Group {
    bool protected;
    address drive;
    address[] additional_drives;

    modifier onlyMember override {
        if (protected) {
            require(owner() == msg.sender, "Only the owner can call this in protected mode");
        } else {
            require(owner() == msg.sender || members.isMember(msg.sender), "Only members can call this");
        }

        _;
    }

    constructor() public {
        initialize(msg.sender);
    }

    function Version() external virtual pure returns (int256) {
        return 112;
    }

    function Protect(bool _protect) external onlyMember {
        protected = _protect;
    }

    function AddMember(address _member) external onlyMember {
        members.add(_member);
    }

    function RemoveMember(address _member) external onlyMember {
        members.remove(_member);
    }

    function Destroy() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function Drive() public view returns (address) {
        return drive;
    }

    function SetDrive(address _drive) external onlyMember {
        drive = _drive;
    }

    function AddDrive(address _drive) external onlyMember {
        for (uint32 i = 0; i < additional_drives.length; i++) {
            if (additional_drives[i] == _drive) return;
        }
        additional_drives.push(_drive);
    }

    function Drives() external view returns (address[] memory) {
        return additional_drives;
    }

    function SubmitTransaction(address dst, bytes memory data) public onlyMember
    {
        require(external_call(dst, data.length, data), "General Transaction failed");
    }

    function SubmitDriveTransaction(bytes memory data) public onlyMember
    {
        require(external_call(drive, data.length, data), "Drive Transaction failed");
    }
}
