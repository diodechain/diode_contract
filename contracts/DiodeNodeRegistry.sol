// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2025 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./deps/IERC20.sol";
import "./deps/SafeERC20.sol";
import "./deps/Utils.sol";
import "./deps/SafeMath.sol";
import "./deps/Initializable.sol";
import "./deps/Set.sol";
import "./ChangeTracker.sol";

/**
 * DiodeNodeRegistry
 *
 * Registry for Diode Nodes which stake tokens.
 *
 */
contract DiodeNodeRegistry is Initializable, ChangeTracker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Set for Set.Data;

    address public immutable FOUNDATION;
    IERC20 public immutable TOKEN;
    uint256 public minimumStake;

    struct Node {
        address accountant;
        address nodeAddress;
        uint256 stake;
    }

    mapping(address => Node) public nodes;
    Set.Data nodesSet;

    constructor(address _foundation, address _token) initializer {
        FOUNDATION = _foundation;
        TOKEN = IERC20(_token);
    }

    function initialize() public initializer {
        require(msg.sender == FOUNDATION, "Only the foundation can initialize");
        minimumStake = 0 ether;
    }

    function initialize_change_tracker() public {
        require(change_tracker() == 0, "Change tracker already initialized");
        update_change_tracker();
    }

    function registerNode(address _nodeAddress, address _accountant, uint256 _stake) public {
        require(msg.sender == _nodeAddress, "Only the node itself can register");

        Node storage node = nodes[_nodeAddress];
        require(_stake + node.stake >= minimumStake, "Node must have at least minimum stake");

        if (_stake > 0) {
            TOKEN.safeTransferFrom(msg.sender, address(this), _stake);
            node.stake = node.stake.add(_stake);
        }

        node.accountant = _accountant;
        node.nodeAddress = _nodeAddress;
        nodesSet.Add(_nodeAddress);
        update_change_tracker();
    }

    function unstakeNode(address _nodeAddress) public {
        require(
            msg.sender == _nodeAddress || msg.sender == nodes[_nodeAddress].accountant,
            "Only the node itself or its accountant can unstake"
        );

        Node storage node = nodes[_nodeAddress];
        require(node.stake > 0, "Node must have a stake");
        require(node.accountant != address(0), "Node must have an accountant");

        TOKEN.safeTransfer(node.accountant, node.stake);
        node.stake = 0;
        update_change_tracker();
    }

    function getNodes() public view returns (address[] memory) {
        return nodesSet.Members();
    }

    function getNodesAbove(uint256 stake) public view returns (address[] memory) {
        address[] memory allNodes = nodesSet.Members();
        address[] memory nodesAboveStake = new address[](allNodes.length);
        uint256 index = 0;
        for (uint256 i = 0; i < allNodes.length; i++) {
            address node = allNodes[i];
            if (nodes[node].stake >= stake) {
                nodesAboveStake[index] = node;
                index++;
            }
        }

        // Use inline assembly to resize the array to only return filled elements
        assembly {
            mstore(nodesAboveStake, index)
        }

        return nodesAboveStake;
    }

    function version() public pure returns (uint256) {
        return 104;
    }
}
