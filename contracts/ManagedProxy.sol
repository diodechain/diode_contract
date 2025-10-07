// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity >=0.7.6;

import "./IProxyResolver.sol";

contract ManagedProxy {
    bytes32 immutable REF;
    IProxyResolver immutable RESOLVER;

    constructor(IProxyResolver _resolver, bytes32 _ref) {
        REF = _ref;
        RESOLVER = _resolver;
    }

    fallback() external payable {
        address target = RESOLVER.resolve(REF);
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 { revert(0, 0) }
            default { return(0, returndatasize()) }
        }
    }
}
