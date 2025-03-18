import { showToastMessage } from './utils.js';
import * as fleetOperations from './fleet-operations.js';
// Navigation functions for the Fleet Manager application

// Show the dashboard view
export const showDashboard = () => {
  window.app.activePage = 'dashboard';
};

// Show the create fleet view
export const showCreateFleetView = () => {
  window.app.activePage = 'createFleet';
};

// Show the fleet management view
export const showFleetManagement = async (fleetAddress) => {
  console.log('showFleetManagement called for fleet:', fleetAddress);
  try {
    window.app.isLoading = true;
    console.log('Set isLoading to true in showFleetManagement');
    window.app.managedFleet = fleetAddress;
    
    // Set active tab to users (default)
    window.app.activeTab = 'users';
    
    // Fetch the fleet label
    try {
      console.log('Fetching fleet label');
      const label = await fleetOperations.getFleetLabel(fleetAddress);
      window.app.fleetLabel = label;
      console.log('Fleet label fetched:', label);
    } catch (err) {
      console.error('Error fetching label:', err);
      window.app.fleetLabel = ''; // Default to empty string if there's an error
    }
    
    // Load fleet users
    console.log('Loading fleet users');
    window.app.managedFleetUsers = [];
    const userCount = await fleetOperations.getFleetUserCount(fleetAddress);
    console.log('Fleet users count:', userCount);
    
    for (let i = 0; i < userCount; i++) {
      const userAddress = await fleetOperations.getFleetUserAtIndex(fleetAddress, i);
      console.log(`Loaded user ${i+1}/${userCount}:`, userAddress);
      
      // Add the user address - we don't have detailed user data available in registry
      window.app.managedFleetUsers.push({
        userAddress: userAddress,
        nickname: '',
        email: '',
        avatarURI: ''
      });
    }
    
    // Switch to fleet management view
    console.log('Switching to fleet management view');
    window.app.activePage = 'fleetManagement';
    
  } catch (error) {
    console.error('Error managing fleet:', error);
    showToastMessage('Error loading fleet data');
  } finally {
    console.log('Resetting isLoading in showFleetManagement finally block');
    window.app.isLoading = false;
  }
}; 