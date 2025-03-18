// Tag management operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';
import * as fleetOperations from './fleet-operations.js';

// Load all tags in the fleet
export const loadTags = async () => {
  try {
    setLoadingWithSafety(true);
    
    // Get all tags
    const tagIds = await fleetOperations.getAllTags(window.app.managedFleet);
    
    // Load tag details
    window.tags = [];
    
    for (const tagId of tagIds) {
      try {
        const tagData = await fleetOperations.getTag(window.app.managedFleet, tagId);
        
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
    
    // Get tag devices
    const deviceIds = await fleetOperations.getTagDevices(window.app.managedFleet, tagId);
    
    // Load device details
    window.tagDevices = [];
    
    for (const deviceId of deviceIds) {
      try {
        const deviceData = await fleetOperations.getDevice(window.app.managedFleet, deviceId);
        
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
    
    // Create tag
    const tagId = await fleetOperations.createTag(
      window.app.managedFleet,
      window.newTagData.name,
      window.newTagData.description || '',
      window.newTagData.color || '#3B82F6'
    );
    
    // Add properties if any
    if (window.newTagData.properties) {
      for (const [key, value] of Object.entries(window.newTagData.properties)) {
        if (key && value) {
          await fleetOperations.setTagProperty(window.app.managedFleet, tagId, key, value);
        }
      }
    }
    
    // Refresh tag list
    await loadTags();
    
    // Reset form
    window.newTagData = { name: '', description: '', color: '#3B82F6', properties: {} };
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
    
    // Update tag
    await fleetOperations.updateTag(
      window.app.managedFleet,
      window.selectedTag.id,
      window.newTagData.name,
      window.newTagData.description || '',
      window.newTagData.color || '#3B82F6'
    );
    
    // Update properties if any
    if (window.newTagData.properties) {
      for (const [key, value] of Object.entries(window.newTagData.properties)) {
        if (key && value) {
          await fleetOperations.setTagProperty(window.app.managedFleet, window.selectedTag.id, key, value);
        }
      }
    }
    
    // Refresh tag list
    await loadTags();
    
    // Reset selection
    window.selectedTag = null;
    window.newTagData = { name: '', description: '', color: '#3B82F6', properties: {} };
    window.tagDevices = [];
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
    
    // Remove tag
    await fleetOperations.removeTag(window.app.managedFleet, window.selectedTag.id);
    
    // Refresh tag list
    await loadTags();
    
    // Reset selection
    window.selectedTag = null;
    window.newTagData = { name: '', description: '', color: '#3B82F6', properties: {} };
    window.tagDevices = [];
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
    
    // Remove device from tag
    await fleetOperations.removeDeviceFromTag(
      window.app.managedFleet,
      deviceId,
      window.selectedTag.id
    );
    
    // Refresh tag devices
    await loadTagDevices(window.selectedTag.id);
  } catch (error) {
    console.error('Error removing device from tag:', error);
    showToastMessage('Failed to remove device from tag: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
}; 