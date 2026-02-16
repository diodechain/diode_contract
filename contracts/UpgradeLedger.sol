// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./ChangeTracker.sol";
import "./deps/OwnableInitializable.sol";
import "./deps/IERC20.sol";

/**
 * Simple ledger to record upgrade payments
 */
contract UpgradeLedger is ChangeTracker, OwnableInitializable {
    struct Payment {
        address sender;
        uint256 amount;
        uint256 timestamp;
        string reason;
    }

    address public TOKEN;
    mapping(address => Payment[]) public payments;

    constructor(address _owner, address token) {
        TOKEN = token;
        initialize(payable(_owner));
    }

    function RecordPayment(uint256 _amount, string memory _reason) public {
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(TOKEN).transferFrom(msg.sender, address(this), _amount);
        payments[msg.sender].push(Payment(msg.sender, _amount, block.timestamp, _reason));
        update_change_tracker();
    }

    function GetPayments(address _sender) public view returns (Payment[] memory) {
        return payments[_sender];
    }

    function Withdraw(uint256 _amount, address _recipient) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_recipient != address(0), "Recipient cannot be the zero address");
        IERC20(TOKEN).transfer(_recipient, _amount);
    }

    function Version() public pure returns (int256) {
        return 100;
    }
}
