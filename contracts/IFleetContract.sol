// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity >=0.7.6;

/**
 * IFleetContract
 * This interface is used to interact with the FleetContractLight.
 */
interface IFleetContract {
    function Accountant() external view returns (address);
    function DeviceAllowlist(address _client) external view returns (bool);
    /// @notice Deprecated alias for DeviceAllowlist.
    function deviceWhitelist(address _client) external view returns (bool);
}

/**
 * IConsoleFleetContract
 * This interface is used to be managed by the console.
 */
interface IConsoleFleetContract is IFleetContract {
    function SetDeviceAllowlist(address _client, bool _value) external;
    function AddDeviceBatch(address[] memory _clients) external;
    function RemoveDeviceBatch(address[] memory _clients) external;
    function GetDeviceCount() external view returns (uint256);
    function GetDeviceList(uint256 offset, uint256 limit) external view returns (address[] memory);
}
