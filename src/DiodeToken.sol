// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
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
    mapping(address => bool) transferAllowlist;

    constructor(
        address _foundation,
        address _bridge,
        bool _transferable
    ) ERC20("Diode", "DIODE") {
        foundation = _foundation;
        bridge = _bridge;
        transferable = _transferable;
    }

    function mint(address to, uint256 amount) public {
        require(
            msg.sender == foundation || msg.sender == bridge,
            "DiodeToken: minting not allowed"
        );
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(
            msg.sender == foundation || msg.sender == bridge,
            "DiodeToken: burning not allowed"
        );
        _burn(from, amount);
    }

    function setTransferable(bool _transferable) public {
        require(
            msg.sender == foundation,
            "DiodeToken: only foundation can set transferable"
        );
        transferable = _transferable;
    }

    function setTransferAllowlist(address account, bool allow) public {
        require(
            msg.sender == foundation,
            "DiodeToken: only foundation can set transfer allowlist"
        );
        transferAllowlist[account] = allow;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(
            transferable ||
                transferAllowlist[sender] ||
                transferAllowlist[recipient],
            "DiodeToken: transfer not allowed"
        );
        return super._transfer(sender, recipient, amount);
    }
}
