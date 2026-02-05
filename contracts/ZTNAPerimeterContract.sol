// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;

import "./FleetContractUpgradeable.sol";
import "./deps/Set.sol";
import "./sapphire/Sapphire.sol";
import "./IZTNAContract.sol";

/**
 * ZTNAPerimeterContract adds new functionality around Users, User Groups, Devices, Tags (Groups of Devices)
 * similar to Tailscale's tailnet configuration panel
 */
contract ZTNAPerimeterContract is FleetContractUpgradeable, IZTNAContract {
    using Set for Set.Data;

    // Fleet label
    string public label;

    // ======== Events ========
    event UserCreated(address indexed userAddress, string nickname);
    event UserUpdated(address indexed userAddress, string nickname);
    event UserRemoved(address indexed userAddress);
    event UserGroupCreated(address indexed groupId, string name);
    event UserGroupUpdated(address indexed groupId, string name);
    event UserGroupRemoved(address indexed groupId);
    event UserAddedToGroup(address indexed userAddress, address indexed groupId);
    event UserRemovedFromGroup(address indexed userAddress, address indexed groupId);
    event DeviceCreated(address indexed deviceId, address owner, string name);
    event DeviceUpdated(address indexed deviceId, string name);
    event DeviceRemoved(address indexed deviceId);
    event TagCreated(address indexed tagId, string name);
    event TagUpdated(address indexed tagId, string name);
    event TagRemoved(address indexed tagId);
    event DeviceAddedToTag(address indexed deviceId, address indexed tagId);
    event DeviceRemovedFromTag(address indexed deviceId, address indexed tagId);
    event FleetLabelUpdated(string newLabel);
    event DevicePropertySet(address indexed deviceId, string key, string value);
    event TagPropertySet(address indexed tagId, string key, string value);

    // ======== Structs ========
    struct User {
        address user;
        string nickname;
        string email;
        string avatarURI;
        bool isAdmin;
        uint256 createdAt;
        Set.Data groups;
        bool active;
    }

    struct UserGroup {
        address id;
        string name;
        string description;
        uint256 createdAt;
        address createdBy;
        bool active;
    }

    struct Device {
        address id;
        address owner;
        string name;
        string description;
        string deviceType; // e.g., "sensor", "gateway", "controller"
        string location;
        uint256 createdAt;
        uint256 lastSeen;
        Set.Data tags;
        bool active;
        Sapphire.Curve25519PublicKey publicKey; // Curve25519 public key
        Sapphire.Curve25519SecretKey privateKey; // Curve25519 private key (encrypted/accessible only by device)
    }

    struct Tag {
        address id;
        string name;
        string description;
        string color; // For UI representation
        uint256 createdAt;
        address createdBy;
        bool active;
    }

    // ======== Storage ========
    mapping(address => User) private users;
    mapping(address => UserGroup) private userGroups;
    mapping(address => Device) private devices;
    mapping(address => Tag) private tags;

    // Lookup mappings
    mapping(address => Set.Data) private groupUsers; // groupId => Set of user addresses
    mapping(address => Set.Data) private tagDevices; // tagId => Set of device IDs
    mapping(address => Set.Data) private userDevices; // user address => Set of device IDs

    // Property mappings
    mapping(address => mapping(string => string)) private deviceProperties; // deviceId => key => value
    mapping(address => mapping(string => string)) private tagProperties; // tagId => key => value

    // Counters for IDs
    uint256 private userGroupCounter;
    uint256 private tagCounter;

    // List of all entities for enumeration
    address[] private allUsers;
    address[] private allUserGroups;
    address[] private allDevices;
    address[] private allTags;

    // Static default tag id used for fallback properties (not a real tag).
    address private constant DEFAULT_TAG_ID = address(uint160(uint256(keccak256("diode_default_tag"))));
    string private constant DEFAULT_FLEET_VALUE = "0x6000000000000000000000000000000000000000";

    // Override initialize to include label
    function initialize(address payable _owner, string memory _label) public initializer {
        super.initialize(_owner);
        label = _label;
        operator = _owner;

        // Create default admin user with admin privileges
        _createUser(_owner, "Admin", "", "", true);

        // Create default user group
        address adminGroupId = _createUserGroup("Administrators", "Users with administrative privileges");
        _addUserToGroup(_owner, adminGroupId);
    }

    // For backward compatibility
    function initialize(address payable _owner) public override initializer {
        initialize(_owner, "");
    }

    // Allow updating the fleet label
    function updateLabel(string memory _newLabel) external onlyOperator {
        label = _newLabel;
        emit FleetLabelUpdated(_newLabel);
    }

    constructor() FleetContractUpgradeable(address(0)) {
        initialize(payable(msg.sender));
    }

    // ======== Modifiers ========
    modifier userExists(address _userAddress) {
        _requireUserExists(_userAddress);
        _;
    }

    modifier onlyMember() {
        _requireUserExists(msg.sender);
        _;
    }

    function _requireUserExists(address _userAddress) internal view {
        require(users[_userAddress].active, "UNE");
    }

    modifier userGroupExists(address _groupId) {
        _requireUserGroupExists(_groupId);
        _;
    }

    function _requireUserGroupExists(address _groupId) internal view {
        require(userGroups[_groupId].active, "UGNE");
    }

    modifier deviceExists(address _deviceId) {
        _requireDeviceExists(_deviceId);
        _;
    }

    function _requireDeviceExists(address _deviceId) internal view {
        require(devices[_deviceId].active, "DNE");
    }

    modifier tagExists(address _tagId) {
        _requireTagExists(_tagId);
        _;
    }

    function _requireTagExists(address _tagId) internal view {
        require(tags[_tagId].active, "TNE");
    }

    modifier onlyMemberOrDevice(address _deviceId) {
        _requireMemberOrDevice(_deviceId);
        _;
    }

    function _requireMemberOrDevice(address _deviceId) internal view {
        require(users[msg.sender].active || msg.sender == _deviceId, "AUTH");
        require(devices[_deviceId].active, "DNE");
    }

    modifier onlyAdmin() {
        _requireAdmin(msg.sender);
        _;
    }

    function _requireAdmin(address _userAddress) internal view {
        require(users[_userAddress].isAdmin || _userAddress == operator, "AUTH");
    }

    modifier onlyDeviceOwner(address _deviceId) {
        _requireDeviceOwner(_deviceId);
        _;
    }

    function _requireDeviceOwner(address _deviceId) internal view {
        require(devices[_deviceId].active, "DNE");
        require(devices[_deviceId].owner == msg.sender || users[msg.sender].isAdmin, "AUTH");
    }

    modifier onlyDevice(address _deviceId) {
        _requireDevice(_deviceId);
        _;
    }

    function _requireDevice(address _deviceId) internal view {
        require(msg.sender == _deviceId, "AUTH");
        require(devices[_deviceId].active, "DNE");
    }

    // ======== User Management ========
    function createUser(address _userAddress, string memory _nickname, string memory _email, string memory _avatarURI)
        external
        onlyOperator
    {
        _createUser(_userAddress, _nickname, _email, _avatarURI, false);
    }

    function _createUser(
        address _userAddress,
        string memory _nickname,
        string memory _email,
        string memory _avatarURI,
        bool _isAdmin
    ) private {
        require(_userAddress != address(0), "IUA");
        require(!users[_userAddress].active, "UAE");

        if (users[_userAddress].user == address(0)) {
            allUsers.push(_userAddress);
        }

        // Initialize the user struct fields individually
        users[_userAddress].user = _userAddress;
        users[_userAddress].nickname = _nickname;
        users[_userAddress].email = _email;
        users[_userAddress].avatarURI = _avatarURI;
        users[_userAddress].isAdmin = _isAdmin; // Set admin status based on parameter
        users[_userAddress].createdAt = block.timestamp;
        users[_userAddress].active = true;
        // Note: groups is already initialized as an empty Set.Data

        emit UserCreated(_userAddress, _nickname);
    }

    function updateUser(address _userAddress, string memory _nickname, string memory _email, string memory _avatarURI)
        external
        onlyOperator
        userExists(_userAddress)
    {
        users[_userAddress].nickname = _nickname;
        users[_userAddress].email = _email;
        users[_userAddress].avatarURI = _avatarURI;

        emit UserUpdated(_userAddress, _nickname);
    }

    function setUserAdmin(address _userAddress, bool _isAdmin) external onlyOperator userExists(_userAddress) {
        users[_userAddress].isAdmin = _isAdmin;
    }

    /**
     * @notice Add a user as admin to this perimeter. If the user doesn't exist, create them first.
     * @param _userAddress The address of the user to add as admin
     * @param _nickname The nickname for the user (used if creating new user)
     */
    function addPerimeterAdmin(address _userAddress, string memory _nickname) external onlyOperator {
        require(_userAddress != address(0), "IUA");

        // If user doesn't exist, create them
        if (!users[_userAddress].active) {
            _createUser(_userAddress, _nickname, "", "", true);
        } else {
            // User exists, just set admin status
            users[_userAddress].isAdmin = true;
        }
    }

    function removeUser(address _userAddress) external onlyOperator userExists(_userAddress) {
        // Remove user from all groups
        address[] memory userGroupsList = Set.Members(users[_userAddress].groups);
        for (uint256 i = 0; i < userGroupsList.length; i++) {
            address groupId = userGroupsList[i];
            _removeUserFromGroup(_userAddress, groupId);
        }

        // Mark user as inactive
        users[_userAddress].active = false;

        emit UserRemoved(_userAddress);
    }

    function getUser(address _userAddress)
        external
        view
        onlyMember
        returns (
            address user,
            string memory nickname,
            string memory email,
            string memory avatarURI,
            bool isAdmin,
            uint256 createdAt,
            bool active
        )
    {
        User storage userData = users[_userAddress];
        return (
            userData.user,
            userData.nickname,
            userData.email,
            userData.avatarURI,
            userData.isAdmin,
            userData.createdAt,
            userData.active
        );
    }

    function getUserGroups(address _userAddress)
        external
        view
        onlyMember
        userExists(_userAddress)
        returns (address[] memory)
    {
        return Set.Members(users[_userAddress].groups);
    }

    function getAllUsers() external view onlyMember returns (address[] memory) {
        return allUsers;
    }

    // ======== User Group Management ========
    function createUserGroup(string memory _name, string memory _description) external onlyAdmin returns (address) {
        return _createUserGroup(_name, _description);
    }

    function _createUserGroup(string memory _name, string memory _description) private returns (address) {
        address groupId = address(bytes20(keccak256(abi.encodePacked("GROUP", userGroupCounter++, block.timestamp))));

        // Initialize the user group struct fields individually
        userGroups[groupId].id = groupId;
        userGroups[groupId].name = _name;
        userGroups[groupId].description = _description;
        userGroups[groupId].createdAt = block.timestamp;
        userGroups[groupId].createdBy = msg.sender;
        userGroups[groupId].active = true;

        allUserGroups.push(groupId);
        emit UserGroupCreated(groupId, _name);
        return groupId;
    }

    function updateUserGroup(address _groupId, string memory _name, string memory _description)
        external
        onlyAdmin
        userGroupExists(_groupId)
    {
        userGroups[_groupId].name = _name;
        userGroups[_groupId].description = _description;

        emit UserGroupUpdated(_groupId, _name);
    }

    function removeUserGroup(address _groupId) external onlyAdmin userGroupExists(_groupId) {
        // Remove all users from this group
        address[] memory groupUsersList = Set.Members(groupUsers[_groupId]);
        for (uint256 i = 0; i < groupUsersList.length; i++) {
            _removeUserFromGroup(groupUsersList[i], _groupId);
        }

        // Mark group as inactive
        userGroups[_groupId].active = false;

        emit UserGroupRemoved(_groupId);
    }

    function addUserToGroup(address _userAddress, address _groupId)
        external
        onlyAdmin
        userExists(_userAddress)
        userGroupExists(_groupId)
    {
        _addUserToGroup(_userAddress, _groupId);
    }

    function _addUserToGroup(address _userAddress, address _groupId) private {
        // Add group to user's groups
        Set.Add(users[_userAddress].groups, _groupId);

        // Add user to group's users
        Set.Add(groupUsers[_groupId], _userAddress);

        emit UserAddedToGroup(_userAddress, _groupId);
    }

    function removeUserFromGroup(address _userAddress, address _groupId)
        external
        onlyAdmin
        userExists(_userAddress)
        userGroupExists(_groupId)
    {
        _removeUserFromGroup(_userAddress, _groupId);
    }

    function _removeUserFromGroup(address _userAddress, address _groupId) private {
        // Remove group from user's groups
        Set.Remove(users[_userAddress].groups, _groupId);

        // Remove user from group's users
        Set.Remove(groupUsers[_groupId], _userAddress);

        emit UserRemovedFromGroup(_userAddress, _groupId);
    }

    function getUserGroup(address _groupId)
        external
        view
        onlyMember
        userGroupExists(_groupId)
        returns (
            address id,
            string memory name,
            string memory description,
            uint256 createdAt,
            address createdBy,
            bool active
        )
    {
        UserGroup storage group = userGroups[_groupId];
        return (group.id, group.name, group.description, group.createdAt, group.createdBy, group.active);
    }

    function getGroupUsers(address _groupId)
        external
        view
        userGroupExists(_groupId)
        onlyMember
        returns (address[] memory)
    {
        return Set.Members(groupUsers[_groupId]);
    }

    function getAllUserGroups() external view onlyMember returns (address[] memory) {
        return allUserGroups;
    }

    // ======== Device Management ========
    function createDevice(
        address _deviceId,
        string memory _name,
        string memory _description,
        string memory _deviceType,
        string memory _location
    ) external onlyAdmin returns (address) {
        require(_deviceId != address(0), "IDA");
        require(!devices[_deviceId].active, "DAE");

        // Initialize the device struct fields individually
        devices[_deviceId].id = _deviceId;
        devices[_deviceId].owner = msg.sender;
        devices[_deviceId].name = _name;
        devices[_deviceId].description = _description;
        devices[_deviceId].deviceType = _deviceType;
        devices[_deviceId].location = _location;
        devices[_deviceId].createdAt = block.timestamp;
        devices[_deviceId].lastSeen = block.timestamp;
        devices[_deviceId].active = true;
        doGenerateDeviceKeyPair(_deviceId);
        // Note: tags is already initialized as an empty Set.Data

        allDevices.push(_deviceId);
        Set.Add(userDevices[msg.sender], _deviceId);

        emit DeviceCreated(_deviceId, msg.sender, _name);
        return _deviceId;
    }

    function updateDevice(
        address _deviceId,
        string memory _name,
        string memory _description,
        string memory _deviceType,
        string memory _location
    ) external onlyDeviceOwner(_deviceId) {
        Device storage device = devices[_deviceId];

        device.name = _name;
        device.description = _description;
        device.deviceType = _deviceType;
        device.location = _location;

        emit DeviceUpdated(_deviceId, _name);
    }

    function updateDeviceLastSeen(address _deviceId) external onlyDeviceOwner(_deviceId) {
        devices[_deviceId].lastSeen = block.timestamp;
    }

    function transferDeviceOwnership(address _deviceId, address _newOwner)
        external
        onlyDeviceOwner(_deviceId)
        userExists(_newOwner)
    {
        address currentOwner = devices[_deviceId].owner;

        // Remove device from current owner's devices
        Set.Remove(userDevices[currentOwner], _deviceId);

        // Add device to new owner's devices
        Set.Add(userDevices[_newOwner], _deviceId);

        // Update device owner
        devices[_deviceId].owner = _newOwner;
    }

    function removeDevice(address _deviceId) external onlyDeviceOwner(_deviceId) {
        // Remove device from all tags
        address[] memory deviceTagsList = Set.Members(devices[_deviceId].tags);
        for (uint256 i = 0; i < deviceTagsList.length; i++) {
            address tagId = deviceTagsList[i];
            _removeDeviceFromTag(_deviceId, tagId);
        }

        // Remove device from owner's devices
        Set.Remove(userDevices[devices[_deviceId].owner], _deviceId);

        // Remove device from allDevices
        for (uint256 i = 0; i < allDevices.length; i++) {
            if (allDevices[i] == _deviceId) {
                allDevices[i] = allDevices[allDevices.length - 1];
                allDevices.pop();
                break;
            }
        }

        // Mark device as inactive
        devices[_deviceId].active = false;

        emit DeviceRemoved(_deviceId);
    }

    function getDevice(address _deviceId)
        external
        view
        onlyMember
        deviceExists(_deviceId)
        returns (
            address id,
            address owner,
            string memory name,
            string memory description,
            string memory deviceType,
            string memory location,
            uint256 createdAt,
            uint256 lastSeen,
            bool active
        )
    {
        Device storage device = devices[_deviceId];
        return (
            device.id,
            device.owner,
            device.name,
            device.description,
            device.deviceType,
            device.location,
            device.createdAt,
            device.lastSeen,
            device.active
        );
    }

    struct DeviceV2 {
        address id;
        address owner;
        string name;
        string description;
        string deviceType;
        string location;
        uint256 createdAt;
        uint256 lastSeen;
        bool active;
        Sapphire.Curve25519PublicKey publicKey;
        address[] tags;
        string[] properties;
    }

    function getDeviceV2(address _deviceId, string[] memory _keys)
        external
        view
        onlyMember
        deviceExists(_deviceId)
        returns (DeviceV2 memory device)
    {
        string[] memory _properties = doGetDeviceProperties(_deviceId, _keys);
        address[] memory _tags = Set.Members(devices[_deviceId].tags);
        Device storage _device = devices[_deviceId];

        return DeviceV2({
            id: _deviceId,
            owner: _device.owner,
            name: _device.name,
            description: _device.description,
            deviceType: _device.deviceType,
            location: _device.location,
            createdAt: _device.createdAt,
            lastSeen: _device.lastSeen,
            active: _device.active,
            publicKey: _device.publicKey,
            tags: _tags,
            properties: _properties
        });
    }

    function getUserDevices(address _userAddress)
        external
        view
        onlyMember
        userExists(_userAddress)
        returns (address[] memory)
    {
        return Set.Members(userDevices[_userAddress]);
    }

    function getAllDevices() external view onlyMember returns (address[] memory) {
        return allDevices;
    }

    /**
     * @notice Get the public key of a device
     * @param _deviceId The device address
     * @return publicKey The Curve25519 public key of the device
     */
    function getDevicePublicKey(address _deviceId)
        external
        view
        onlyMember
        deviceExists(_deviceId)
        returns (Sapphire.Curve25519PublicKey publicKey)
    {
        return devices[_deviceId].publicKey;
    }

    /**
     * @notice Get the private key of a device (only accessible by the device itself)
     * @param _deviceId The device address
     * @return privateKey The Curve25519 private key of the device
     */
    function getDevicePrivateKey(address _deviceId)
        external
        view
        onlyDevice(_deviceId)
        returns (Sapphire.Curve25519SecretKey privateKey)
    {
        return devices[_deviceId].privateKey;
    }

    /**
     * @notice Generate a Curve25519 key pair for an existing device (migration function)
     * @param _deviceId The device address
     * @return publicKey The generated public key
     */
    function generateDeviceKeyPair(address _deviceId)
        external
        onlyDeviceOwner(_deviceId)
        deviceExists(_deviceId)
        returns (Sapphire.Curve25519PublicKey publicKey)
    {
        require(Sapphire.Curve25519PublicKey.unwrap(devices[_deviceId].publicKey) == bytes32(0), "DUP");

        doGenerateDeviceKeyPair(_deviceId);
        return devices[_deviceId].publicKey;
    }

    function doGenerateDeviceKeyPair(address _deviceId) internal {
        if (block.chainid != 0x5afe) {
            return;
        }
        // Generate Curve25519 key pair for the device
        bytes memory personalization = abi.encodePacked("ZTNA_DEVICE_", _deviceId);
        (Sapphire.Curve25519PublicKey pk, Sapphire.Curve25519SecretKey sk) =
            Sapphire.generateCurve25519KeyPair(personalization);

        devices[_deviceId].publicKey = pk;
        devices[_deviceId].privateKey = sk;
    }

    // ======== Tag Management ========
    function createTag(string memory _name, string memory _description, string memory _color)
        external
        onlyAdmin
        returns (address)
    {
        address tagId = address(bytes20(keccak256(abi.encodePacked("TAG", tagCounter++, block.timestamp))));

        // Initialize the tag struct fields individually
        tags[tagId].id = tagId;
        tags[tagId].name = _name;
        tags[tagId].description = _description;
        tags[tagId].color = _color;
        tags[tagId].createdAt = block.timestamp;
        tags[tagId].createdBy = msg.sender;
        tags[tagId].active = true;

        allTags.push(tagId);
        emit TagCreated(tagId, _name);
        return tagId;
    }

    function updateTag(address _tagId, string memory _name, string memory _description, string memory _color)
        external
        onlyAdmin
        tagExists(_tagId)
    {
        tags[_tagId].name = _name;
        tags[_tagId].description = _description;
        tags[_tagId].color = _color;

        emit TagUpdated(_tagId, _name);
    }

    function removeTag(address _tagId) external onlyAdmin tagExists(_tagId) {
        // Remove all devices from this tag
        address[] memory tagDevicesList = Set.Members(tagDevices[_tagId]);
        for (uint256 i = 0; i < tagDevicesList.length; i++) {
            address deviceId = tagDevicesList[i];
            _removeDeviceFromTag(deviceId, _tagId);
        }

        // Mark tag as inactive
        tags[_tagId].active = false;

        emit TagRemoved(_tagId);
    }

    function addDeviceToTag(address _deviceId, address _tagId) external onlyDeviceOwner(_deviceId) tagExists(_tagId) {
        require(devices[_deviceId].owner == msg.sender || users[msg.sender].isAdmin, "AUTH");

        _addDeviceToTag(_deviceId, _tagId);
    }

    function _addDeviceToTag(address _deviceId, address _tagId) private {
        // Add tag to device's tags
        Set.Add(devices[_deviceId].tags, _tagId);

        // Add device to tag's devices
        Set.Add(tagDevices[_tagId], _deviceId);

        emit DeviceAddedToTag(_deviceId, _tagId);
    }

    function removeDeviceFromTag(address _deviceId, address _tagId) external deviceExists(_deviceId) tagExists(_tagId) {
        require(devices[_deviceId].owner == msg.sender || users[msg.sender].isAdmin, "AUTH");

        _removeDeviceFromTag(_deviceId, _tagId);
    }

    function _removeDeviceFromTag(address _deviceId, address _tagId) private {
        // Remove tag from device's tags
        Set.Remove(devices[_deviceId].tags, _tagId);

        // Remove device from tag's devices
        Set.Remove(tagDevices[_tagId], _deviceId);

        emit DeviceRemovedFromTag(_deviceId, _tagId);
    }

    function getDeviceTags(address _deviceId)
        external
        view
        onlyMember
        deviceExists(_deviceId)
        returns (address[] memory)
    {
        return Set.Members(devices[_deviceId].tags);
    }

    function getTagDevices(address _tagId) external view onlyMember tagExists(_tagId) returns (address[] memory) {
        return Set.Members(tagDevices[_tagId]);
    }

    function isDeviceInTag(address _deviceId, address _tagId) external view onlyMember returns (bool) {
        if (!devices[_deviceId].active || !tags[_tagId].active) {
            return false;
        }

        // Check if tag is in device's tags
        bool deviceHasTag = Set.IsMember(devices[_deviceId].tags, _tagId);

        // Check if device is in tag's devices
        bool tagHasDevice = Set.IsMember(tagDevices[_tagId], _deviceId);

        // Both relationships must exist
        return deviceHasTag && tagHasDevice;
    }

    function isDeviceOwner(address _userAddress, address _deviceId) external view onlyMember returns (bool) {
        return devices[_deviceId].active && devices[_deviceId].owner == _userAddress;
    }

    // ======== Access Control ========
    function isUserInGroup(address _userAddress, address _groupId) external view onlyMember returns (bool) {
        if (!users[_userAddress].active || !userGroups[_groupId].active) {
            return false;
        }

        return Set.IsMember(users[_userAddress].groups, _groupId);
    }

    function isUserAdmin(address _userAddress) external view onlyMember returns (bool) {
        return users[_userAddress].active && users[_userAddress].isAdmin;
    }

    // ======== Property Management ========
    function setDeviceProperty(address _deviceId, string memory _key, string memory _value)
        external
        onlyDeviceOwner(_deviceId)
    {
        deviceProperties[_deviceId][_key] = _value;
        emit DevicePropertySet(_deviceId, _key, _value);
    }

    function getDeviceProperty(address _deviceId, string memory _key) external view returns (string memory) {
        return deviceProperties[_deviceId][_key];
    }

    function getDeviceProperties(address _deviceId, string[] memory _keys)
        external
        view
        onlyMemberOrDevice(_deviceId)
        returns (string[] memory)
    {
        return doGetDeviceProperties(_deviceId, _keys);
    }

    function doGetDeviceProperties(address _deviceId, string[] memory _keys) internal view returns (string[] memory) {
        string[] memory values = new string[](_keys.length);
        for (uint256 i = 0; i < _keys.length; i++) {
            values[i] = deviceProperties[_deviceId][_keys[i]];
        }
        return values;
    }

    function setTagProperty(address _tagId, string memory _key, string memory _value) external onlyAdmin {
        tagProperties[_tagId][_key] = _value;
        emit TagPropertySet(_tagId, _key, _value);
    }

    function getTagProperty(address _tagId, string memory _key) external view onlyMember returns (string memory) {
        return tagProperties[_tagId][_key];
    }

    function getPropertyValue(address _deviceId, string memory _key)
        external
        view
        deviceExists(_deviceId)
        returns (string memory)
    {
        // First check device properties
        string memory deviceValue = deviceProperties[_deviceId][_key];

        address[] memory deviceTagsList = Set.Members(devices[_deviceId].tags);
        string memory combinedValue = "";

        // Start with device property if it exists
        if (bytes(deviceValue).length > 0) {
            combinedValue = deviceValue;
        }

        if (deviceTagsList.length > 0) {
            for (uint256 i = 0; i < deviceTagsList.length; i++) {
                address tagId = deviceTagsList[i];

                // Get the tag property
                string memory tagValue = tagProperties[tagId][_key];

                if (bytes(tagValue).length > 0) {
                    if (bytes(combinedValue).length == 0) {
                        combinedValue = tagValue;
                    } else {
                        combinedValue = string(abi.encodePacked(combinedValue, " ", tagValue));
                    }
                }
            }
        }

        if (bytes(combinedValue).length == 0) {
            string memory defaultValue = tagProperties[DEFAULT_TAG_ID][_key];
            if (bytes(defaultValue).length == 0 && keccak256(bytes(_key)) == keccak256("fleet")) {
                return DEFAULT_FLEET_VALUE;
            }
            return defaultValue;
        }

        return combinedValue;
    }

    function getPropertyValueDirect(address _deviceId, string memory _key)
        external
        view
        deviceExists(_deviceId)
        returns (string memory)
    {
        // Only return device properties, ignoring tag properties
        return deviceProperties[_deviceId][_key];
    }

    function getAllTags() external view onlyMember returns (address[] memory) {
        return allTags;
    }

    function getTag(address _tagId)
        external
        view
        onlyMember
        tagExists(_tagId)
        returns (
            address id,
            string memory name,
            string memory description,
            string memory color,
            uint256 createdAt,
            address createdBy,
            bool active
        )
    {
        Tag storage tag = tags[_tagId];
        return (tag.id, tag.name, tag.description, tag.color, tag.createdAt, tag.createdBy, tag.active);
    }

    function Version() external pure override(FleetContractUpgradeable, IZTNAContract) returns (uint256) {
        return 805;
    }

    function Type() external pure returns (bytes32) {
        return "ZTNAPerimeterContract";
    }
}
