// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "./deps/Set.sol";
import "./ZTNAPerimeterContract.sol";
import "./FleetContractUpgradeable.sol";

/**
 * @title ZTNAOrganisation
 * @notice A single organisation instance that can own and manage multiple perimeters
 * @dev Each organisation is deployed as a ManagedProxy pointing to this implementation.
 *      Organizations have three roles: Owner (one), Admins (many), Members (many)
 *      Admins are members with the isAdmin flag set to true.
 *
 * Use cases:
 * 1. Users can create new organizations (they become the owner)
 * 2. Owners can add/remove admins and members
 * 3. Admins can add/remove members (but not change admin status)
 * 4. Users can transfer their owned perimeters to an organization
 * 5. Owners and Admins can create new perimeters within the organization
 * 6. Admins can add themselves as admins to perimeters owned by the organization
 */
contract ZTNAOrganisation {
    using Set for Set.Data;

    // ======== Structs ========
    struct Member {
        address user;
        string nickname;
        string email;
        string avatarURI;
        bool isAdmin;
        uint256 createdAt;
        bool active;
    }

    // External view struct (without internal fields)
    struct MemberView {
        address user;
        string nickname;
        string email;
        string avatarURI;
        bool isAdmin;
        uint256 createdAt;
    }

    // ======== Events ========
    event OrganisationUpdated(string name);
    event MemberAdded(address indexed member, bool isAdmin);
    event MemberUpdated(address indexed member);
    event MemberRemoved(address indexed member);
    event AdminStatusChanged(address indexed member, bool isAdmin);
    event PerimeterAdded(address indexed perimeter);
    event PerimeterRemoved(address indexed perimeter);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ======== Storage ========
    // Note: Storage layout must be stable for proxy pattern
    string public name;
    string public description;
    address public owner;
    uint256 public createdAt;

    Set.Data private members;
    mapping(address => Member) private memberInfo;
    Set.Data private perimeters;

    // Track which perimeters belong to this org
    mapping(address => bool) private perimeterInOrg;

    // Reference to the registry for creating perimeters
    address private immutable REGISTRY;

    // Initialization flag
    bool private initialized;

    // ======== Constructor ========
    constructor(address _registry) {
        REGISTRY = _registry;
        initialized = true; // Prevent implementation contract from being initialized
    }

    // ======== Initialization ========
    function initialize(address payable _owner, string memory _name, string memory _description) external {
        require(!initialized, "Already initialized");
        initialized = true;

        owner = _owner;
        name = _name;
        description = _description;
        createdAt = block.timestamp;
    }

    // ======== Modifiers ========
    modifier onlyOwner() {
        require(owner == msg.sender, "NOT_OWNER");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(owner == msg.sender || _isAdmin(msg.sender), "NOT_OWNER_OR_ADMIN");
        _;
    }

    modifier onlyMember() {
        require(owner == msg.sender || _isMember(msg.sender), "NOT_MEMBER");
        _;
    }

    modifier onlyPerimeterOwner(address _perimeter) {
        require(FleetContractUpgradeable(_perimeter).Operator() == msg.sender, "NOT_PERIMETER_OWNER");
        _;
    }

    // ======== Internal Helper Functions ========
    function _isMember(address _user) internal view returns (bool) {
        return memberInfo[_user].active;
    }

    function _isAdmin(address _user) internal view returns (bool) {
        return memberInfo[_user].active && memberInfo[_user].isAdmin;
    }

    // ======== Organisation Management ========

    /**
     * @notice Update organisation details
     * @param _name New name
     * @param _description New description
     */
    function updateOrganisation(string memory _name, string memory _description) external onlyOwner {
        name = _name;
        description = _description;
        emit OrganisationUpdated(_name);
    }

    /**
     * @notice Transfer ownership of the organisation to a new owner
     * @param _newOwner The new owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_OWNER");
        address previousOwner = owner;
        owner = _newOwner;
        IZTNARegistryMembership(REGISTRY).orgTransferOwnership(previousOwner, _newOwner);
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    // ======== Member Management ========

    /**
     * @notice Add a member to the organisation
     * @param _member The address to add as member
     * @param _nickname The member's nickname
     * @param _email The member's email
     * @param _avatarURI The member's avatar URI
     * @param _asAdmin Whether the member should be an admin
     */
    function addMember(
        address _member,
        string memory _nickname,
        string memory _email,
        string memory _avatarURI,
        bool _asAdmin
    ) public onlyOwnerOrAdmin {
        require(_member != address(0), "INVALID_MEMBER");
        require(!memberInfo[_member].active, "ALREADY_MEMBER");
        // Only owner can add admins
        require(!_asAdmin || msg.sender == owner, "ONLY_OWNER_CAN_ADD_ADMIN");

        Set.Add(members, _member);
        memberInfo[_member] = Member({
            user: _member,
            nickname: _nickname,
            email: _email,
            avatarURI: _avatarURI,
            isAdmin: _asAdmin,
            createdAt: block.timestamp,
            active: true
        });

        // Notify registry
        IZTNARegistryMembership(REGISTRY).orgAddMember(_member);
        if (_asAdmin) {
            IZTNARegistryMembership(REGISTRY).orgAddAdmin(_member);
        }

        emit MemberAdded(_member, _asAdmin);
    }

    /**
     * @notice Add a member with default empty fields
     * @param _member The address to add as member
     */
    function addMember(address _member) external onlyOwnerOrAdmin {
        addMember(_member, "", "", "", false);
    }

    /**
     * @notice Add an admin (member with admin privileges)
     * @param _admin The address to add as admin
     */
    function addAdmin(address _admin) external onlyOwner {
        addMember(_admin, "", "", "", true);
    }

    /**
     * @notice Update a member's info
     * @param _member The member address
     * @param _nickname New nickname
     * @param _email New email
     * @param _avatarURI New avatar URI
     */
    function updateMember(address _member, string memory _nickname, string memory _email, string memory _avatarURI)
        external
        onlyOwnerOrAdmin
    {
        require(memberInfo[_member].active, "NOT_MEMBER");

        memberInfo[_member].nickname = _nickname;
        memberInfo[_member].email = _email;
        memberInfo[_member].avatarURI = _avatarURI;

        emit MemberUpdated(_member);
    }

    /**
     * @notice Set or remove admin status for a member
     * @param _member The member address
     * @param _adminStatus Whether the member should be an admin
     */
    function setAdmin(address _member, bool _adminStatus) external onlyOwner {
        require(memberInfo[_member].active, "NOT_MEMBER");
        require(memberInfo[_member].isAdmin != _adminStatus, "ALREADY_SET");

        memberInfo[_member].isAdmin = _adminStatus;

        // Notify registry
        if (_adminStatus) {
            IZTNARegistryMembership(REGISTRY).orgAddAdmin(_member);
        } else {
            IZTNARegistryMembership(REGISTRY).orgRemoveAdmin(_member);
        }

        emit AdminStatusChanged(_member, _adminStatus);
    }

    /**
     * @notice Remove admin status from a member (convenience function)
     * @param _admin The admin address
     */
    function removeAdmin(address _admin) external onlyOwner {
        require(memberInfo[_admin].active, "NOT_MEMBER");
        require(memberInfo[_admin].isAdmin, "NOT_ADMIN");

        memberInfo[_admin].isAdmin = false;
        IZTNARegistryMembership(REGISTRY).orgRemoveAdmin(_admin);

        emit AdminStatusChanged(_admin, false);
    }

    /**
     * @notice Remove a member from the organisation
     * @param _member The address to remove as member
     */
    function removeMember(address _member) external onlyOwnerOrAdmin {
        require(memberInfo[_member].active, "NOT_MEMBER");
        // Admins can only remove non-admin members
        require(msg.sender == owner || !memberInfo[_member].isAdmin, "ONLY_OWNER_CAN_REMOVE_ADMIN");

        bool wasAdmin = memberInfo[_member].isAdmin;

        Set.Remove(members, _member);
        memberInfo[_member].active = false;
        memberInfo[_member].isAdmin = false;

        // Notify registry
        if (wasAdmin) {
            IZTNARegistryMembership(REGISTRY).orgRemoveAdmin(_member);
        }
        IZTNARegistryMembership(REGISTRY).orgRemoveMember(_member);

        emit MemberRemoved(_member);
    }

    // ======== Perimeter Management ========

    /**
     * @notice Register a perimeter that's already owned by this organisation.
     *         The perimeter must have been transferred to this contract first.
     * @param _perimeter The perimeter contract address (must already be owned by this contract)
     */
    function registerPerimeter(address _perimeter) external onlyOwnerOrAdmin {
        require(!perimeterInOrg[_perimeter], "PERIMETER_ALREADY_IN_ORG");
        require(FleetContractUpgradeable(_perimeter).Operator() == address(this), "PERIMETER_NOT_OWNED_BY_ORG");

        Set.Add(perimeters, _perimeter);
        perimeterInOrg[_perimeter] = true;

        emit PerimeterAdded(_perimeter);
    }

    /**
     * @notice Transfer an existing perimeter to this organisation in one step.
     *         The caller must be the current operator/owner of the perimeter AND
     *         must be an owner or admin of the organisation.
     * @param _perimeter The perimeter contract address
     */
    function transferPerimeterToOrganisation(address _perimeter)
        external
        onlyOwnerOrAdmin
        onlyPerimeterOwner(_perimeter)
    {
        require(!perimeterInOrg[_perimeter], "PERIMETER_ALREADY_IN_ORG");

        // Transfer the perimeter's operator to this contract
        FleetContractUpgradeable(_perimeter).transferOperator(payable(address(this)));

        Set.Add(perimeters, _perimeter);
        perimeterInOrg[_perimeter] = true;

        emit PerimeterAdded(_perimeter);
    }

    /**
     * @notice Remove a perimeter from the organisation and transfer it to a new owner
     * @param _perimeter The perimeter to remove
     * @param _newOwner The new owner of the perimeter
     */
    function removePerimeter(address _perimeter, address payable _newOwner) external onlyOwner {
        require(perimeterInOrg[_perimeter], "PERIMETER_NOT_IN_ORG");
        require(_newOwner != address(0), "INVALID_NEW_OWNER");

        // Transfer the perimeter's operator to the new owner
        FleetContractUpgradeable(_perimeter).transferOperator(_newOwner);

        Set.Remove(perimeters, _perimeter);
        perimeterInOrg[_perimeter] = false;

        emit PerimeterRemoved(_perimeter);
    }

    /**
     * @notice Create a new perimeter within the organisation via the registry
     * @param _label The label for the new perimeter
     * @return perimeter The address of the newly created perimeter
     */
    function createPerimeter(string memory _label) external onlyOwnerOrAdmin returns (address perimeter) {
        // Create the perimeter through the registry - it will be owned by this contract
        IZTNAPerimeterRegistry(REGISTRY).CreateFleet(_label);

        // Get the last created fleet for this contract
        uint256 fleetCount = IZTNAPerimeterRegistry(REGISTRY).GetOwnFleetCount();
        IZTNAPerimeterRegistry.FleetMetadataView memory fleet =
            IZTNAPerimeterRegistry(REGISTRY).GetOwnFleet(fleetCount - 1);
        perimeter = fleet.fleet;

        Set.Add(perimeters, perimeter);
        perimeterInOrg[perimeter] = true;

        emit PerimeterAdded(perimeter);
        return perimeter;
    }

    /**
     * @notice Add yourself (caller) as an admin to a perimeter owned by the organisation
     * @param _perimeter The perimeter to add yourself as admin to
     * @param _nickname Your nickname in the perimeter
     */
    function addSelfAsPerimeterAdmin(address _perimeter, string memory _nickname) external onlyOwnerOrAdmin {
        require(perimeterInOrg[_perimeter], "PERIMETER_NOT_IN_ORG");

        // Add the caller as an admin to the perimeter
        ZTNAPerimeterContract(_perimeter).addPerimeterAdmin(msg.sender, _nickname);
    }

    // ======== View Functions ========

    /**
     * @notice Get all admins of the organisation (members only)
     * @return Array of admin addresses
     */
    function getAdmins() external view onlyMember returns (address[] memory) {
        address[] memory allMembers = Set.Members(members);
        uint256 adminCount = 0;

        // Count admins
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (memberInfo[allMembers[i]].isAdmin) {
                adminCount++;
            }
        }

        // Build admin array
        address[] memory adminList = new address[](adminCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (memberInfo[allMembers[i]].isAdmin) {
                adminList[index] = allMembers[i];
                index++;
            }
        }

        return adminList;
    }

    /**
     * @notice Get all members of the organisation (members only)
     * @return Array of member addresses
     */
    function getMembers() external view onlyMember returns (address[] memory) {
        return Set.Members(members);
    }

    /**
     * @notice Get detailed info for all members (members only)
     * @return Array of MemberView structs
     */
    function getMembersDetailed() external view onlyMember returns (MemberView[] memory) {
        address[] memory allMembers = Set.Members(members);
        MemberView[] memory result = new MemberView[](allMembers.length);

        for (uint256 i = 0; i < allMembers.length; i++) {
            Member storage m = memberInfo[allMembers[i]];
            result[i] = MemberView({
                user: m.user,
                nickname: m.nickname,
                email: m.email,
                avatarURI: m.avatarURI,
                isAdmin: m.isAdmin,
                createdAt: m.createdAt
            });
        }

        return result;
    }

    /**
     * @notice Get info for a specific member (members only)
     * @param _member The member address
     * @return MemberView struct
     */
    function getMember(address _member) external view onlyMember returns (MemberView memory) {
        require(memberInfo[_member].active, "NOT_MEMBER");
        Member storage m = memberInfo[_member];
        return MemberView({
            user: m.user,
            nickname: m.nickname,
            email: m.email,
            avatarURI: m.avatarURI,
            isAdmin: m.isAdmin,
            createdAt: m.createdAt
        });
    }

    /**
     * @notice Get all perimeters owned by the organisation (members only)
     * @return Array of perimeter addresses
     */
    function getPerimeters() external view onlyMember returns (address[] memory) {
        return Set.Members(perimeters);
    }

    /**
     * @notice Check if an address is an admin of this organisation
     * @param _user The address to check
     * @return True if the user is an admin
     */
    function isAdmin(address _user) external view returns (bool) {
        return _isAdmin(_user);
    }

    /**
     * @notice Check if an address is a member of this organisation
     * @param _user The address to check
     * @return True if the user is a member
     */
    function isMember(address _user) external view returns (bool) {
        return _isMember(_user);
    }

    /**
     * @notice Check if an address is the owner of this organisation
     * @param _user The address to check
     * @return True if the user is the owner
     */
    function isOwner(address _user) external view returns (bool) {
        return owner == _user;
    }

    /**
     * @notice Check if an address is the owner or admin of this organisation
     * @param _user The address to check
     * @return True if the user is owner or admin
     */
    function isOwnerOrAdmin(address _user) external view returns (bool) {
        return owner == _user || _isAdmin(_user);
    }

    /**
     * @notice Check if a perimeter belongs to this organisation (members only)
     * @param _perimeter The perimeter address
     * @return True if the perimeter is in this org
     */
    function hasPerimeter(address _perimeter) external view onlyMember returns (bool) {
        return perimeterInOrg[_perimeter];
    }

    /**
     * @notice Get the registry address
     * @return The registry contract address
     */
    function Registry() external view returns (address) {
        return REGISTRY;
    }

    function Version() external pure returns (uint256) {
        return 202;
    }
}

/**
 * @title IZTNAPerimeterRegistry
 * @notice Interface for the perimeter registry
 */
interface IZTNAPerimeterRegistry {
    struct FleetMetadataView {
        address owner;
        address fleet;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function CreateFleet(string memory label) external;
    function GetOwnFleetCount() external view returns (uint256);
    function GetOwnFleet(uint256 fleetIndex) external view returns (FleetMetadataView memory);
}

/**
 * @title IZTNARegistryMembership
 * @notice Interface for registry membership tracking callbacks
 */
interface IZTNARegistryMembership {
    function orgAddAdmin(address _user) external;
    function orgRemoveAdmin(address _user) external;
    function orgAddMember(address _user) external;
    function orgRemoveMember(address _user) external;
    function orgTransferOwnership(address _previousOwner, address _newOwner) external;
}
