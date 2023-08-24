// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;
import "./deps/OwnableInitializable.sol";

/**
 * FleetContract
 */
contract FleetContract is OwnableInitializable {
    address public operator;
    address payable public accountant;
    uint256 private _reserved_1;
    bytes32 private _reserved_2;
    bytes32 private _reserved_3;
    mapping(address => bool) private allowlist;
    mapping(address => mapping(address => bool)) private _reserved_4;

    modifier onlyOperator() {
        require(
            msg.sender == operator,
            "Only the operator can call this method"
        );
        _;
    }

    modifier onlyAccountant() {
        require(
            msg.sender == accountant,
            "Only the accountant can call this method"
        );
        _;
    }

    constructor() public {
        initialize(0, msg.sender, msg.sender);
    }

    bytes32 salt;
    address target;
    address owner;

    function initialize(
        bytes32 _salt,
        address _target,
        address payable _owner
    ) public initializer {
        salt = _salt;
        target = _target;
        owner = _owner;
    }

    function Accountant() external view returns (address payable) {
        return accountant;
    }

    function Operator() external view returns (address) {
        return operator;
    }

    function SetDeviceAllowlist(address _client, bool _value)
        public
        virtual
        onlyOperator
    {
        allowlist[_client] = _value;
    }

    function DeviceAllowlist(address _client)
        public
        view
        virtual
        returns (bool)
    {
        return allowlist[_client];
    }
}
