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

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address charlie;
    uint256 charlieKey;
    address dana;
    uint256 danaKey;

    uint256 moon = 1284;

    constructor() {
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        (charlie, charlieKey) = makeAddrAndKey("charlie");
        (dana, danaKey) = makeAddrAndKey("dana");

        address[] memory validators = new address[](3);
        validators[0] = alice;
        validators[1] = bob;
        validators[2] = charlie;
        moonBridgeIn = new BridgeIn(address(0), validators, 2);
        l1BridgeOut = new BridgeOutNative(moon);
        moonDiode = moonBridgeIn.diode();
    }

    function testBridgeOut() public {
        uint256 amount = 10000000000000000;

        assertEq(l1BridgeOut.txsLength(moon), 0, "txsLength=0");
        l1BridgeOut.bridgeOut{value: amount}();
        assertEq(l1BridgeOut.txsLength(moon), 1, "txsLength=1");
        bytes32 hashv = l1BridgeOut.txsAt(moon, 0).historyHash;

        BridgeIn.InTransactionMsg[] memory msgs = new BridgeIn.InTransactionMsg[](1);
        msgs[0] = BridgeIn.InTransactionMsg({
            destination: address(this),
            amount: amount
        });

        // Alice is an approved validator and her signature should increase score
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, hashv);
        moonBridgeIn.addInWitness(hashv, v, r, s);
        assertEq(moonBridgeIn.trustScore(hashv), 1, "trustScore=1");
        assertEq(moonBridgeIn.hashTransactions(block.chainid, msgs), hashv, "hashv=hashTxs()");

        // Dana is no approved validator and her should not increase score
        (v, r, s) = vm.sign(danaKey, hashv);
        moonBridgeIn.addInWitness(hashv, v, r, s);
        assertEq(moonBridgeIn.trustScore(hashv), 1, "trustScore=1");

        // Bob is an approved validator and his signature should increase score
        (v, r, s) = vm.sign(bobKey, hashv);
        moonBridgeIn.addInWitness(hashv, v, r, s);
        assertEq(moonBridgeIn.trustScore(hashv), 2, "trustScore=2");

        assertEq(moonDiode.balanceOf(address(this)), 0, "balance=0");
        moonBridgeIn.bridgeIn(block.chainid, msgs);
        assertEq(moonDiode.balanceOf(address(this)), amount, "balance=amount");
    }
}
