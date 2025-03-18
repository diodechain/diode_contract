// Device management operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';
import * as fleetOperations from './fleet-operations.js';

// Load all devices in the fleet
export const loadDevices = async () => {
  try {
    setLoadingWithSafety(true);
    
    // Get all devices
    const deviceIds = await fleetOperations.getAllDevices(window.app.managedFleet);
    
    // Load device details
    window.devices = [];
    
    for (const deviceId of deviceIds) {
      try {
        const deviceData = await fleetOperations.getDevice(window.app.managedFleet, deviceId);
        
        window.devices.push({
          id: deviceData.id,
          owner: deviceData.owner,
          name: deviceData.name,
          description: deviceData.description,
          deviceType: deviceData.deviceType,
          location: deviceData.location,
          createdAt: new Date(deviceData.createdAt * 1000),
          lastSeen: new Date(deviceData.lastSeen * 1000),
          active: deviceData.active
        });
      } catch (error) {
        console.error(`Error loading device ${deviceId}:`, error);
      }
    }
  } catch (error) {
    console.error('Error loading devices:', error);
    showToastMessage('Failed to load devices: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Select a device for viewing/editing
export const selectDevice = (deviceId) => {
  const device = window.devices.find(d => d.id === deviceId);
  if (device) {
    window.selectedDevice = device;
    
    // Copy device data to form
    window.newDeviceData = {
      name: device.name,
      description: device.description,
      deviceType: device.deviceType,
      location: device.location,
      properties: {}
    };
    
    // Load device tags
    loadDeviceTags(deviceId);
  }
};

// Load tags for a device
export const loadDeviceTags = async (deviceId) => {
  try {
    setLoadingWithSafety(true);
    
    // Get device tags
    const tagIds = await fleetOperations.getDeviceTags(window.app.managedFleet, deviceId);
    
    // Load tag details
    window.deviceTags = [];
    
    for (const tagId of tagIds) {
      try {
        const tagData = await fleetOperations.getTag(window.app.managedFleet, tagId);
        
        window.deviceTags.push({
          id: tagData.id,
          name: tagData.name,
          description: tagData.description,
          color: tagData.color,
          createdAt: new Date(tagData.createdAt * 1000),
          createdBy: tagData.createdBy,
          active: tagData.active
        });
      } catch (error) {
        console.error(`Error loading tag ${tagId}:`, error);
      }
    }
  } catch (error) {
    console.error('Error loading device tags:', error);
    showToastMessage('Failed to load device tags: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Create a new device
export const createNewDevice = async () => {
  try {
    if (!window.newDeviceData.name) {
      showToastMessage('Please enter a device name');
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Create device
    const deviceId = await fleetOperations.createDevice(
      window.app.managedFleet,
      window.newDeviceData.name,
      window.newDeviceData.description || '',
      window.newDeviceData.deviceType || '',
      window.newDeviceData.location || ''
    );
    
    // Add properties if any
    if (window.newDeviceData.properties) {
      for (const [key, value] of Object.entries(window.newDeviceData.properties)) {
        if (key && value) {
          await fleetOperations.setDeviceProperty(window.app.managedFleet, deviceId, key, value);
        }
      }
    }
    
    // Refresh device list
    await loadDevices();
    
    // Reset form
    window.newDeviceData = { 
      name: '', 
      description: '', 
      deviceType: '', 
      location: '', 
      properties: {} 
    };
    
    showToastMessage('Device created successfully!');
  } catch (error) {
    console.error('Error creating device:', error);
    showToastMessage('Failed to create device: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Update device details
export const updateDeviceDetails = async () => {
  try {
    if (!window.selectedDevice) {
      showToastMessage('No device selected');
      return;
    }
    
    if (!window.newDeviceData.name) {
      showToastMessage('Please enter a device name');
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Update device
    await fleetOperations.updateDevice(
      window.app.managedFleet,
      window.selectedDevice.id,
      window.newDeviceData.name,
      window.newDeviceData.description || '',
      window.newDeviceData.deviceType || '',
      window.newDeviceData.location || ''
    );
    
    // Update properties if any
    if (window.newDeviceData.properties) {
      for (const [key, value] of Object.entries(window.newDeviceData.properties)) {
        if (key && value) {
          await fleetOperations.setDeviceProperty(window.app.managedFleet, window.selectedDevice.id, key, value);
        }
      }
    }
    
    // Refresh device list
    await loadDevices();
    
    // Reset selection
    window.selectedDevice = null;
    window.newDeviceData = { 
      name: '', 
      description: '', 
      deviceType: '', 
      location: '', 
      properties: {} 
    };
    window.deviceTags = [];
    
    showToastMessage('Device updated successfully!');
  } catch (error) {
    console.error('Error updating device:', error);
    showToastMessage('Failed to update device: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Update device last seen timestamp
export const updateDeviceLastSeen = async (deviceId) => {
  try {
    setLoadingWithSafety(true);
    await fleetOperations.updateDeviceLastSeen(window.app.managedFleet, deviceId);
    await loadDevices();
    showToastMessage('Device last seen updated successfully!');
  } catch (error) {
    console.error('Error updating device last seen:', error);
    showToastMessage('Failed to update device last seen: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Show device transfer dialog
export const transferDeviceDialog = (deviceId) => {
  const device = window.devices.find(d => d.id === deviceId);
  if (device) {
    window.selectedDevice = device;
    window.newDeviceOwner = '';
    window.showDeviceTransferModal = true;
  }
};

// Transfer device ownership
export const transferDevice = async () => {
  try {
    if (!window.selectedDevice) {
      showToastMessage('No device selected');
      return;
    }
    
    if (!window.isValidAddress(window.newDeviceOwner)) {
      showToastMessage('Please enter a valid Ethereum address');
      return;
    }
    
    setLoadingWithSafety(true);
    
    await fleetOperations.transferDeviceOwnership(
      window.app.managedFleet,
      window.selectedDevice.id,
      window.newDeviceOwner
    );
    
    // Refresh device list
    await loadDevices();
    
    // Reset selection and close modal
    window.selectedDevice = null;
    window.newDeviceOwner = '';
    window.showDeviceTransferModal = false;
    
    showToastMessage('Device ownership transferred successfully!');
  } catch (error) {
    console.error('Error transferring device ownership:', error);
    showToastMessage('Failed to transfer device ownership: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Remove a device
export const removeDevice = async (deviceId) => {
  try {
    if (!confirm('Are you sure you want to remove this device?')) {
      return;
    }
    
    setLoadingWithSafety(true);
    
    await fleetOperations.removeDevice(window.app.managedFleet, deviceId);
    
    // Refresh device list
    await loadDevices();
    
    // Reset selection if this was the selected device
    if (window.selectedDevice && window.selectedDevice.id === deviceId) {
      window.selectedDevice = null;
      window.newDeviceData = { 
        name: '', 
        description: '', 
        deviceType: '', 
        location: '', 
        properties: {} 
      };
      window.deviceTags = [];
    }
    
    showToastMessage('Device removed successfully!');
  } catch (error) {
    console.error('Error removing device:', error);
    showToastMessage('Failed to remove device: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Add a tag to a device
export const addTagToDevice = async () => {
  try {
    if (!window.selectedDevice) {
      showToastMessage('No device selected');
      return;
    }
    
    if (!window.selectedTagToAdd) {
      showToastMessage('Please select a tag to add');
      return;
    }
    
    setLoadingWithSafety(true);
    
    await fleetOperations.addDeviceToTag(
      window.app.managedFleet,
      window.selectedDevice.id,
      window.selectedTagToAdd
    );
    
    // Refresh device tags
    await loadDeviceTags(window.selectedDevice.id);
    
    // Reset selected tag
    window.selectedTagToAdd = '';
    
    showToastMessage('Tag added to device successfully!');
  } catch (error) {
    console.error('Error adding tag to device:', error);
    showToastMessage('Failed to add tag to device: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Remove a tag from a device
export const removeTagFromDevice = async (tagId) => {
  try {
    if (!window.selectedDevice) {
      showToastMessage('No device selected');
      return;
    }
    
    if (!confirm('Are you sure you want to remove this tag from the device?')) {
      return;
    }
    
    setLoadingWithSafety(true);
    
    await fleetOperations.removeDeviceFromTag(
      window.app.managedFleet,
      window.selectedDevice.id,
      tagId
    );
    
    // Refresh device tags
    await loadDeviceTags(window.selectedDevice.id);
    
    showToastMessage('Tag removed from device successfully!');
  } catch (error) {
    console.error('Error removing tag from device:', error);
    showToastMessage('Failed to remove tag from device: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
}; 