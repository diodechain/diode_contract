// Navigation functions for the Fleet Manager application

// Show the dashboard view
export const showDashboard = () => {
  window.activePage = 'dashboard';
};

// Show the create fleet view
export const showCreateFleetView = () => {
  window.activePage = 'createFleet';
};

// Show the fleet management view
export const showFleetManagement = async (fleetAddress) => {
  console.log('showFleetManagement called for fleet:', fleetAddress);
  try {
    window.isLoading = true;
    console.log('Set isLoading to true in showFleetManagement');
    window.managedFleet = fleetAddress;
    
    // Set active tab to users (default)
    window.activeTab = 'users';
    
    // Fetch the fleet label using web3
    try {
      console.log('Fetching fleet label');
      const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, fleetAddress);
      const label = await fleetContractInstance.methods.label().call();
      window.fleetLabel = label;
      console.log('Fleet label fetched:', label);
    } catch (err) {
      console.error('Error fetching label:', err);
      window.fleetLabel = ''; // Default to empty string if there's an error
    }
    
    // Load fleet users
    console.log('Loading fleet users');
    window.managedFleetUsers = [];
    const userCount = await window.registryContract.methods.GetFleetUserCount(fleetAddress).call({ from: window.account });
    console.log('Fleet users count:', userCount);
    
    for (let i = 0; i < userCount; i++) {
      const userAddress = await window.registryContract.methods.GetFleetUser(fleetAddress, i).call({ from: window.account });
      console.log(`Loaded user ${i+1}/${userCount}:`, userAddress);
      
      // Add the user address - we don't have detailed user data available in registry
      window.managedFleetUsers.push({
        userAddress: userAddress,
        nickname: '',
        email: '',
        avatarURI: ''
      });
    }
    
    // Switch to fleet management view
    console.log('Switching to fleet management view');
    window.activePage = 'fleetManagement';
    
  } catch (error) {
    console.error('Error managing fleet:', error);
    window.showToastMessage('Error loading fleet data');
  } finally {
    console.log('Resetting isLoading in showFleetManagement finally block');
    window.isLoading = false;
  }
}; 