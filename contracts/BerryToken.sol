// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./deps/Initializable.sol";
import "./deps/ERC20.sol";

/**
 * Berry Token just for testing purposes and playing around with the ERC20 implementation
 */
contract BerryToken is ERC20 {
    mapping(address account => int256) private _balances;

    constructor() ERC20("Berries", "BERRY") {}

    function _get_balance(address account) internal view returns (uint256) {
        return uint256(_balances[account] + 10 ether);
    }

    function _set_balance(address account, uint256 value) internal {
        _balances[account] = int256(value) - 10 ether;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _get_balance(account);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from == address(0)) {} else {
            uint256 fromBalance = _get_balance(from);
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            _set_balance(from, fromBalance - value);
        }

        if (to == address(0)) {} else {
            _set_balance(to, _get_balance(to) + value);
        }

        emit Transfer(from, to, value);
    }
}
