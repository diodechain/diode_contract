// Device management operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';

// Load all devices in the fleet
export const loadDevices = async () => {
  try {
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Get all devices
    const deviceIds = await fleetContractInstance.methods.getAllDevices().call({ from: window.account });
    
    // Load device details
    window.devices = [];
    
    for (const deviceId of deviceIds) {
      try {
        const deviceData = await fleetContractInstance.methods.getDevice(deviceId).call({ from: window.account });
        
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Get device tags
    const tagIds = await fleetContractInstance.methods.getDeviceTags(deviceId).call({ from: window.account });
    
    // Load tag details
    window.deviceTags = [];
    
    for (const tagId of tagIds) {
      try {
        const tagData = await fleetContractInstance.methods.getTag(tagId).call({ from: window.account });
        
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Create device
    const deviceId = await fleetContractInstance.methods.createDevice(
      window.newDeviceData.name,
      window.newDeviceData.description || '',
      window.newDeviceData.deviceType || '',
      window.newDeviceData.location || ''
    ).send({ from: window.account });
    
    // Add properties if any
    if (window.newDeviceData.properties) {
      for (const [key, value] of Object.entries(window.newDeviceData.properties)) {
        if (key && value) {
          await fleetContractInstance.methods.setDeviceProperty(
            deviceId,
            key,
            value
          ).send({ from: window.account });
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Update device
    await fleetContractInstance.methods.updateDevice(
      window.selectedDevice.id,
      window.newDeviceData.name,
      window.newDeviceData.description || '',
      window.newDeviceData.deviceType || '',
      window.newDeviceData.location || ''
    ).send({ from: window.account });
    
    // Update properties if any
    if (window.newDeviceData.properties) {
      for (const [key, value] of Object.entries(window.newDeviceData.properties)) {
        if (key && value) {
          await fleetContractInstance.methods.setDeviceProperty(
            window.selectedDevice.id,
            key,
            value
          ).send({ from: window.account });
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Update device last seen
    await fleetContractInstance.methods.updateDeviceLastSeen(deviceId).send({ from: window.account });
    
    // Refresh device list
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Transfer device ownership
    await fleetContractInstance.methods.transferDeviceOwnership(
      window.selectedDevice.id,
      window.newDeviceOwner
    ).send({ from: window.account });
    
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Remove device
    await fleetContractInstance.methods.removeDevice(deviceId).send({ from: window.account });
    
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Add tag to device
    await fleetContractInstance.methods.addDeviceToTag(
      window.selectedDevice.id,
      window.selectedTagToAdd
    ).send({ from: window.account });
    
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
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Remove tag from device
    await fleetContractInstance.methods.removeDeviceFromTag(
      window.selectedDevice.id,
      tagId
    ).send({ from: window.account });
    
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