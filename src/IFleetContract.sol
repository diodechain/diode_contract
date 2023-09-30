// Diode Contracts
// Copyright 2023 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;
import "./DiodeRegistry.sol";

/**
 * IFleetContract
 */
interface IFleetContract {
    function Accountant() external view returns (address payable);
    function deviceWhitelist(address _client) external view returns (bool);
}
