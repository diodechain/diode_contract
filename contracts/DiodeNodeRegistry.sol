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

/**
 * DiodeNodeRegistry
 *
 * Registry for Diode Nodes which stake tokens.
 *
 */
contract DiodeNodeRegistry is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Set for Set.Data;

    address public immutable Foundation;
    IERC20 public immutable Token;
    uint256 public minimumStake;

    struct Node {
        address accountant;
        address nodeAddress;
        uint256 stake;
    }

    mapping(address => Node) public nodes;
    Set.Data nodesSet;

    constructor(address _foundation, address _token) initializer {
        Foundation = _foundation;
        Token = IERC20(_token);
    }

    function initialize() public initializer {
        require(msg.sender == Foundation, "Only the foundation can initialize");
        minimumStake = 0 ether;
    }

    function registerNode(address _nodeAddress, address _accountant, uint256 _stake) public {
        require(msg.sender == _nodeAddress, "Only the node itself can register");

        Node storage node = nodes[_nodeAddress];
        require(_stake + node.stake >= minimumStake, "Node must have at least minimum stake");

        if (_stake > 0) {
            Token.safeTransferFrom(msg.sender, address(this), _stake);
            node.stake = node.stake.add(_stake);
        }

        node.accountant = _accountant;
        node.nodeAddress = _nodeAddress;
        nodesSet.Add(_nodeAddress);
    }

    function unstakeNode(address _nodeAddress) public {
        require(msg.sender == _nodeAddress || msg.sender == nodes[_nodeAddress].accountant, "Only the node itself or its accountant can unstake");

        Node storage node = nodes[_nodeAddress];
        require(node.stake > 0, "Node must have a stake");
        require(node.accountant != address(0), "Node must have an accountant");

        Token.safeTransfer(node.accountant, node.stake);
        node.stake = 0;
        node.accountant = address(0);
        node.nodeAddress = address(0);
        nodesSet.Remove(_nodeAddress);
    }

    function getNodes() public view returns (address[] memory) {
        return nodesSet.Members();
    }

    function version() public pure returns (uint256) {
        return 101;
    }
}
