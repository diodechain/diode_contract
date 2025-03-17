// Blockchain interaction functions
import { fleetManagerABI } from './abi.js';

// Contract addresses - these would be set based on deployment
const FLEET_MANAGER_ADDRESS = '0x5FbDB2315678afecb367f032d93F642f64180aa3';

/**
 * Initialize Web3 and connect to the wallet
 * @returns {Object} Web3 instance and account
 */
export async function initWeb3() {
  if (window.ethereum) {
    try {
      // Request account access
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      const web3 = new Web3(window.ethereum);
      
      // Check if this is a mock provider (for development/testing)
      if (window.ethereum.isMock) {
        console.warn('Using mock provider for Web3. Limited functionality available.');
      }
      
      return { web3, account: accounts[0] };
    } catch (error) {
      console.error("User denied account access");
      throw error;
    }
  } else if (window.web3) {
    // Legacy dapp browsers
    const web3 = new Web3(window.web3.currentProvider);
    const accounts = await web3.eth.getAccounts();
    return { web3, account: accounts[0] };
  } else {
    throw new Error("No Ethereum browser extension detected. Please install MetaMask.");
  }
}

/**
 * Get all available accounts from the wallet
 * @param {Object} web3 - Web3 instance
 * @returns {Array} List of accounts
 */
export async function getAccounts(web3) {
  return await web3.eth.getAccounts();
}

/**
 * Get the FleetManager contract instance
 * @param {Object} web3 - Web3 instance
 * @returns {Object} Contract instance
 */
export function getFleetManagerContract(web3) {
  return new web3.eth.Contract(fleetManagerABI, FLEET_MANAGER_ADDRESS);
}

/**
 * Get fleets owned by a user
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @returns {Array} List of fleets
 */
export async function getOwnFleets(contract, account) {
  return await contract.methods.getFleets(account).call({ from: account });
}

/**
 * Get fleets shared with a user
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @returns {Array} List of shared fleets
 */
export async function getSharedFleets(contract, account) {
  return await contract.methods.getSharedFleets(account).call({ from: account });
}

/**
 * Create a new fleet
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @param {string} label - Label for the fleet
 * @returns {string} Address of the new fleet
 */
export async function createFleet(contract, account, label) {
  return await contract.methods.createFleet(label).send({ from: account });
}

/**
 * Update a fleet's label
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @param {string} fleet - Fleet address
 * @param {string} label - New label for the fleet
 */
export async function updateFleetLabel(contract, account, fleet, label) {
  return await contract.methods.updateFleetLabel(fleet, label).send({ from: account });
}

/**
 * Get users of a fleet
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @param {string} fleet - Fleet address
 * @returns {Array} List of fleet users
 */
export async function getFleetUsers(contract, account, fleet) {
  return await contract.methods.getFleetUsers(fleet).call({ from: account });
}

/**
 * Add a user to a fleet
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @param {string} fleet - Fleet address
 * @param {string} user - User address to add
 */
export async function addFleetUser(contract, account, fleet, user) {
  return await contract.methods.addFleetUser(fleet, user).send({ from: account });
}

/**
 * Remove a user from a fleet
 * @param {Object} contract - FleetManager contract instance
 * @param {string} account - User's Ethereum address
 * @param {string} fleet - Fleet address
 * @param {string} user - User address to remove
 */
export async function removeFleetUser(contract, account, fleet, user) {
  return await contract.methods.removeFleetUser(fleet, user).send({ from: account });
} 