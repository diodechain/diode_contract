// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

/**
 * BridgeOutNative contract
 */
contract BridgeOutNative {
    struct Transaction {
        address sender;
        address destination;
        uint256 amount;
        uint256 timestamp;
        uint256 blockNumber;
        bytes32 historyHash;
    }

    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // This should always match block.chainid
    // but for testing it makes sense to override this
    uint256 public immutable chainid;
    constructor(uint256 _chainid) {
        chainid = _chainid;
    }

    mapping(uint256 => Transaction[]) public txs;
    mapping(bytes32 => mapping(address => Sig)) public witnesses;

    function txsLength(uint256 chain) public view returns (uint256) {
        return txs[chain].length;
    }

    function txsAt(
        uint256 chain,
        uint256 index
    ) public view returns (Transaction memory) {
        return txs[chain][index];
    }

    function bridgeOut(
        address destination,
        uint256 destinationChain
    ) public payable {
        _bridgeOut(destination, destinationChain);
    }

    function bridgeOut(address destination) public payable {
        _bridgeOut(destination, 1284);
    }

    function bridgeOut() public payable {
        _bridgeOut(msg.sender, 1284);
    }

    function _bridgeOut(
        address destination,
        uint256 destinationChain
    ) internal {
        require(
            msg.value >= 10000000000000000,
            "BridgeOut: value must be at least 0.01 $DIODE"
        );
        uint256 len = txs[destinationChain].length;
        bytes32 prev = len == 0
            ? keccak256(
                abi.encodePacked(
                    chainid,
                    "diode_bridge_genesis",
                    destinationChain
                )
            )
            : txs[destinationChain][len - 1].historyHash;
        bytes32 historyHash = keccak256(
            abi.encodePacked(destination, destinationChain, msg.value, prev)
        );
        txs[destinationChain].push(
            Transaction({
                sender: msg.sender,
                destination: destination,
                amount: msg.value,
                timestamp: block.timestamp,
                blockNumber: block.number,
                historyHash: historyHash
            })
        );
    }

    function addWitness(bytes32 hashv, uint8 v, bytes32 r, bytes32 s) public {
        address sender = ecrecover(hashv, v, r, s);
        witnesses[hashv][sender] = Sig({v: v, r: r, s: s});
    }
}
