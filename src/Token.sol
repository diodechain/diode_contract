// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./deps/ERC20.sol";

/**
 * Diode Token
 */
contract DiodeToken is ERC20 {
    address public foundation;
    address public bridge;
    bool public transferable = false;
    mapping (address=>bool) transferAllowlist;

    constructor(address _foundation, address _bridge) ERC20("Diode", "DIODE") {
        foundation = _foundation;
        bridge = _bridge;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == foundation || msg.sender == bridge, "DiodeToken: minting not allowed");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == foundation || msg.sender == bridge, "DiodeToken: burning not allowed");
        _burn(from, amount);
    }

    function setTransferable(bool _transferable) public {
        require(msg.sender == foundation, "DiodeToken: only foundation can set transferable");
        transferable = _transferable;
    }

    function setTransferAllowlist(address account, bool allow) public {
        require(msg.sender == foundation, "DiodeToken: only foundation can set transfer allowlist");
        transferAllowlist[account] = allow;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(transferable || transferAllowlist[msg.sender], "DiodeToken: transfer not allowed");
        return super.transfer(recipient, amount);
    }
}