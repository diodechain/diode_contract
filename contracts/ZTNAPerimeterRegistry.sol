// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "./ManagedProxy.sol";
import "./deps/Set.sol";
import "./ZTNAPerimeterContract.sol";
import "./ZTNAWallet.sol";
import "./ZTNAOrganisation.sol";

interface InitializableFleet {
    function initialize(address payable _owner, string memory _label) external;
}

interface InitializableUser {
    function initialize(address payable _owner) external;
}

interface InitializableOrganisation {
    function initialize(address payable _owner, string memory _name, string memory _description) external;
}

// Per user Fleet Registry used for Tracking user fleets in the Perimeter ManagementUser Interface
contract ZTNAPerimeterRegistry is IProxyResolver {
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
    mapping(address => FleetMetadata) private fleets;

    // Users own fleets
    mapping(address => address[]) private userFleets;

    // Shared Users: Receiver User => Sender User
    mapping(address => Set.Data) private users;

    // Shared Fleets: Sender User => Receiver User => Fleet Address
    mapping(address => mapping(address => Set.Data)) private sharedFleets;

    // Default Fleet Implementation
    address private _perimeterImplementationReserved;
    address private _userImplementationReserved;

    mapping(address => address) private userWallets;

    // Organisation tracking
    mapping(address => address[]) private userOrganisations;

    // Organisation membership tracking (user -> set of orgs)
    mapping(address => Set.Data) private adminOrganisations; // orgs where user is admin
    mapping(address => Set.Data) private memberOrganisations; // orgs where user is member

    // Track valid organisation addresses (to validate callbacks)
    mapping(address => bool) private validOrganisations;

    address private immutable perimeterImplementation;
    address private immutable userImplementation;
    address private immutable organisationImplementation;

    constructor() {
        perimeterImplementation = address(new ZTNAPerimeterContract());
        userImplementation = address(new ZTNAWallet());
        organisationImplementation = address(new ZTNAOrganisation(address(this)));
    }

    // function Validate() external view returns (string memory) {
    //     if (perimeterImplementation == address(0)) {
    //         return "Perimeter implementation not set";
    //     }
    //     if (userImplementation == address(0)) {
    //         return "User implementation not set";
    //     }
    //     return "Contract is valid";
    // }

    // function SetImplementation(bytes32 what, address implementation) external {
    //     require(msg.sender == Owner(), "You do not have permission to set the default fleet implementation");
    //     if (what == "ZTNAPerimeterRegistry") {
    //         perimeterImplementation = implementation;
    //     } else if (what == "ZTNAWallet") {
    //         userImplementation = implementation;
    //     }
    // }

    function resolve(bytes32 what) external view returns (address) {
        if (what == "ZTNAPerimeterRegistry") {
            return address(perimeterImplementation);
        } else if (what == "ZTNAWallet") {
            return address(userImplementation);
        } else if (what == "ZTNAOrganisation") {
            return address(organisationImplementation);
        }
        return address(0);
    }

    function Owner() public view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_SLOT)
        }
        return owner;
    }

    function CreateUserWallet() external returns (address) {
        address key = userWalletKey(msg.sender);
        address user = userWallets[key];
        if (user != address(0)) {
            return user;
        }

        user = address(new ManagedProxy(this, "ZTNAWallet"));
        InitializableUser(user).initialize(payable(msg.sender));
        userWallets[key] = user;
        return user;
    }

    function UserWallet(address user) external view returns (address) {
        return userWallets[userWalletKey(user)];
    }

    function userWalletKey(address user) internal pure returns (address) {
        return address(bytes20(keccak256(abi.encodePacked("userWallet2", user))));
    }

    // Add a fleet to the registry
    function CreateFleet(string memory label) public {
        address fleet = address(new ManagedProxy(this, "ZTNAPerimeterRegistry"));
        InitializableFleet(fleet).initialize(payable(msg.sender), label);

        // Initialize struct fields individually instead of using struct constructor
        fleets[fleet].owner = msg.sender;
        fleets[fleet].fleet = fleet;
        fleets[fleet].createdAt = block.timestamp;
        fleets[fleet].updatedAt = block.timestamp;
        // Note: users Set.Data will be initialized to its default empty state

        userFleets[msg.sender].push(fleet);
    }

    function CreateFleet() external {
        CreateFleet(string(abi.encodePacked("Fleet ", userFleets[msg.sender].length + 1)));
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
            owner: metadata.owner, fleet: metadata.fleet, createdAt: metadata.createdAt, updatedAt: metadata.updatedAt
        });
    }

    // Get the fleets for a user
    function GetOwnFleet(uint256 fleetIndex) external view returns (FleetMetadataView memory) {
        return _toFleetMetadataView(fleets[userFleets[msg.sender][fleetIndex]]);
    }

    function GetFleetUserCount(address fleet) external view returns (uint256) {
        require(
            fleets[fleet].owner == msg.sender || Set.IsMember(fleets[fleet].users, msg.sender),
            "You do not own this fleet"
        );
        return Set.Size(fleets[fleet].users);
    }

    function GetFleetUser(address fleet, uint256 userIndex) external view returns (address) {
        require(
            fleets[fleet].owner == msg.sender || Set.IsMember(fleets[fleet].users, msg.sender),
            "You do not own this fleet"
        );
        return fleets[fleet].users.items[userIndex];
    }

    function GetFleet(address fleet) external view returns (FleetMetadataView memory) {
        require(
            fleets[fleet].owner == msg.sender || Set.IsMember(fleets[fleet].users, msg.sender),
            "You do not own this fleet"
        );
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

    // ======== Organisation Support ========

    /**
     * @notice Create a new organisation. The caller becomes the owner.
     * @param _name The name of the organisation
     * @param _description A description of the organisation
     * @return org The address of the newly created organisation
     */
    function CreateOrganisation(string memory _name, string memory _description) public returns (address org) {
        org = address(new ManagedProxy(this, "ZTNAOrganisation"));
        InitializableOrganisation(org).initialize(payable(msg.sender), _name, _description);
        userOrganisations[msg.sender].push(org);
        validOrganisations[org] = true;
        return org;
    }

    /**
     * @notice Create a new organisation with default name
     * @return The address of the newly created organisation
     */
    function CreateOrganisation() external returns (address) {
        return
            CreateOrganisation(string(abi.encodePacked("Organisation ", userOrganisations[msg.sender].length + 1)), "");
    }

    /**
     * @notice Get the number of organisations owned by the caller
     * @return The number of organisations
     */
    function GetOwnOrganisationCount() external view returns (uint256) {
        return userOrganisations[msg.sender].length;
    }

    /**
     * @notice Get an organisation owned by the caller by index
     * @param orgIndex The index of the organisation
     * @return The organisation address
     */
    function GetOwnOrganisation(uint256 orgIndex) external view returns (address) {
        return userOrganisations[msg.sender][orgIndex];
    }

    /**
     * @notice Get the ZTNAOrganisation implementation contract address
     * @return The address of the organisation implementation
     */
    function OrganisationContract() external view returns (address) {
        return organisationImplementation;
    }

    // ======== Organisation Membership Callbacks ========
    // These are called by organisation contracts to track membership in the registry

    modifier onlyValidOrganisation() {
        require(validOrganisations[msg.sender], "Caller is not a valid organisation");
        _;
    }

    /**
     * @notice Called by organisation when adding an admin
     * @param _user The user being added as admin
     */
    function orgAddAdmin(address _user) external onlyValidOrganisation {
        Set.Add(adminOrganisations[_user], msg.sender);
    }

    /**
     * @notice Called by organisation when removing an admin
     * @param _user The user being removed as admin
     */
    function orgRemoveAdmin(address _user) external onlyValidOrganisation {
        Set.Remove(adminOrganisations[_user], msg.sender);
    }

    /**
     * @notice Called by organisation when adding a member
     * @param _user The user being added as member
     */
    function orgAddMember(address _user) external onlyValidOrganisation {
        Set.Add(memberOrganisations[_user], msg.sender);
    }

    /**
     * @notice Called by organisation when removing a member
     * @param _user The user being removed as member
     */
    function orgRemoveMember(address _user) external onlyValidOrganisation {
        Set.Remove(memberOrganisations[_user], msg.sender);
    }

    /**
     * @notice Called by organisation when transferring ownership
     * @param _previousOwner The previous owner
     * @param _newOwner The new owner
     */
    function orgTransferOwnership(address _previousOwner, address _newOwner) external onlyValidOrganisation {
        // Remove org from previous owner's list
        address[] storage prevOwnerOrgs = userOrganisations[_previousOwner];
        for (uint256 i = 0; i < prevOwnerOrgs.length; i++) {
            if (prevOwnerOrgs[i] == msg.sender) {
                prevOwnerOrgs[i] = prevOwnerOrgs[prevOwnerOrgs.length - 1];
                prevOwnerOrgs.pop();
                break;
            }
        }
        // Add org to new owner's list
        userOrganisations[_newOwner].push(msg.sender);
    }

    // ======== Organisation Membership Queries ========
    // These allow users to query which organisations they belong to

    /**
     * @notice Get all organisations where the caller is an admin
     * @return Array of organisation addresses
     */
    function GetOrganisationsWhereAdmin() external view returns (address[] memory) {
        return Set.Members(adminOrganisations[msg.sender]);
    }

    /**
     * @notice Get all organisations where the caller is a member
     * @return Array of organisation addresses
     */
    function GetOrganisationsWhereMember() external view returns (address[] memory) {
        return Set.Members(memberOrganisations[msg.sender]);
    }

    /**
     * @notice Get all organisations the caller owns, is admin of, or is member of
     * @return ownedOrgs Organisations owned by caller
     * @return adminOrgs Organisations where caller is admin
     * @return memberOrgs Organisations where caller is member
     */
    function GetAllMyOrganisations()
        external
        view
        returns (address[] memory ownedOrgs, address[] memory adminOrgs, address[] memory memberOrgs)
    {
        ownedOrgs = userOrganisations[msg.sender];
        adminOrgs = Set.Members(adminOrganisations[msg.sender]);
        memberOrgs = Set.Members(memberOrganisations[msg.sender]);
    }

    function Version() external pure returns (uint256) {
        return 118;
    }
}
