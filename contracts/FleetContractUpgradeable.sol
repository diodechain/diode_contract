// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity >=0.7.6;

import "./IFleetContract.sol";
import "./deps/Set.sol";

/**
 * FleetContract
 */
contract FleetContractUpgradeable is IConsoleFleetContract {
    using Set for Set.Data;

    address private _reserved_0;
    address public operator;
    address payable public accountant;
    uint256 private _reserved_1;
    bytes32 private _reserved_2;
    bytes32 private _reserved_3;
    mapping(address => bool) private allowlist;
    mapping(address => mapping(address => bool)) private _reserved_4;
    address private immutable REGISTRY;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Enumerable allowlist: insertion order for GetDeviceList pagination.
     * @dev Appended after existing storage for upgrade-safe layout.
     * @dev Entries added before this enumeration existed are only visible via DeviceAllowlist until set again via operator APIs.
     */
    Set.Data private _allowlistSet;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only the operator can call this method");
        _;
    }

    modifier onlyAccountant() {
        require(msg.sender == accountant, "Only the accountant can call this method");
        _;
    }

    constructor(address _registry) initializer {
        REGISTRY = _registry;
        initialized = true;
    }

    function initialize(address payable _owner) public virtual initializer {
        operator = _owner;
        accountant = _owner;
    }

    function initialize(address _operator, address payable _accountant) public virtual initializer {
        operator = _operator;
        accountant = _accountant;
    }

    function Accountant() external view override returns (address) {
        return accountant;
    }

    function Operator() external view returns (address) {
        return operator;
    }

    function transferOperator(address payable _newOperator) public virtual onlyOperator {
        require(_newOperator != address(0), "New operator cannot be zero address");
        operator = _newOperator;
        accountant = _newOperator;
    }

    function SetDeviceAllowlist(address _client, bool _value) public virtual onlyOperator {
        if (_value) {
            _addAllowlisted(_client);
        } else {
            _removeAllowlisted(_client);
        }
    }

    function _addAllowlisted(address _client) internal {
        if (allowlist[_client]) {
            return;
        }
        allowlist[_client] = true;
        _allowlistSet.Add(_client);
    }

    function _removeAllowlisted(address _client) internal {
        if (!allowlist[_client]) {
            return;
        }
        allowlist[_client] = false;
        _allowlistSet.Remove(_client);
    }

    function DeviceAllowlist(address _client) public view override returns (bool) {
        return allowlist[_client];
    }

    function Version() external pure virtual returns (uint256) {
        return 400;
    }

    function AddDeviceBatch(address[] memory _clients) external onlyOperator {
        for (uint256 i = 0; i < _clients.length; i++) {
            _addAllowlisted(_clients[i]);
        }
    }

    function RemoveDeviceBatch(address[] memory _clients) external onlyOperator {
        for (uint256 i = 0; i < _clients.length; i++) {
            _removeAllowlisted(_clients[i]);
        }
    }

    function GetDeviceCount() external view returns (uint256) {
        return _allowlistSet.Size();
    }

    function GetDeviceList(uint256 offset, uint256 limit) external view returns (address[] memory) {
        return _allowlistSet.Slice(offset, limit);
    }

    /**
     *
     *   DEPRECATED FUNCTIONS    **
     *
     */
    function SetDeviceWhitelist(address _client, bool _value) external {
        SetDeviceAllowlist(_client, _value);
    }

    function deviceWhitelist(address _client) external view override returns (bool) {
        return DeviceAllowlist(_client);
    }
}
