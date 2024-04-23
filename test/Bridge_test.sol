// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BridgeOutNative.sol";
import "../contracts/BridgeIn.sol";
import "../contracts/DiodeToken.sol";
import "../contracts/deps/Utils.sol";

import "./forge-std/Test.sol";

/**
    This test runs within the same chain (anvil) and thus simulates
    both sides Diode L1 and Moonbeam using the DiodeToken and the native token 
    respectively.
 */

contract BridgeTest is Test {
    BridgeOutNative l1BridgeOut;
    BridgeIn moonBridgeIn;
    DiodeToken moonDiode;

    constructor() {
        address[] memory validators = new address[](1);
        validators[0] = address(0);
        moonBridgeIn = new BridgeIn(address(0), validators, 1);
        l1BridgeOut = new BridgeOutNative();
        moonDiode = moonBridgeIn.diode();
    }
}
