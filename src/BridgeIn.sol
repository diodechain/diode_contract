// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./DiodeToken.sol";

/**
 * BridgeIn contract
 * 
 * This contract is responsible for receiving transactions from other non-L1 chains.
 * Hence the BridgeIn always operates on a ERC20 Diode Token. The token is spawned
 * as part of the initial bridge deployment.
 */
contract BridgeIn {
    struct InTransaction {
        address destination;
        uint256 amount;
        bytes32 historyHash;
        uint256 timestamp;
        uint256 blockNumber;
    }

    struct InTransactionMsg {
        address destination;
        uint256 amount;
    }

    struct InSig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    mapping(uint256 => InTransaction[]) public in_txs;
    mapping(bytes32 => mapping(address => InSig)) public in_witnesses;
    address[] public in_validators;
    uint256 public in_threshold;
    DiodeToken public immutable diode;
    address public immutable foundation;

    constructor(
        address _foundation,
        address[] memory _validators,
        uint256 _threshold
    ) {
        in_validators = _validators;
        in_threshold = _threshold;
        diode = new DiodeToken(_foundation, address(this), false);
        foundation = _foundation;
    }

    function inTxsLength(uint256 chain) public view returns (uint256) {
        return in_txs[chain].length;
    }

    function txsAt(
        uint256 chain,
        uint256 index
    ) public view returns (InTransaction memory) {
        return in_txs[chain][index];
    }

    function setValidators(address[] memory _validators) public {
        require(
            msg.sender == foundation,
            "BridgeIn: only foundation can set validators"
        );
        in_validators = _validators;
    }

    function setThreshold(uint256 _threshold) public {
        require(
            msg.sender == foundation,
            "BridgeIn: only foundation can set threshold"
        );
        require(_threshold > 0, "BridgeIn: threshold must be larger than 0");
        in_threshold = _threshold;
    }

    function bridgeIn(
        uint256 sourceChain,
        InTransactionMsg[] memory msgs
    ) public {
        require(
            msgs.length >= 0,
            "BridgeOut: there must be at least one transaction"
        );

        bytes32 historyHash;

        for (uint256 i = 0; i < msgs.length; i++) {
            uint256 len = in_txs[sourceChain].length;
            bytes32 prev = len == 0
                ? keccak256(
                    abi.encodePacked(
                        sourceChain,
                        "diode_bridge_genesis",
                        block.chainid
                    )
                )
                : in_txs[sourceChain][len - 1].historyHash;

            historyHash = keccak256(
                abi.encodePacked(msgs[i].destination, msgs[i].amount, prev)
            );
            in_txs[sourceChain].push(
                InTransaction({
                    destination: msgs[i].destination,
                    amount: msgs[i].amount,
                    historyHash: historyHash,
                    timestamp: block.timestamp,
                    blockNumber: block.number
                })
            );
            diode.mint(address(this), msgs[i].amount);
            diode.transfer(msgs[i].destination, msgs[i].amount);
        }

        uint256 _trustScore = calcTrustScore(historyHash);
        require(
            _trustScore >= in_threshold,
            "BridgeOut: trust score must reach at least threshold"
        );
    }

    function trustScore(
        uint256 sourceChain,
        InTransactionMsg[] memory msgs
    ) public view returns (uint256) {
        uint256 len = in_txs[sourceChain].length;
        bytes32 tmpHistoryHash = len == 0
            ? keccak256(
                abi.encodePacked(
                    sourceChain,
                    "diode_bridge_genesis",
                    block.chainid
                )
            )
            : in_txs[sourceChain][len - 1].historyHash;

        for (uint256 i = 0; i < msgs.length; i++) {
            tmpHistoryHash = keccak256(
                abi.encodePacked(
                    msgs[i].destination,
                    msgs[i].amount,
                    tmpHistoryHash
                )
            );
        }

        return calcTrustScore(tmpHistoryHash);
    }

    function trustScore(bytes32 tmpHistoryHash) public view returns (uint256) {
        return calcTrustScore(tmpHistoryHash);
    }

    function calcTrustScore(bytes32 hashv) internal view returns (uint256) {
        uint256 _trustScore = 0;
        for (uint256 i = 0; i < in_validators.length; i++) {
            if (in_witnesses[hashv][in_validators[i]].v != 0) {
                _trustScore++;
            }
        }
        return _trustScore;
    }

    function addInWitness(bytes32 hashv, uint8 v, bytes32 r, bytes32 s) public {
        address destination = ecrecover(hashv, v, r, s);
        in_witnesses[hashv][destination] = InSig({r: r, s: s, v: v});
    }
}
