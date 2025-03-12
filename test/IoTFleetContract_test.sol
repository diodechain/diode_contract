// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;

import "./Assert.sol";
import "../contracts/IoTFleetContract.sol";

contract IoTFleetContractTest {
    IoTFleetContract private fleetContract;
    address private contractOwner;
    address private user1;
    address private user2;
    address private user3;

    // Setup function to initialize the contract and test accounts
    function beforeEach() public {
        contractOwner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        
        fleetContract = new IoTFleetContract();
    }

    // ======== User Management Tests ========
    function testCreateUser() public {
        beforeEach();
        
        // Create a new user
        bool success = fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        Assert.equal(success, true, "User creation should succeed");
        
        // Verify user data
        (
            address userAddr,
            string memory nickname,
            string memory email,
            string memory avatarURI,
            bool isAdmin,
            uint256 createdAt,
            uint256 lastLogin,
            bool active
        ) = fleetContract.getUser(user1);
        
        Assert.equal(userAddr, user1, "User address should match");
        Assert.equal(nickname, "User One", "User nickname should match");
        Assert.equal(email, "user1@example.com", "User email should match");
        Assert.equal(avatarURI, "avatar1.png", "User avatar URI should match");
        Assert.equal(isAdmin, false, "User should not be admin by default");
        Assert.equal(active, true, "User should be active");
    }
    
    function testUpdateUser() public {
        beforeEach();
        
        // Create a user first
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Update user
        bool success = fleetContract.updateUser(user1, "Updated User", "updated@example.com", "updated.png");
        Assert.equal(success, true, "User update should succeed");
        
        // Verify updated data
        (
            ,
            string memory nickname,
            string memory email,
            string memory avatarURI,
            ,
            ,
            ,
            
        ) = fleetContract.getUser(user1);
        
        Assert.equal(nickname, "Updated User", "User nickname should be updated");
        Assert.equal(email, "updated@example.com", "User email should be updated");
        Assert.equal(avatarURI, "updated.png", "User avatar URI should be updated");
    }
    
    function testSetUserAdmin() public {
        beforeEach();
        
        // Create a user first
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Set user as admin
        bool success = fleetContract.setUserAdmin(user1, true);
        Assert.equal(success, true, "Setting user as admin should succeed");
        
        // Verify admin status
        (
            ,
            ,
            ,
            ,
            bool isAdmin,
            ,
            ,
            
        ) = fleetContract.getUser(user1);
        
        Assert.equal(isAdmin, true, "User should be admin");
        Assert.equal(fleetContract.isUserAdmin(user1), true, "isUserAdmin should return true");
    }
    
    function testRemoveUser() public {
        beforeEach();
        
        // Create a user first
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Remove user
        bool success = fleetContract.removeUser(user1);
        Assert.equal(success, true, "User removal should succeed");
        
        // Verify user is inactive
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool active
        ) = fleetContract.getUser(user1);
        
        Assert.equal(active, false, "User should be inactive after removal");
    }
    
    function testRecordUserLogin() public {
        beforeEach();
        
        // Create a user first
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Get initial login time
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 initialLogin,
            
        ) = fleetContract.getUser(user1);
        
        // Wait a moment
        uint256 waitTime = 1;
        
        // Record login
        bool success = fleetContract.recordUserLogin(user1);
        Assert.equal(success, true, "Recording user login should succeed");
        
        // Verify login time updated
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 updatedLogin,
            
        ) = fleetContract.getUser(user1);
        
        Assert.ok(updatedLogin >= initialLogin, "Login time should be updated");
    }
    
    function testGetAllUsers() public {
        beforeEach();
        
        // Create multiple users
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        fleetContract.createUser(user2, "User Two", "user2@example.com", "avatar2.png");
        
        // Get all users
        address[] memory allUsers = fleetContract.getAllUsers();
        
        // Owner is automatically added as admin in constructor, plus our two new users
        Assert.equal(allUsers.length, 3, "Should have 3 users (owner + 2 created)");
    }

    // ======== User Group Management Tests ========
    function testCreateUserGroup() public {
        beforeEach();
        
        // Create a user group
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Verify group data
        (
            bytes32 id,
            string memory name,
            string memory description,
            ,
            ,
            bool active
        ) = fleetContract.getUserGroup(groupId);
        
        Assert.equal(id, groupId, "Group ID should match");
        Assert.equal(name, "Test Group", "Group name should match");
        Assert.equal(description, "A test group", "Group description should match");
        Assert.equal(active, true, "Group should be active");
    }
    
    function testUpdateUserGroup() public {
        beforeEach();
        
        // Create a user group first
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Update group
        bool success = fleetContract.updateUserGroup(groupId, "Updated Group", "Updated description");
        Assert.equal(success, true, "Group update should succeed");
        
        // Verify updated data
        (
            ,
            string memory name,
            string memory description,
            ,
            ,
            
        ) = fleetContract.getUserGroup(groupId);
        
        Assert.equal(name, "Updated Group", "Group name should be updated");
        Assert.equal(description, "Updated description", "Group description should be updated");
    }
    
    function testAddUserToGroup() public {
        beforeEach();
        
        // Create a user first
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a user group
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Add user to group
        bool success = fleetContract.addUserToGroup(user1, groupId);
        Assert.equal(success, true, "Adding user to group should succeed");
        
        // Verify user is in group
        bool isInGroup = fleetContract.isUserInGroup(user1, groupId);
        Assert.equal(isInGroup, true, "User should be in group");
        
        // Get user's groups
        bytes32[] memory userGroups = fleetContract.getUserGroups(user1);
        Assert.ok(userGroups.length > 0, "User should have at least one group");
        
        // Get group's users
        address[] memory groupUsers = fleetContract.getGroupUsers(groupId);
        Assert.ok(groupUsers.length > 0, "Group should have at least one user");
    }
    
    function testRemoveUserFromGroup() public {
        beforeEach();
        
        // Create a user first
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a user group
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Add user to group
        fleetContract.addUserToGroup(user1, groupId);
        
        // Remove user from group
        bool success = fleetContract.removeUserFromGroup(user1, groupId);
        Assert.equal(success, true, "Removing user from group should succeed");
        
        // Verify user is not in group
        Assert.equal(fleetContract.isUserInGroup(user1, groupId), false, "User should not be in group");
        
        // Get user's groups
        bytes32[] memory userGroups = fleetContract.getUserGroups(user1);
        Assert.equal(userGroups.length, 0, "User should not be in any groups");
        
        // Get group's users
        address[] memory groupUsers = fleetContract.getGroupUsers(groupId);
        Assert.equal(groupUsers.length, 0, "Group should not have any users");
    }
    
    function testGetAllUserGroups() public {
        beforeEach();
        
        // Create multiple groups
        fleetContract.createUserGroup("Group One", "First group");
        fleetContract.createUserGroup("Group Two", "Second group");
        
        // Get all groups
        bytes32[] memory allGroups = fleetContract.getAllUserGroups();
        
        // Admin group is automatically created in constructor, plus our two new groups
        Assert.equal(allGroups.length, 3, "Should have 3 groups (admin + 2 created)");
    }

    // ======== Device Management Tests ========
    function testCreateDevice() public {
        beforeEach();
        
        // Create a user first (owner is already a user from constructor)
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Verify device data
        (
            bytes32 id,
            address owner,
            string memory name,
            string memory description,
            string memory deviceType,
            string memory location,
            string memory ipAddress,
            string memory macAddress,
            ,
            ,
            bool active
        ) = fleetContract.getDevice(deviceId);
        
        Assert.equal(id, deviceId, "Device ID should match");
        Assert.equal(owner, address(this), "Device owner should match");
        Assert.equal(name, "Test Device", "Device name should match");
        Assert.equal(description, "A test device", "Device description should match");
        Assert.equal(deviceType, "sensor", "Device type should match");
        Assert.equal(location, "Room 101", "Device location should match");
        Assert.equal(ipAddress, "192.168.1.100", "Device IP address should match");
        Assert.equal(macAddress, "00:11:22:33:44:55", "Device MAC address should match");
        Assert.equal(active, true, "Device should be active");
    }
    
    function testUpdateDevice() public {
        beforeEach();
        
        // Create a device first
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Update device
        bool success = fleetContract.updateDevice(
            deviceId,
            "Updated Device", 
            "Updated description", 
            "gateway",
            "Room 102",
            "192.168.1.101",
            "AA:BB:CC:DD:EE:FF"
        );
        Assert.equal(success, true, "Device update should succeed");
        
        // Verify updated data
        (
            ,
            ,
            string memory name,
            string memory description,
            string memory deviceType,
            string memory location,
            string memory ipAddress,
            string memory macAddress,
            ,
            ,
            
        ) = fleetContract.getDevice(deviceId);
        
        Assert.equal(name, "Updated Device", "Device name should be updated");
        Assert.equal(description, "Updated description", "Device description should be updated");
        Assert.equal(deviceType, "gateway", "Device type should be updated");
        Assert.equal(location, "Room 102", "Device location should be updated");
        Assert.equal(ipAddress, "192.168.1.101", "Device IP address should be updated");
        Assert.equal(macAddress, "AA:BB:CC:DD:EE:FF", "Device MAC address should be updated");
    }
    
    function testUpdateDeviceLastSeen() public {
        beforeEach();
        
        // Create a device first
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Get initial last seen time
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 initialLastSeen,
            
        ) = fleetContract.getDevice(deviceId);
        
        // Wait a moment
        uint256 waitTime = 1;
        
        // Update last seen
        bool success = fleetContract.updateDeviceLastSeen(deviceId);
        Assert.equal(success, true, "Updating device last seen should succeed");
        
        // Verify last seen updated
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 updatedLastSeen,
            
        ) = fleetContract.getDevice(deviceId);
        
        Assert.ok(updatedLastSeen >= initialLastSeen, "Last seen time should be updated");
    }
    
    function testTransferDeviceOwnership() public {
        beforeEach();
        
        // Create users
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Transfer ownership
        bool success = fleetContract.transferDeviceOwnership(deviceId, user1);
        Assert.equal(success, true, "Device ownership transfer should succeed");
        
        // Verify new owner
        (
            ,
            address owner,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            
        ) = fleetContract.getDevice(deviceId);
        
        Assert.equal(owner, user1, "Device owner should be updated");
        Assert.equal(fleetContract.isDeviceOwner(user1, deviceId), true, "isDeviceOwner should return true for new owner");
        Assert.equal(fleetContract.isDeviceOwner(address(this), deviceId), false, "isDeviceOwner should return false for old owner");
    }
    
    function testGetUserDevices() public {
        beforeEach();
        
        // Create multiple devices
        bytes32 deviceId1 = fleetContract.createDevice(
            "Device One", 
            "First device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        bytes32 deviceId2 = fleetContract.createDevice(
            "Device Two", 
            "Second device", 
            "gateway",
            "Room 102",
            "192.168.1.101",
            "AA:BB:CC:DD:EE:FF"
        );
        
        // Get user's devices
        bytes32[] memory userDevices = fleetContract.getUserDevices(address(this));
        
        Assert.equal(userDevices.length, 2, "User should have 2 devices");
    }
    
    function testGetAllDevices() public {
        beforeEach();
        
        // Create multiple devices
        fleetContract.createDevice(
            "Device One", 
            "First device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        fleetContract.createDevice(
            "Device Two", 
            "Second device", 
            "gateway",
            "Room 102",
            "192.168.1.101",
            "AA:BB:CC:DD:EE:FF"
        );
        
        // Get all devices
        bytes32[] memory allDevices = fleetContract.getAllDevices();
        
        Assert.equal(allDevices.length, 2, "Should have 2 devices");
    }

    // ======== Tag Management Tests ========
    function testCreateTag() public {
        beforeEach();
        
        // Create a tag
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Verify tag data
        (
            bytes32 id,
            string memory name,
            string memory description,
            string memory color,
            ,
            ,
            bool active
        ) = fleetContract.getTag(tagId);
        
        Assert.equal(id, tagId, "Tag ID should match");
        Assert.equal(name, "Test Tag", "Tag name should match");
        Assert.equal(description, "A test tag", "Tag description should match");
        Assert.equal(color, "#FF0000", "Tag color should match");
        Assert.equal(active, true, "Tag should be active");
    }
    
    function testUpdateTag() public {
        beforeEach();
        
        // Create a tag first
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Update tag
        bool success = fleetContract.updateTag(tagId, "Updated Tag", "Updated description", "#00FF00");
        Assert.equal(success, true, "Tag update should succeed");
        
        // Verify updated data
        (
            ,
            string memory name,
            string memory description,
            string memory color,
            ,
            ,
            
        ) = fleetContract.getTag(tagId);
        
        Assert.equal(name, "Updated Tag", "Tag name should be updated");
        Assert.equal(description, "Updated description", "Tag description should be updated");
        Assert.equal(color, "#00FF00", "Tag color should be updated");
    }
    
    function testAddDeviceToTag() public {
        beforeEach();
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Create a tag
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Add device to tag
        bool success = fleetContract.addDeviceToTag(deviceId, tagId);
        Assert.equal(success, true, "Adding device to tag should succeed");
        
        // Verify device is in tag
        bool isInTag = fleetContract.isDeviceInTag(deviceId, tagId);
        Assert.equal(isInTag, true, "Device should be in tag");
        
        // Get device's tags
        bytes32[] memory deviceTags = fleetContract.getDeviceTags(deviceId);
        Assert.ok(deviceTags.length > 0, "Device should have at least one tag");
        
        // Get tag's devices
        bytes32[] memory tagDevices = fleetContract.getTagDevices(tagId);
        Assert.ok(tagDevices.length > 0, "Tag should have at least one device");
    }
    
    function testRemoveDeviceFromTag() public {
        beforeEach();
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Create a tag
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Add device to tag
        fleetContract.addDeviceToTag(deviceId, tagId);
        
        // Remove device from tag
        bool success = fleetContract.removeDeviceFromTag(deviceId, tagId);
        Assert.equal(success, true, "Removing device from tag should succeed");
        
        // Verify device is not in tag
        Assert.equal(fleetContract.isDeviceInTag(deviceId, tagId), false, "Device should not be in tag");
        
        // Get device's tags
        bytes32[] memory deviceTags = fleetContract.getDeviceTags(deviceId);
        Assert.equal(deviceTags.length, 0, "Device should not have any tags");
        
        // Get tag's devices
        bytes32[] memory tagDevices = fleetContract.getTagDevices(tagId);
        Assert.equal(tagDevices.length, 0, "Tag should not have any devices");
    }
    
    function testGetAllTags() public {
        beforeEach();
        
        // Create multiple tags
        fleetContract.createTag("Tag One", "First tag", "#FF0000");
        fleetContract.createTag("Tag Two", "Second tag", "#00FF00");
        
        // Get all tags
        bytes32[] memory allTags = fleetContract.getAllTags();
        
        Assert.equal(allTags.length, 2, "Should have 2 tags");
    }

    // ======== Access Control Tests ========
    function testIsUserInGroup() public {
        beforeEach();
        
        // Create a user
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a user group
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Check user is not in group initially
        Assert.equal(fleetContract.isUserInGroup(user1, groupId), false, "User should not be in group initially");
        
        // Add user to group
        fleetContract.addUserToGroup(user1, groupId);
        
        // Check user is in group
        Assert.equal(fleetContract.isUserInGroup(user1, groupId), true, "User should be in group after adding");
    }
    
    function testIsDeviceInTag() public {
        beforeEach();
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Create a tag
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Check device is not in tag initially
        Assert.equal(fleetContract.isDeviceInTag(deviceId, tagId), false, "Device should not be in tag initially");
        
        // Add device to tag
        fleetContract.addDeviceToTag(deviceId, tagId);
        
        // Check device is in tag
        Assert.equal(fleetContract.isDeviceInTag(deviceId, tagId), true, "Device should be in tag after adding");
    }
    
    function testIsUserAdmin() public {
        beforeEach();
        
        // Create a user
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Verify user is not admin initially
        bool isAdminInitially = fleetContract.isUserAdmin(user1);
        Assert.equal(isAdminInitially, false, "User should not be admin initially");
        
        // Set user as admin
        fleetContract.setUserAdmin(user1, true);
        
        // Check user is admin after setting
        bool isAdminAfterSetting = fleetContract.isUserAdmin(user1);
        Assert.equal(isAdminAfterSetting, true, "User should be admin after setting");
    }
    
    function testIsDeviceOwner() public {
        beforeEach();
        
        // Create users
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Check ownership
        Assert.equal(fleetContract.isDeviceOwner(address(this), deviceId), true, "Contract should be device owner initially");
        Assert.equal(fleetContract.isDeviceOwner(user1, deviceId), false, "User1 should not be device owner initially");
        
        // Transfer ownership
        fleetContract.transferDeviceOwnership(deviceId, user1);
        
        // Check ownership after transfer
        Assert.equal(fleetContract.isDeviceOwner(address(this), deviceId), false, "Contract should not be device owner after transfer");
        Assert.equal(fleetContract.isDeviceOwner(user1, deviceId), true, "User1 should be device owner after transfer");
    }

    // Fix the shadowing issues in the getDevice function
    function testGetDevice() public {
        beforeEach();
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Verify device data
        (
            bytes32 id,
            address deviceOwner,
            string memory name,
            string memory description,
            string memory deviceType,
            string memory location,
            string memory ipAddress,
            string memory macAddress,
            ,
            ,
            bool active
        ) = fleetContract.getDevice(deviceId);
        
        Assert.equal(id, deviceId, "Device ID should match");
        Assert.equal(deviceOwner, address(this), "Device owner should match");
        Assert.equal(name, "Test Device", "Device name should match");
        Assert.equal(description, "A test device", "Device description should match");
        Assert.equal(deviceType, "sensor", "Device type should match");
        Assert.equal(location, "Room 101", "Device location should match");
        Assert.equal(ipAddress, "192.168.1.100", "Device IP address should match");
        Assert.equal(macAddress, "00:11:22:33:44:55", "Device MAC address should match");
        Assert.equal(active, true, "Device should be active");
    }

    // Debug test for user group functionality
    function testDebugUserGroup() public {
        beforeEach();
        
        // Create a user
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a user group
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Add user to group
        bool success = fleetContract.addUserToGroup(user1, groupId);
        Assert.equal(success, true, "Adding user to group should succeed");
        
        // Check if user is in group
        bool isInGroup = fleetContract.isUserInGroup(user1, groupId);
        Assert.equal(isInGroup, true, "User should be in group");
        
        // Get user's groups
        bytes32[] memory userGroups = fleetContract.getUserGroups(user1);
        Assert.ok(userGroups.length > 0, "User should have at least one group");
    }

    // Debug test for device tag functionality
    function testDebugDeviceTag() public {
        beforeEach();
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Create a tag
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Add device to tag
        bool success = fleetContract.addDeviceToTag(deviceId, tagId);
        Assert.equal(success, true, "Adding device to tag should succeed");
        
        // Check if device is in tag
        bool isInTag = fleetContract.isDeviceInTag(deviceId, tagId);
        Assert.equal(isInTag, true, "Device should be in tag");
        
        // Get device's tags
        bytes32[] memory deviceTags = fleetContract.getDeviceTags(deviceId);
        Assert.ok(deviceTags.length > 0, "Device should have at least one tag");
    }

    // Test device removal behavior
    function testDeviceRemovalBehavior() public {
        beforeEach();
        
        // Create a device owned by the test contract
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Create a tag and add device to it
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        fleetContract.addDeviceToTag(deviceId, tagId);
        
        // Verify device is in tag
        bool isInTag = fleetContract.isDeviceInTag(deviceId, tagId);
        Assert.equal(isInTag, true, "Device should be in tag");
        
        // Get device's owner
        (
            ,
            address deviceOwner,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            
        ) = fleetContract.getDevice(deviceId);
        
        Assert.equal(deviceOwner, address(this), "Device owner should be the test contract");
        
        // Get user's devices before removal
        bytes32[] memory userDevicesBefore = fleetContract.getUserDevices(address(this));
        uint256 deviceCountBefore = userDevicesBefore.length;
        
        // Remove device
        bool success = fleetContract.removeDevice(deviceId);
        Assert.equal(success, true, "Device removal should succeed");
        
        // Get user's devices after removal
        bytes32[] memory userDevicesAfter = fleetContract.getUserDevices(address(this));
        uint256 deviceCountAfter = userDevicesAfter.length;
        
        // Verify device count decreased
        Assert.equal(deviceCountAfter, deviceCountBefore - 1, "Device count should decrease by 1");
        
        // Verify device is not in tag
        isInTag = fleetContract.isDeviceInTag(deviceId, tagId);
        Assert.equal(isInTag, false, "Device should not be in tag after removal");
    }
    
    // Test tag removal behavior
    function testTagRemovalBehavior() public {
        beforeEach();
        
        // Create a device
        bytes32 deviceId = fleetContract.createDevice(
            "Test Device", 
            "A test device", 
            "sensor",
            "Room 101",
            "192.168.1.100",
            "00:11:22:33:44:55"
        );
        
        // Create a tag
        bytes32 tagId = fleetContract.createTag("Test Tag", "A test tag", "#FF0000");
        
        // Add device to tag
        fleetContract.addDeviceToTag(deviceId, tagId);
        
        // Verify device is in tag
        bool isInTag = fleetContract.isDeviceInTag(deviceId, tagId);
        Assert.equal(isInTag, true, "Device should be in tag");
        
        // Get all tags before removal
        bytes32[] memory allTagsBefore = fleetContract.getAllTags();
        uint256 tagCountBefore = allTagsBefore.length;
        
        // Remove tag
        bool success = fleetContract.removeTag(tagId);
        Assert.equal(success, true, "Tag removal should succeed");
        
        // Get all tags after removal
        bytes32[] memory allTagsAfter = fleetContract.getAllTags();
        uint256 tagCountAfter = allTagsAfter.length;
        
        // Verify tag count remains the same (we only mark as inactive)
        Assert.equal(tagCountAfter, tagCountBefore, "Tag count should remain the same");
        
        // Verify device is not in tag
        isInTag = fleetContract.isDeviceInTag(deviceId, tagId);
        Assert.equal(isInTag, false, "Device should not be in inactive tag");
    }
    
    // Test user group removal behavior
    function testUserGroupRemovalBehavior() public {
        beforeEach();
        
        // Create a user
        fleetContract.createUser(user1, "User One", "user1@example.com", "avatar1.png");
        
        // Create a user group
        bytes32 groupId = fleetContract.createUserGroup("Test Group", "A test group");
        
        // Add user to group
        fleetContract.addUserToGroup(user1, groupId);
        
        // Verify user is in group
        bool isInGroup = fleetContract.isUserInGroup(user1, groupId);
        Assert.equal(isInGroup, true, "User should be in group");
        
        // Get all user groups before removal
        bytes32[] memory allGroupsBefore = fleetContract.getAllUserGroups();
        uint256 groupCountBefore = allGroupsBefore.length;
        
        // Remove group
        bool success = fleetContract.removeUserGroup(groupId);
        Assert.equal(success, true, "Group removal should succeed");
        
        // Get all user groups after removal
        bytes32[] memory allGroupsAfter = fleetContract.getAllUserGroups();
        uint256 groupCountAfter = allGroupsAfter.length;
        
        // Verify group count remains the same (we only mark as inactive)
        Assert.equal(groupCountAfter, groupCountBefore, "Group count should remain the same");
        
        // Verify user is not in group
        isInGroup = fleetContract.isUserInGroup(user1, groupId);
        Assert.equal(isInGroup, false, "User should not be in inactive group");
    }
}
