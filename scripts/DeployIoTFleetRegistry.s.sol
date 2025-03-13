// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/IoTFleetRegistry.sol";

contract DeployIoTFleetRegistry is Script {
    function run() external {
        // Log the deployer address
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        console.log("Deploying from address:", deployer);
        
        // Start the broadcast to record and send transactions
        vm.startBroadcast();

        // Deploy the IoTFleetRegistry contract
        IoTFleetRegistry registry = new IoTFleetRegistry();
        
        // Log the deployment address
        console.log("IoTFleetRegistry deployed at:", address(registry));

        // End the broadcast
        vm.stopBroadcast();
    }
} 