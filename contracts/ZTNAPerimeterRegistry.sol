// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "./Proxy8.sol";
import "./deps/Set.sol";
import "./ZTNAPerimeterContract.sol";

interface InitializableFleet {
    function initialize(address payable _owner, string memory _label) external;
}

// Per user Fleet Registry used for Tracking user fleets in the Fleet ManagementUser Interface
contract ZTNAPerimeterRegistry {
    bytes32 internal constant OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    using Set for Set.Data;

    struct FleetMetadata {
        address owner;
        address fleet;
        uint256 createdAt;
        uint256 updatedAt;
        Set.Data users;
    }

    // External version of FleetMetadata without mappings
    struct FleetMetadataView {
        address owner;
        address fleet;
        uint256 createdAt;
        uint256 updatedAt;
    }

    // All fleet metadata
    mapping(address => FleetMetadata) fleets;

    // Users own fleets
    mapping(address => address[]) userFleets;

    // Shared Users: Receiver User => Sender User
    mapping(address => Set.Data) users;

    // Shared Fleets: Sender User => Receiver User => Fleet Address
    mapping(address => mapping(address => Set.Data)) sharedFleets;

    // Default Fleet Implementation
    address public defaultFleetImplementation;

    constructor() {
        defaultFleetImplementation = address(new ZTNAPerimeterContract());
    }

    function SetDefaultFleetImplementation(address _defaultFleetImplementation) external {
        require(msg.sender == Owner(), "You do not have permission to set the default fleet implementation");
        defaultFleetImplementation = _defaultFleetImplementation;
    }

    function Owner() public view returns (address) {
        address owner;
        assembly {owner := sload(OWNER_SLOT)}
        return owner;
    }

    function Version() external pure returns (uint256) {
        return 100;
    }
    
    // Add a fleet to the registry
    function CreateFleet(string memory label) external {
        address fleet = address(new Proxy8(defaultFleetImplementation, msg.sender));
        InitializableFleet(fleet).initialize(payable(msg.sender), label);
        
        // Initialize struct fields individually instead of using struct constructor
        fleets[fleet].owner = msg.sender;
        fleets[fleet].fleet = fleet;
        fleets[fleet].createdAt = block.timestamp;
        fleets[fleet].updatedAt = block.timestamp;
        // Note: users Set.Data will be initialized to its default empty state
        
        userFleets[msg.sender].push(fleet);
    }

    // For backward compatibility - creates a fleet with an empty label
    function CreateFleet() external {
        address fleet = address(new Proxy8(defaultFleetImplementation, msg.sender));
        InitializableFleet(fleet).initialize(payable(msg.sender), "");
        
        // Initialize struct fields individually instead of using struct constructor
        fleets[fleet].owner = msg.sender;
        fleets[fleet].fleet = fleet;
        fleets[fleet].createdAt = block.timestamp;
        fleets[fleet].updatedAt = block.timestamp;
        // Note: users Set.Data will be initialized to its default empty state
        
        userFleets[msg.sender].push(fleet);
    }

    function AddFleetUser(address fleet, address user) external {
        require(fleets[fleet].owner == msg.sender, "You do not own this fleet");
        Set.Add(fleets[fleet].users, user);
        fleets[fleet].updatedAt = block.timestamp;
        Set.Add(users[user], msg.sender);
        Set.Add(sharedFleets[msg.sender][user], fleet);
    }

    function RemoveFleetUser(address fleet, address user) external {
        require(fleets[fleet].owner == msg.sender, "You do not own this fleet");
        Set.Remove(fleets[fleet].users, user);
        fleets[fleet].updatedAt = block.timestamp;
        Set.Remove(sharedFleets[msg.sender][user], fleet);
    }

    // Get the fleets for a user
    function GetOwnFleetCount() external view returns (uint256) {
        return userFleets[msg.sender].length;
    }

    // Convert internal FleetMetadata to external FleetMetadataView
    function _toFleetMetadataView(FleetMetadata storage metadata) internal view returns (FleetMetadataView memory) {
        return FleetMetadataView({
            owner: metadata.owner,
            fleet: metadata.fleet,
            createdAt: metadata.createdAt,
            updatedAt: metadata.updatedAt
        });
    }

    // Get the fleets for a user
    function GetOwnFleet(uint256 fleetIndex) external view returns (FleetMetadataView memory) {
        return _toFleetMetadataView(fleets[userFleets[msg.sender][fleetIndex]]);
    }

    function GetFleetUserCount(address fleet) external view returns (uint256) {
        require(fleets[fleet].owner == msg.sender || Set.IsMember(fleets[fleet].users, msg.sender), "You do not own this fleet");
        return Set.Size(fleets[fleet].users);
    }

    function GetFleetUser(address fleet, uint256 userIndex) external view returns (address) {
        require(fleets[fleet].owner == msg.sender || Set.IsMember(fleets[fleet].users, msg.sender), "You do not own this fleet");
        return fleets[fleet].users.items[userIndex];
    }

    function GetFleet(address fleet) external view returns (FleetMetadataView memory) {
        require(fleets[fleet].owner == msg.sender || Set.IsMember(fleets[fleet].users, msg.sender), "You do not own this fleet");
        return _toFleetMetadataView(fleets[fleet]);
    }

    // Get users who are sharing a fleet
    function GetSharingUserCount() external view returns (uint256) {
        return Set.Size(users[msg.sender]);
    }

    function GetSharingUser(uint256 index) external view returns (address) {
        return users[msg.sender].items[index];
    }

    function GetSharedFleetCount(address sender) external view returns (uint256) {
        return Set.Size(sharedFleets[sender][msg.sender]);
    }

    function GetSharedFleet(address sender, uint256 fleetIndex) external view returns (FleetMetadataView memory) {
        return _toFleetMetadataView(fleets[sharedFleets[sender][msg.sender].items[fleetIndex]]);
    }
}