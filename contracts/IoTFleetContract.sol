// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.8.20;
import "./FleetContractUpgradeable.sol";
import "./deps/Set.sol";

/**
 * IoTFleetContract adds new functionality around Users, User Groups, Devices, Tags (Groups of Devices)
 * similar to Tailscale's tailnet configuration panel
 */
contract IoTFleetContract is FleetContractUpgradeable {
    using Set for Set.Data;

    // Fleet label
    string public label;

    // ======== Events ========
    event UserCreated(address indexed userAddress, string nickname);
    event UserUpdated(address indexed userAddress, string nickname);
    event UserRemoved(address indexed userAddress);
    event UserGroupCreated(bytes32 indexed groupId, string name);
    event UserGroupUpdated(bytes32 indexed groupId, string name);
    event UserGroupRemoved(bytes32 indexed groupId);
    event UserAddedToGroup(address indexed userAddress, bytes32 indexed groupId);
    event UserRemovedFromGroup(address indexed userAddress, bytes32 indexed groupId);
    event DeviceCreated(address indexed deviceId, address owner, string name);
    event DeviceUpdated(address indexed deviceId, string name);
    event DeviceRemoved(address indexed deviceId);
    event TagCreated(bytes32 indexed tagId, string name);
    event TagUpdated(bytes32 indexed tagId, string name);
    event TagRemoved(bytes32 indexed tagId);
    event DeviceAddedToTag(address indexed deviceId, bytes32 indexed tagId);
    event DeviceRemovedFromTag(address indexed deviceId, bytes32 indexed tagId);
    event FleetLabelUpdated(string newLabel);
    event DevicePropertySet(address indexed deviceId, string key, string value);
    event TagPropertySet(bytes32 indexed tagId, string key, string value);

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
        bytes32 id;
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
    }

    struct Tag {
        bytes32 id;
        string name;
        string description;
        string color; // For UI representation
        uint256 createdAt;
        address createdBy;
        bool active;
    }

    // ======== Storage ========
    mapping(address => User) private users;
    mapping(bytes32 => UserGroup) private userGroups;
    mapping(address => Device) private devices;
    mapping(bytes32 => Tag) private tags;
    
    // Lookup mappings
    mapping(bytes32 => Set.Data) private groupUsers; // groupId => Set of user addresses
    mapping(bytes32 => Set.Data) private tagDevices; // tagId => Set of device IDs
    mapping(address => Set.Data) private userDevices; // user address => Set of device IDs
    
    // Property mappings
    mapping(address => mapping(string => string)) private deviceProperties; // deviceId => key => value
    mapping(bytes32 => mapping(string => string)) private tagProperties; // tagId => key => value
    
    // Counters for IDs
    uint256 private userGroupCounter;
    uint256 private tagCounter;
    
    // List of all entities for enumeration
    address[] private allUsers;
    bytes32[] private allUserGroups;
    address[] private allDevices;
    bytes32[] private allTags;

    // Override initialize to include label
    function initialize(address payable _owner, string memory _label) public initializer {
        super.initialize(_owner);
        label = _label;
    }

    // For backward compatibility
    function initialize(address payable _owner) public override initializer {
        initialize(_owner, "");
    }

    // Allow updating the fleet label
    function updateLabel(string memory _newLabel) 
        external 
        onlyOperator 
        returns (bool) 
    {
        label = _newLabel;
        emit FleetLabelUpdated(_newLabel);
        return true;
    }

    constructor() FleetContractUpgradeable(address(0)) {
        operator = msg.sender;
        
        // Create default admin user with admin privileges
        _createUser(msg.sender, "Admin", "", "", true);
        
        // Create default user group
        bytes32 adminGroupId = _createUserGroup("Administrators", "Users with administrative privileges");
        _addUserToGroup(msg.sender, adminGroupId);
    }

    // ======== Modifiers ========
    modifier userExists(address _userAddress) {
        require(users[_userAddress].active, "User does not exist");
        _;
    }
    
    modifier userGroupExists(bytes32 _groupId) {
        require(userGroups[_groupId].active, "User group does not exist");
        _;
    }
    
    modifier deviceExists(address _deviceId) {
        require(devices[_deviceId].active, "Device does not exist");
        _;
    }
    
    modifier tagExists(bytes32 _tagId) {
        require(tags[_tagId].active, "Tag does not exist");
        _;
    }
    
    modifier onlyAdmin() {
        require(users[msg.sender].isAdmin, "Only admins can perform this action");
        _;
    }
    
    modifier onlyDeviceOwner(address _deviceId) {
        require(devices[_deviceId].owner == msg.sender || users[msg.sender].isAdmin, 
                "Only device owner or admin can perform this action");
        _;
    }

    // ======== User Management ========
    function createUser(address _userAddress, string memory _nickname, string memory _email, string memory _avatarURI) 
        external 
        onlyOperator 
        returns (bool) 
    {
        return _createUser(_userAddress, _nickname, _email, _avatarURI, false);
    }
    
    function _createUser(address _userAddress, string memory _nickname, string memory _email, string memory _avatarURI, bool _isAdmin) 
        private 
        returns (bool) 
    {
        require(_userAddress != address(0), "Invalid user address");
        require(!users[_userAddress].active, "User already exists");
        
        // Initialize the user struct fields individually
        users[_userAddress].user = _userAddress;
        users[_userAddress].nickname = _nickname;
        users[_userAddress].email = _email;
        users[_userAddress].avatarURI = _avatarURI;
        users[_userAddress].isAdmin = _isAdmin; // Set admin status based on parameter
        users[_userAddress].createdAt = block.timestamp;
        users[_userAddress].active = true;
        // Note: groups is already initialized as an empty Set.Data
        
        allUsers.push(_userAddress);
        emit UserCreated(_userAddress, _nickname);
        return true;
    }
    
    function updateUser(address _userAddress, string memory _nickname, string memory _email, string memory _avatarURI) 
        external 
        onlyOperator 
        userExists(_userAddress) 
        returns (bool) 
    {
        users[_userAddress].nickname = _nickname;
        users[_userAddress].email = _email;
        users[_userAddress].avatarURI = _avatarURI;
        
        emit UserUpdated(_userAddress, _nickname);
        return true;
    }
    
    function setUserAdmin(address _userAddress, bool _isAdmin) 
        external 
        onlyOperator 
        userExists(_userAddress) 
        returns (bool) 
    {
        users[_userAddress].isAdmin = _isAdmin;
        return true;
    }
    
    function removeUser(address _userAddress) 
        external 
        onlyOperator 
        userExists(_userAddress) 
        returns (bool) 
    {
        // Remove user from all groups
        address[] memory userGroupsList = Set.Members(users[_userAddress].groups);
        for (uint i = 0; i < userGroupsList.length; i++) {
            bytes32 groupId = bytes32(uint256(uint160(userGroupsList[i])));
            _removeUserFromGroup(_userAddress, groupId);
        }
        
        // Mark user as inactive
        users[_userAddress].active = false;
        
        emit UserRemoved(_userAddress);
        return true;
    }
    
    function getUser(address _userAddress) 
        external 
        view 
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
        userExists(_userAddress) 
        returns (bytes32[] memory) 
    {
        address[] memory groupAddresses = Set.Members(users[_userAddress].groups);
        bytes32[] memory result = new bytes32[](groupAddresses.length);
        
        for (uint i = 0; i < groupAddresses.length; i++) {
            result[i] = bytes32(uint256(uint160(groupAddresses[i])));
        }
        
        return result;
    }
    
    function getAllUsers() 
        external 
        view 
        returns (address[] memory) 
    {
        return allUsers;
    }

    // ======== User Group Management ========
    function createUserGroup(string memory _name, string memory _description) 
        external 
        onlyAdmin 
        returns (bytes32) 
    {
        return _createUserGroup(_name, _description);
    }
    
    function _createUserGroup(string memory _name, string memory _description) 
        private 
        returns (bytes32) 
    {
        bytes32 groupId = keccak256(abi.encodePacked("GROUP", userGroupCounter++, block.timestamp));
        
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
    
    function updateUserGroup(bytes32 _groupId, string memory _name, string memory _description) 
        external 
        onlyAdmin 
        userGroupExists(_groupId) 
        returns (bool) 
    {
        userGroups[_groupId].name = _name;
        userGroups[_groupId].description = _description;
        
        emit UserGroupUpdated(_groupId, _name);
        return true;
    }
    
    function removeUserGroup(bytes32 _groupId) 
        external 
        onlyAdmin 
        userGroupExists(_groupId) 
        returns (bool) 
    {
        // Remove all users from this group
        address[] memory groupUsersList = Set.Members(groupUsers[_groupId]);
        for (uint i = 0; i < groupUsersList.length; i++) {
            _removeUserFromGroup(groupUsersList[i], _groupId);
        }
        
        // Mark group as inactive
        userGroups[_groupId].active = false;
        
        emit UserGroupRemoved(_groupId);
        return true;
    }
    
    function addUserToGroup(address _userAddress, bytes32 _groupId) 
        external 
        onlyAdmin 
        userExists(_userAddress) 
        userGroupExists(_groupId) 
        returns (bool) 
    {
        return _addUserToGroup(_userAddress, _groupId);
    }
    
    function _addUserToGroup(address _userAddress, bytes32 _groupId) 
        private 
        returns (bool) 
    {
        // Add group to user's groups
        Set.Add(users[_userAddress].groups, address(uint160(uint256(_groupId))));
        
        // Add user to group's users
        Set.Add(groupUsers[_groupId], _userAddress);
        
        emit UserAddedToGroup(_userAddress, _groupId);
        return true;
    }
    
    function removeUserFromGroup(address _userAddress, bytes32 _groupId) 
        external 
        onlyAdmin 
        userExists(_userAddress) 
        userGroupExists(_groupId) 
        returns (bool) 
    {
        return _removeUserFromGroup(_userAddress, _groupId);
    }
    
    function _removeUserFromGroup(address _userAddress, bytes32 _groupId) 
        private 
        returns (bool) 
    {
        // Remove group from user's groups
        Set.Remove(users[_userAddress].groups, address(uint160(uint256(_groupId))));
        
        // Remove user from group's users
        Set.Remove(groupUsers[_groupId], _userAddress);
        
        emit UserRemovedFromGroup(_userAddress, _groupId);
        return true;
    }
    
    function getUserGroup(bytes32 _groupId) 
        external 
        view 
        userGroupExists(_groupId) 
        returns (
            bytes32 id,
            string memory name,
            string memory description,
            uint256 createdAt,
            address createdBy,
            bool active
        ) 
    {
        UserGroup storage group = userGroups[_groupId];
        return (
            group.id,
            group.name,
            group.description,
            group.createdAt,
            group.createdBy,
            group.active
        );
    }
    
    function getGroupUsers(bytes32 _groupId) 
        external 
        view 
        userGroupExists(_groupId) 
        returns (address[] memory) 
    {
        return Set.Members(groupUsers[_groupId]);
    }
    
    function getAllUserGroups() 
        external 
        view 
        returns (bytes32[] memory) 
    {
        return allUserGroups;
    }

    // ======== Device Management ========
    function createDevice(
        address _deviceId,
        string memory _name, 
        string memory _description, 
        string memory _deviceType,
        string memory _location
    ) 
        external 
        userExists(msg.sender) 
        returns (address) 
    {
        require(_deviceId != address(0), "Invalid device address");
        require(!devices[_deviceId].active, "Device already exists");
        
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
    ) 
        external 
        deviceExists(_deviceId)
        onlyDeviceOwner(_deviceId)
        returns (bool) 
    {
        Device storage device = devices[_deviceId];
        
        device.name = _name;
        device.description = _description;
        device.deviceType = _deviceType;
        device.location = _location;
        
        emit DeviceUpdated(_deviceId, _name);
        return true;
    }
    
    function updateDeviceLastSeen(address _deviceId) 
        external 
        deviceExists(_deviceId)
        returns (bool) 
    {
        require(
            devices[_deviceId].owner == msg.sender || 
            users[msg.sender].isAdmin || 
            msg.sender == operator,
            "Unauthorized"
        );
        
        devices[_deviceId].lastSeen = block.timestamp;
        return true;
    }
    
    function transferDeviceOwnership(address _deviceId, address _newOwner) 
        external 
        deviceExists(_deviceId)
        onlyDeviceOwner(_deviceId)
        userExists(_newOwner)
        returns (bool) 
    {
        address currentOwner = devices[_deviceId].owner;
        
        // Remove device from current owner's devices
        Set.Remove(userDevices[currentOwner], _deviceId);
        
        // Add device to new owner's devices
        Set.Add(userDevices[_newOwner], _deviceId);
        
        // Update device owner
        devices[_deviceId].owner = _newOwner;
        
        return true;
    }
    
    function removeDevice(address _deviceId) 
        external 
        deviceExists(_deviceId)
        onlyDeviceOwner(_deviceId)
        returns (bool) 
    {
        // Remove device from all tags
        address[] memory deviceTagsList = Set.Members(devices[_deviceId].tags);
        for (uint i = 0; i < deviceTagsList.length; i++) {
            bytes32 tagId = bytes32(uint256(uint160(deviceTagsList[i])));
            _removeDeviceFromTag(_deviceId, tagId);
        }
        
        // Remove device from owner's devices
        Set.Remove(userDevices[devices[_deviceId].owner], _deviceId);
        
        // Remove device from allDevices
        for (uint i = 0; i < allDevices.length; i++) {
            if (allDevices[i] == _deviceId) {
                allDevices[i] = allDevices[allDevices.length - 1];
                allDevices.pop();
                break;
            }
        }
        
        // Mark device as inactive
        devices[_deviceId].active = false;
        
        emit DeviceRemoved(_deviceId);
        return true;
    }
    
    function getDevice(address _deviceId) 
        external 
        view 
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
    
    function getUserDevices(address _userAddress) 
        external 
        view 
        userExists(_userAddress)
        returns (address[] memory) 
    {
        return Set.Members(userDevices[_userAddress]);
    }
    
    function getAllDevices() 
        external 
        view 
        returns (address[] memory) 
    {
        return allDevices;
    }

    // ======== Tag Management ========
    function createTag(string memory _name, string memory _description, string memory _color) 
        external 
        onlyAdmin 
        returns (bytes32) 
    {
        bytes32 tagId = keccak256(abi.encodePacked("TAG", tagCounter++, block.timestamp));
        
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
    
    function updateTag(bytes32 _tagId, string memory _name, string memory _description, string memory _color) 
        external 
        onlyAdmin 
        tagExists(_tagId) 
        returns (bool) 
    {
        tags[_tagId].name = _name;
        tags[_tagId].description = _description;
        tags[_tagId].color = _color;
        
        emit TagUpdated(_tagId, _name);
        return true;
    }
    
    function removeTag(bytes32 _tagId) 
        external 
        onlyAdmin 
        tagExists(_tagId) 
        returns (bool) 
    {
        // Remove all devices from this tag
        address[] memory tagDevicesList = Set.Members(tagDevices[_tagId]);
        for (uint i = 0; i < tagDevicesList.length; i++) {
            bytes32 deviceId = bytes32(uint256(uint160(tagDevicesList[i])));
            _removeDeviceFromTag(address(uint160(uint256(deviceId))), _tagId);
        }
        
        // Mark tag as inactive
        tags[_tagId].active = false;
        
        emit TagRemoved(_tagId);
        return true;
    }
    
    function addDeviceToTag(address _deviceId, bytes32 _tagId) 
        external 
        deviceExists(_deviceId)
        tagExists(_tagId)
        returns (bool) 
    {
        require(
            devices[_deviceId].owner == msg.sender || 
            users[msg.sender].isAdmin,
            "Only device owner or admin can add device to tag"
        );
        
        return _addDeviceToTag(_deviceId, _tagId);
    }
    
    function _addDeviceToTag(address _deviceId, bytes32 _tagId) 
        private 
        returns (bool) 
    {
        // Add tag to device's tags
        Set.Add(devices[_deviceId].tags, address(uint160(uint256(_tagId) & ((1 << 160) - 1))));
        
        // Add device to tag's devices
        Set.Add(tagDevices[_tagId], _deviceId);
        
        emit DeviceAddedToTag(_deviceId, _tagId);
        return true;
    }
    
    function removeDeviceFromTag(address _deviceId, bytes32 _tagId) 
        external 
        deviceExists(_deviceId)
        tagExists(_tagId)
        returns (bool) 
    {
        require(
            devices[_deviceId].owner == msg.sender || 
            users[msg.sender].isAdmin,
            "Only device owner or admin can remove device from tag"
        );
        
        return _removeDeviceFromTag(_deviceId, _tagId);
    }
    
    function _removeDeviceFromTag(address _deviceId, bytes32 _tagId) 
        private 
        returns (bool) 
    {
        // Remove tag from device's tags
        Set.Remove(devices[_deviceId].tags, address(uint160(uint256(_tagId))));
        
        // Remove device from tag's devices
        Set.Remove(tagDevices[_tagId], _deviceId);
        
        emit DeviceRemovedFromTag(_deviceId, _tagId);
        return true;
    }
    
    function getDeviceTags(address _deviceId) 
        external 
        view 
        deviceExists(_deviceId)
        returns (bytes32[] memory) 
    {
        address[] memory tagAddresses = Set.Members(devices[_deviceId].tags);
        bytes32[] memory result = new bytes32[](tagAddresses.length);
        
        for (uint i = 0; i < tagAddresses.length; i++) {
            result[i] = bytes32(uint256(uint160(tagAddresses[i])) & ((1 << 160) - 1));
        }
        
        return result;
    }
    
    function getTagDevices(bytes32 _tagId) 
        external 
        view 
        tagExists(_tagId)
        returns (address[] memory) 
    {
        return Set.Members(tagDevices[_tagId]);
    }
    
    function isDeviceInTag(address _deviceId, bytes32 _tagId) 
        external 
        view 
        returns (bool) 
    {
        if (!devices[_deviceId].active || !tags[_tagId].active) {
            return false;
        }
        
        // Check if tag is in device's tags
        bool deviceHasTag = Set.IsMember(devices[_deviceId].tags, address(uint160(uint256(_tagId))));
        
        // Check if device is in tag's devices
        bool tagHasDevice = Set.IsMember(tagDevices[_tagId], _deviceId);
        
        // Both relationships must exist
        return deviceHasTag && tagHasDevice;
    }
    
    function isDeviceOwner(address _userAddress, address _deviceId) 
        external 
        view 
        returns (bool) 
    {
        return devices[_deviceId].active && devices[_deviceId].owner == _userAddress;
    }

    // ======== Access Control ========
    function isUserInGroup(address _userAddress, bytes32 _groupId) 
        external 
        view 
        returns (bool) 
    {
        if (!users[_userAddress].active || !userGroups[_groupId].active) {
            return false;
        }
        
        return Set.IsMember(users[_userAddress].groups, address(uint160(uint256(_groupId))));
    }
    
    function isUserAdmin(address _userAddress) 
        external 
        view 
        returns (bool) 
    {
        return users[_userAddress].active && users[_userAddress].isAdmin;
    }

    // ======== Property Management ========
    function setDeviceProperty(address _deviceId, string memory _key, string memory _value) 
        external 
        onlyDeviceOwner(_deviceId)
        returns (bool) 
    {
        deviceProperties[_deviceId][_key] = _value;
        emit DevicePropertySet(_deviceId, _key, _value);
        return true;
    }
    
    function getDeviceProperty(address _deviceId, string memory _key) 
        external 
        view 
        returns (string memory) 
    {
        return deviceProperties[_deviceId][_key];
    }
    
    function setTagProperty(bytes32 _tagId, string memory _key, string memory _value) 
        external 
        onlyAdmin
        returns (bool) 
    {
        tagProperties[_tagId][_key] = _value;
        emit TagPropertySet(_tagId, _key, _value);
        return true;
    }
    
    function getTagProperty(bytes32 _tagId, string memory _key) 
        external 
        view 
        returns (string memory) 
    {
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
        if (bytes(deviceValue).length > 0) {
            return deviceValue;
        }
        
        // Then check tag properties
        address[] memory deviceTagsList = Set.Members(devices[_deviceId].tags);
        if (deviceTagsList.length > 0) {
            for (uint i = 0; i < deviceTagsList.length; i++) {
                bytes32 tagId = bytes32(uint256(uint160(deviceTagsList[i])) & ((1 << 160) - 1));
                
                // Get the tag property
                string memory tagValue = tagProperties[tagId][_key];
                if (bytes(tagValue).length > 0) {
                    return tagValue;
                }
            }
        }
        
        // If no property found, return an empty string
        return "";
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
    
    // Check if a device or any of its tags has a property
    function hasProperty(address _deviceId, string memory _key)
        external
        view
        deviceExists(_deviceId)
        returns (bool)
    {
        // First check tag properties
        address[] memory deviceTagsList = Set.Members(devices[_deviceId].tags);
        for (uint i = 0; i < deviceTagsList.length; i++) {
            bytes32 tagId = bytes32(uint256(uint160(deviceTagsList[i])));
            
            // Skip inactive tags
            if (!tags[tagId].active) {
                continue;
            }
            
            // Check if device is in this tag
            if (Set.IsMember(devices[_deviceId].tags, address(uint160(uint256(tagId))))) {
                // Get the tag property
                if (bytes(tagProperties[tagId][_key]).length > 0) {
                    return true;
                }
            }
        }
        
        // Then check device properties
        if (bytes(deviceProperties[_deviceId][_key]).length > 0) {
            return true;
        }
        
        return false;
    }

    function getAllTags() 
        external 
        view 
        returns (bytes32[] memory) 
    {
        return allTags;
    }

    function getTag(bytes32 _tagId) 
        external 
        view 
        tagExists(_tagId)
        returns (
            bytes32 id,
            string memory name,
            string memory description,
            string memory color,
            uint256 createdAt,
            address createdBy,
            bool active
        ) 
    {
        Tag storage tag = tags[_tagId];
        return (
            tag.id,
            tag.name,
            tag.description,
            tag.color,
            tag.createdAt,
            tag.createdBy,
            tag.active
        );
    }
}