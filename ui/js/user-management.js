// User management operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';

// Load all users in the fleet
export const loadAllUsers = async () => {
  try {
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Get all users
    const userAddresses = await fleetContractInstance.methods.getAllUsers().call({ from: window.account });
    
    // Load user details
    window.fleetAllUsers = [];
    
    for (const userAddress of userAddresses) {
      try {
        const userData = await fleetContractInstance.methods.getUser(userAddress).call({ from: window.account });
        
        window.fleetAllUsers.push({
          address: userData.user,
          nickname: userData.nickname,
          email: userData.email,
          avatarURI: userData.avatarURI,
          isAdmin: userData.isAdmin,
          createdAt: new Date(userData.createdAt * 1000),
          active: userData.active
        });
      } catch (error) {
        console.error(`Error loading user ${userAddress}:`, error);
      }
    }
  } catch (error) {
    console.error('Error loading users:', error);
    showToastMessage('Failed to load users: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Select a user for viewing/editing
export const selectUser = (userAddress) => {
  const user = window.fleetAllUsers.find(u => u.address === userAddress);
  if (user) {
    window.selectedUser = user;
    
    // Copy user data to form
    window.newUserData = {
      address: user.address,
      nickname: user.nickname,
      email: user.email,
      avatarURI: user.avatarURI
    };
    
    window.isUserAdmin = user.isAdmin;
  }
};

// Create a new user
export const createNewUser = async () => {
  try {
    if (!window.isValidAddress(window.newUserData.address)) {
      showToastMessage('Please enter a valid Ethereum address');
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Create user
    await fleetContractInstance.methods.createUser(
      window.newUserData.address,
      window.newUserData.nickname || '',
      window.newUserData.email || '',
      window.newUserData.avatarURI || ''
    ).send({ from: window.account });
    
    // Refresh user list
    await loadAllUsers();
    
    // Reset form
    window.newUserData = { address: '', nickname: '', email: '', avatarURI: '' };
    
    showToastMessage('User created successfully!');
  } catch (error) {
    console.error('Error creating user:', error);
    showToastMessage('Failed to create user: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Update user details
export const updateUserDetails = async () => {
  try {
    if (!window.selectedUser) {
      showToastMessage('No user selected');
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Update user details
    await fleetContractInstance.methods.updateUser(
      window.selectedUser.address,
      window.newUserData.nickname || '',
      window.newUserData.email || '',
      window.newUserData.avatarURI || ''
    ).send({ from: window.account });
    
    // Update user admin status if changed
    if (window.selectedUser.isAdmin !== window.isUserAdmin) {
      await fleetContractInstance.methods.setUserAdmin(
        window.selectedUser.address,
        window.isUserAdmin
      ).send({ from: window.account });
    }
    
    // Refresh user list
    await loadAllUsers();
    
    // Reset selection
    window.selectedUser = null;
    window.newUserData = { address: '', nickname: '', email: '', avatarURI: '' };
    
    showToastMessage('User updated successfully!');
  } catch (error) {
    console.error('Error updating user:', error);
    showToastMessage('Failed to update user: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Remove a user from the system
export const removeUserFromSystem = async () => {
  try {
    if (!window.selectedUser) {
      showToastMessage('No user selected');
      return;
    }
    
    if (!confirm('Are you sure you want to remove this user?')) {
      return;
    }
    
    setLoadingWithSafety(true);
    
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Remove user
    await fleetContractInstance.methods.removeUser(window.selectedUser.address).send({ from: window.account });
    
    // Refresh user list
    await loadAllUsers();
    
    // Reset selection
    window.selectedUser = null;
    window.newUserData = { address: '', nickname: '', email: '', avatarURI: '' };
    
    showToastMessage('User removed successfully!');
  } catch (error) {
    console.error('Error removing user:', error);
    showToastMessage('Failed to remove user: ' + error.message);
  } finally {
    setLoadingWithSafety(false);
  }
};

// Check if a user is an admin
export const isUserAdmin = async (userAddress) => {
  try {
    // Get fleet contract instance
    const fleetContractInstance = new window.web3.eth.Contract(window.fleetContractAbi, window.managedFleet);
    
    // Check if user is admin
    return await fleetContractInstance.methods.isUserAdmin(userAddress).call({ from: window.account });
  } catch (error) {
    console.error('Error checking if user is admin:', error);
    return false;
  }
}; 