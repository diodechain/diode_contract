// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/Bridge.sol";
import "../contracts/DiodeToken.sol";
import "../contracts/deps/Utils.sol";
import "../contracts/YieldVault.sol";
import "../contracts/TokenVesting.sol";
import "./forge-std/Test.sol";

/**
 * This test runs within the same chain (anvil) and thus simulates
 *     both sides Diode L1 and Moonbeam using the DiodeToken and the native token 
 *     respectively.
 *
 *     This bridge tests is testing to bridge in/out from the same chain,
 *     this is not a real use case but it is useful for testing the bridge.
 */
contract BridgeTest is Test {
    Bridge bridge;
    DiodeToken token;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address charlie;
    uint256 charlieKey;
    address dana;
    uint256 danaKey;

    constructor() {
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        (charlie, charlieKey) = makeAddrAndKey("charlie");
        (dana, danaKey) = makeAddrAndKey("dana");

        address[] memory validators = new address[](3);
        validators[0] = alice;
        validators[1] = bob;
        validators[2] = charlie;
        bridge = new Bridge(address(this), validators, 2);
        token = bridge.diode();
        bridge.setEnabledChain(block.chainid, true);
    }

    function testBridgeOut() public {
        address destination = makeAddr("edward");
        assertEq(address(token), address(bridge.burnable()));

        uint256 amount = 10000000000000000;
        token.mint(address(this), amount);
        assertEq(token.balanceOf(address(this)), amount, "balance=amount");
        assertEq(bridge.txsLength(block.chainid), 0, "txsLength=0");
        token.approve(address(bridge), amount);
        bridge.bridgeOut(destination, block.chainid, amount);
        assertEq(bridge.txsLength(block.chainid), 1, "txsLength=1");
        bytes32 hashv = bridge.txsAt(block.chainid, 0).historyHash;

        BridgeIn.InTransactionMsg[] memory msgs = new BridgeIn.InTransactionMsg[](1);
        msgs[0] = BridgeIn.InTransactionMsg({destination: destination, amount: amount});

        assertEq(bridge.hashTransactions(block.chainid, msgs), hashv, "hashv=hashTxs()");

        // Alice is an approved validator and her signature should increase score
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, hashv);
        bridge.addInWitness(hashv, v, r, s);
        assertEq(bridge.trustScore(hashv), 1, "trustScore=1");

        // Dana is no approved validator and her signature should not increase score
        (v, r, s) = vm.sign(danaKey, hashv);
        bridge.addInWitness(hashv, v, r, s);
        assertEq(bridge.trustScore(hashv), 1, "trustScore=1");

        // Bob is an approved validator and his signature should increase score
        (v, r, s) = vm.sign(bobKey, hashv);
        bridge.addInWitness(hashv, v, r, s);
        assertEq(bridge.trustScore(hashv), 2, "trustScore=2");

        assertEq(token.balanceOf(address(this)), 0, "balance=0");
        bridge.bridgeIn(block.chainid, msgs);
        assertEq(token.balanceOf(destination), amount, "balance=amount");
    }

    function testBridgeOutWithVault() public {
        address vault = address(new YieldVault(address(token), 1000, 1000, 1000));
        bridge.setVault(vault);
        token.setTransferAllowlist(vault, true);
        token.mint(vault, 10000000000000000);

        address destination = makeAddr("edward");
        assertEq(address(token), address(bridge.burnable()));

        uint256 amount = 10000000000000000;
        token.mint(address(this), amount);
        assertEq(token.balanceOf(address(this)), amount, "balance=amount");
        assertEq(bridge.txsLength(block.chainid), 0, "txsLength=0");
        token.approve(address(bridge), amount);
        bridge.bridgeOut(destination, block.chainid, amount);
        assertEq(bridge.txsLength(block.chainid), 1, "txsLength=1");
        bytes32 hashv = bridge.txsAt(block.chainid, 0).historyHash;

        BridgeIn.InTransactionMsg[] memory msgs = new BridgeIn.InTransactionMsg[](1);
        msgs[0] = BridgeIn.InTransactionMsg({
            destination: destination,
            amount: amount
        });

        assertEq(bridge.hashTransactions(block.chainid, msgs), hashv, "hashv=hashTxs()");

        // Alice is an approved validator and her signature should increase score
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, hashv);
        bridge.addInWitness(hashv, v, r, s);
        assertEq(bridge.trustScore(hashv), 1, "trustScore=1");

        // Dana is no approved validator and her signature should not increase score
        (v, r, s) = vm.sign(danaKey, hashv);
        bridge.addInWitness(hashv, v, r, s);
        assertEq(bridge.trustScore(hashv), 1, "trustScore=1");

        // Bob is an approved validator and his signature should increase score
        (v, r, s) = vm.sign(bobKey, hashv);
        bridge.addInWitness(hashv, v, r, s);
        assertEq(bridge.trustScore(hashv), 2, "trustScore=2");

        assertEq(token.balanceOf(address(this)), 0, "balance=0");
        bridge.bridgeIn(block.chainid, msgs);
        assertEq(token.balanceOf(destination), 0, "balance=0");

        address[] memory vestingContracts = YieldVault(vault).getUserVestingContracts(destination);
        assertEq(vestingContracts.length, 1, "vestingContracts.length=1");
        assertEq(token.balanceOf(vestingContracts[0]), amount + (amount/10), "balance=amount+yield");
        assertEq(TokenVesting(vestingContracts[0]).beneficiary(), destination, "beneficiary=destination");
    }
}
