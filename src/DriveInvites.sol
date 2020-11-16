// Diode Contracts
// Copyright 2020 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./deps/Set.sol";
import "./IDrive.sol";

/**
 * Drive Smart Contract
 * On-Chain invites for asynchronous eventing
 */

contract DriveInvites {
    using Set for Set.Data;

    mapping(address => Set.Data) invites;

    // To be called by drive contract (msg.sender)
    function Invite(IDrive drive, address whom) public {
        require(drive.Role(msg.sender) >= RoleType.Admin, "Only Admins can invite");
        invites[whom].add(address(drive));
    }

    // To be called by drive contract (msg.sender)
    function Uninvite(IDrive drive, address whom) public {
        require(
            drive.Role(msg.sender) >= RoleType.Admin,
            "Only Admins can manage invites"
        );
        invites[whom].remove(address(drive));
    }

    // Called by the invitess to check (user)
    function Invites() public view returns (address[] memory) {
        return invites[msg.sender].members();
    }

    // Called by the invitess to remove an invite after use (user)
    function PopInvite(address invite) public {
        return invites[msg.sender].remove(invite);
    }
}
