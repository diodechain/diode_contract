// Tag management operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';

// Load all tags in the fleet
export const loadTags = async () => {
  try {
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Get all tags
    const tagIds = await fleetContractInstance.methods.getAllTags().call({ from: window.account });
    
    // Load tag details
    window.tags = [];
    
    for (const tagId of tagIds) {
      try {
        const tagData = await fleetContractInstance.methods.getTag(tagId).call({ from: window.account });
        
        window.tags.push({
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
    console.error('Error loading tags:', error);
    showToastMessage('Failed to load tags: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Select a tag for viewing/editing
export const selectTag = (tagId) => {
  const tag = window.tags.find(t => t.id === tagId);
  if (tag) {
    window.selectedTag = tag;
    
    // Copy tag data to form
    window.newTagData = {
      name: tag.name,
      description: tag.description,
      color: tag.color,
      properties: {}
    };
    
    // Load tag devices
    loadTagDevices(tagId);
  }
};

// Load devices for a tag
export const loadTagDevices = async (tagId) => {
  try {
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Get tag devices
    const deviceIds = await fleetContractInstance.methods.getTagDevices(tagId).call({ from: window.account });
    
    // Load device details
    window.tagDevices = [];
    
    for (const deviceId of deviceIds) {
      try {
        const deviceData = await fleetContractInstance.methods.getDevice(deviceId).call({ from: window.account });
        
        window.tagDevices.push({
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
    console.error('Error loading tag devices:', error);
    showToastMessage('Failed to load tag devices: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Create a new tag
export const createTag = async () => {
  try {
    if (!window.newTagData.name) {
      showToastMessage('Please enter a tag name');
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Create tag
    const tagId = await fleetContractInstance.methods.createTag(
      window.newTagData.name,
      window.newTagData.description || '',
      window.newTagData.color || '#3B82F6'
    ).send({ from: window.account });
    
    // Add properties if any
    if (window.newTagData.properties) {
      for (const [key, value] of Object.entries(window.newTagData.properties)) {
        if (key && value) {
          await fleetContractInstance.methods.setTagProperty(
            tagId,
            key,
            value
          ).send({ from: window.account });
        }
      }
    }
    
    // Refresh tag list
    await loadTags();
    
    // Reset form
    window.newTagData = { name: '', description: '', color: '#3B82F6', properties: {} };
    
    showToastMessage('Tag created successfully!');
  } catch (error) {
    console.error('Error creating tag:', error);
    showToastMessage('Failed to create tag: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Update tag details
export const updateTag = async () => {
  try {
    if (!window.selectedTag) {
      showToastMessage('No tag selected');
      return;
    }
    
    if (!window.newTagData.name) {
      showToastMessage('Please enter a tag name');
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Update tag
    await fleetContractInstance.methods.updateTag(
      window.selectedTag.id,
      window.newTagData.name,
      window.newTagData.description || '',
      window.newTagData.color || '#3B82F6'
    ).send({ from: window.account });
    
    // Update properties if any
    if (window.newTagData.properties) {
      for (const [key, value] of Object.entries(window.newTagData.properties)) {
        if (key && value) {
          await fleetContractInstance.methods.setTagProperty(
            window.selectedTag.id,
            key,
            value
          ).send({ from: window.account });
        }
      }
    }
    
    // Refresh tag list
    await loadTags();
    
    // Reset selection
    window.selectedTag = null;
    window.newTagData = { name: '', description: '', color: '#3B82F6', properties: {} };
    window.tagDevices = [];
    
    showToastMessage('Tag updated successfully!');
  } catch (error) {
    console.error('Error updating tag:', error);
    showToastMessage('Failed to update tag: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Remove a tag
export const removeTag = async () => {
  try {
    if (!window.selectedTag) {
      showToastMessage('No tag selected');
      return;
    }
    
    if (!confirm('Are you sure you want to remove this tag?')) {
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Remove tag
    await fleetContractInstance.methods.removeTag(window.selectedTag.id).send({ from: window.account });
    
    // Refresh tag list
    await loadTags();
    
    // Reset selection
    window.selectedTag = null;
    window.newTagData = { name: '', description: '', color: '#3B82F6', properties: {} };
    window.tagDevices = [];
    
    showToastMessage('Tag removed successfully!');
  } catch (error) {
    console.error('Error removing tag:', error);
    showToastMessage('Failed to remove tag: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Remove a device from a tag
export const removeDeviceFromTag = async (deviceId) => {
  try {
    if (!window.selectedTag) {
      showToastMessage('No tag selected');
      return;
    }
    
    if (!confirm('Are you sure you want to remove this device from the tag?')) {
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Remove device from tag
    await fleetContractInstance.methods.removeDeviceFromTag(
      deviceId,
      window.selectedTag.id
    ).send({ from: window.account });
    
    // Refresh tag devices
    await loadTagDevices(window.selectedTag.id);
    
    showToastMessage('Device removed from tag successfully!');
  } catch (error) {
    console.error('Error removing device from tag:', error);
    showToastMessage('Failed to remove device from tag: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
}; 