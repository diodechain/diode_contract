// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;

/**
 * FleetContract
 */
interface FleetContractInterface {
  function Accountant() external view returns (address payable);
  function Operator() external view returns (address);
  function SetDeviceAllowlist(address _client, bool _value) external;
  function DeviceAllowlist(address _client) external view returns (bool);
}