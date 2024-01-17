// Diode Contracts
// Copyright 2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;

interface IProxyResolver {
    function resolve(bytes32 ref) external view returns (address);
}