// Fleet operations for the Fleet Manager application
import { showToastMessage, setLoadingWithSafety } from './utils.js';
import { 
  createFleet as blockchainCreateFleet,
  updateFleetLabel as blockchainUpdateFleetLabel,
  getFleetUsers as blockchainGetFleetUsers,
  addFleetUser as blockchainAddFleetUser,
  removeFleetUser as blockchainRemoveFleetUser
} from './blockchain.js';

// Create a new fleet
export async function createFleet(contract, account, label) {
  try {
    const result = await blockchainCreateFleet(contract, account, label);
    showToastMessage('Fleet created successfully!');
    return result;
  } catch (error) {
    console.error('Error creating fleet:', error);
    showToastMessage('Failed to create fleet: ' + error.message);
    throw error;
  }
}

// View fleet details
export function viewFleetDetails(fleet) {
  return {
    address: fleet.fleet,
    owner: fleet.owner,
    label: fleet.label || '',
    createdAt: fleet.createdAt,
    updatedAt: fleet.updatedAt
  };
}

// Update fleet label
export async function updateFleetLabel(contract, account, fleet, label) {
  try {
    await blockchainUpdateFleetLabel(contract, account, fleet, label);
    showToastMessage('Fleet label updated successfully!');
  } catch (error) {
    console.error('Error updating fleet label:', error);
    showToastMessage('Failed to update fleet label: ' + error.message);
    throw error;
  }
}

// Get users of a fleet
export async function getFleetUsers(contract, account, fleet) {
  try {
    return await blockchainGetFleetUsers(contract, account, fleet);
  } catch (error) {
    console.error('Error getting fleet users:', error);
    showToastMessage('Failed to get fleet users: ' + error.message);
    throw error;
  }
}

// Add a user to a fleet
export async function addFleetUser(contract, account, fleet, user) {
  try {
    await blockchainAddFleetUser(contract, account, fleet, user);
    showToastMessage('User added to fleet successfully!');
  } catch (error) {
    console.error('Error adding user to fleet:', error);
    showToastMessage('Failed to add user to fleet: ' + error.message);
    throw error;
  }
}

// Remove a user from a fleet
export async function removeFleetUser(contract, account, fleet, user) {
  try {
    await blockchainRemoveFleetUser(contract, account, fleet, user);
    showToastMessage('User removed from fleet successfully!');
  } catch (error) {
    console.error('Error removing user from fleet:', error);
    showToastMessage('Failed to remove user from fleet: ' + error.message);
    throw error;
  }
} 