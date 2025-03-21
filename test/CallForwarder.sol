// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity >=0.7.6;

contract CallForwarder {
    address target;

    constructor(address _target) {
        target = _target;
    }

    function __updateTarget(address _target) public {
        target = _target;
    }

    fallback() external payable {
        address t = target;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := call(gas(), t, 0, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 { revert(0, 0) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {
        address t = target;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := call(gas(), t, callvalue(), 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 { revert(0, 0) }
            default { return(0, returndatasize()) }
        }
    }
}
