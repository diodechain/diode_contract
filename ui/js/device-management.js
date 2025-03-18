// Device management operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';
import * as fleetOperations from './fleet-operations.js';

// Device Management Component
export const DeviceManagementComponent = {
  props: {
    managedFleet: {
      type: String,
      required: true
    },
    isLoading: {
      type: Boolean,
      default: false
    }
  },

  data() {
    return {
      devices: [],
      selectedDevice: null,
      newDeviceData: {
        name: '',
        description: '',
        deviceType: '',
        location: '',
        properties: {}
      },
      deviceTags: [],
      showDeviceTransferModal: false,
      newDeviceOwner: '',
      selectedTagToAdd: '',
      showCreateDeviceModal: false
    }
  },

  template: `
    <div>
      <!-- Header with Create Device Button -->
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold">Devices</h3>
        <button 
          @click="showCreateDeviceModal = true" 
          class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-sm">
          Create Device
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="text-center py-4 text-gray-500">
        <p>Loading devices...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="devices.length === 0" class="text-center py-4 text-gray-500">
        <p>No devices found in this fleet.</p>
      </div>

      <!-- Device List -->
      <div v-else class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Last Seen</th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="device in devices" :key="device.id">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ device.name }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ device.deviceType }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ device.location }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ formatDate(device.lastSeen) }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                <button 
                  @click="selectDevice(device.id)" 
                  class="text-blue-600 hover:text-blue-900">
                  Edit
                </button>
                <button 
                  @click="transferDeviceDialog(device.id)" 
                  class="text-green-600 hover:text-green-900">
                  Transfer
                </button>
                <button 
                  @click="removeDevice(device.id)" 
                  class="text-red-600 hover:text-red-900">
                  Remove
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Create Device Modal -->
      <div v-if="showCreateDeviceModal" class="fixed inset-0 overflow-y-auto z-50 flex items-center justify-center">
        <div class="fixed inset-0 bg-black opacity-50"></div>
        <div class="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-800">Create New Device</h3>
          </div>
          
          <div class="p-6">
            <form @submit.prevent="createNewDevice">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Name</label>
                  <input type="text" v-model="newDeviceData.name" 
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Description</label>
                  <textarea v-model="newDeviceData.description" 
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"></textarea>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Device Type</label>
                  <input type="text" v-model="newDeviceData.deviceType" 
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700">Location</label>
                  <input type="text" v-model="newDeviceData.location" 
                    class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                </div>
              </div>
              
              <div class="mt-6 flex justify-end space-x-2">
                <button type="button" @click="showCreateDeviceModal = false" 
                  class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-2 px-4 rounded">
                  Cancel
                </button>
                <button type="submit" 
                  class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                  Create Device
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <!-- Transfer Device Modal -->
      <div v-if="showDeviceTransferModal" class="fixed inset-0 overflow-y-auto z-50 flex items-center justify-center">
        <div class="fixed inset-0 bg-black opacity-50"></div>
        <div class="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
          <div class="px-6 py-4 border-b border-gray-200">
            <h3 class="text-lg font-semibold text-gray-800">Transfer Device Ownership</h3>
          </div>
          
          <div class="p-6">
            <form @submit.prevent="transferDevice">
              <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700">New Owner Address</label>
                <input type="text" v-model="newDeviceOwner" 
                  class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  placeholder="0x...">
              </div>
              
              <div class="flex justify-end space-x-2">
                <button type="button" @click="showDeviceTransferModal = false" 
                  class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold py-2 px-4 rounded">
                  Cancel
                </button>
                <button type="submit" 
                  class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                  Transfer
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  `,

  methods: {
    formatDate(date) {
      return new Date(date).toLocaleString();
    },

    async createNewDevice() {
      try {
        if (!this.newDeviceData.name) {
          showToastMessage('Please enter a device name');
          return;
        }
        
        setLoadingWithSafety(true);
        
        // Create device
        const deviceId = await fleetOperations.createDevice(
          this.managedFleet,
          this.newDeviceData.name,
          this.newDeviceData.description || '',
          this.newDeviceData.deviceType || '',
          this.newDeviceData.location || ''
        );
        
        // Add properties if any
        if (this.newDeviceData.properties) {
          for (const [key, value] of Object.entries(this.newDeviceData.properties)) {
            if (key && value) {
              await fleetOperations.setDeviceProperty(this.managedFleet, deviceId, key, value);
            }
          }
        }
        
        await this.loadDevices();
        this.showCreateDeviceModal = false;
        showToastMessage('Device created successfully!');
      } catch (error) {
        console.error('Error creating device:', error);
        showToastMessage('Failed to create device: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
      }
    },

    async loadDevices() {
      try {
        setLoadingWithSafety(true);
        
        const deviceIds = await fleetOperations.getAllDevices(this.managedFleet);
        this.devices = [];
        
        for (const deviceId of deviceIds) {
          try {
            const deviceData = await fleetOperations.getDevice(this.managedFleet, deviceId);
            
            this.devices.push({
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
    },

    async selectDevice(deviceId) {
      const device = this.devices.find(d => d.id === deviceId);
      if (device) {
        this.selectedDevice = device;
        
        // Copy device data to form
        this.newDeviceData = {
          name: device.name,
          description: device.description,
          deviceType: device.deviceType,
          location: device.location,
          properties: {}
        };
        
        // Load device tags
        await this.loadDeviceTags(deviceId);
      }
    },

    async loadDeviceTags(deviceId) {
      try {
        setLoadingWithSafety(true);
        
        const tagIds = await fleetOperations.getDeviceTags(this.managedFleet, deviceId);
        this.deviceTags = [];
        
        for (const tagId of tagIds) {
          try {
            const tagData = await fleetOperations.getTag(this.managedFleet, tagId);
            
            this.deviceTags.push({
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
    },

    transferDeviceDialog(deviceId) {
      const device = this.devices.find(d => d.id === deviceId);
      if (device) {
        this.selectedDevice = device;
        this.newDeviceOwner = '';
        this.showDeviceTransferModal = true;
      }
    },

    async transferDevice() {
      try {
        if (!this.selectedDevice) {
          showToastMessage('No device selected');
          return;
        }
        
        if (!window.isValidAddress(this.newDeviceOwner)) {
          showToastMessage('Please enter a valid Ethereum address');
          return;
        }
        
        setLoadingWithSafety(true);
        
        await fleetOperations.transferDeviceOwnership(
          this.managedFleet,
          this.selectedDevice.id,
          this.newDeviceOwner
        );
        
        await this.loadDevices();
        this.showDeviceTransferModal = false;
        showToastMessage('Device ownership transferred successfully!');
      } catch (error) {
        console.error('Error transferring device ownership:', error);
        showToastMessage('Failed to transfer device ownership: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
      }
    },

    async removeDevice(deviceId) {
      try {
        if (!confirm('Are you sure you want to remove this device?')) {
          return;
        }
        
        setLoadingWithSafety(true);
        
        await fleetOperations.removeDevice(this.managedFleet, deviceId);
        await this.loadDevices();
        
        showToastMessage('Device removed successfully!');
      } catch (error) {
        console.error('Error removing device:', error);
        showToastMessage('Failed to remove device: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
      }
    }
  },

  mounted() {
    this.loadDevices();
  }
};

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