// Wallet connection utilities

// Initialize MetaMask SDK
export const initializeMetaMask = async () => {
  try {
    // Fallback to window.ethereum if already available
    if (window.ethereum) {
      console.log('Using window.ethereum provider');
      return window.ethereum;
    } else if (window.MetaMaskSDK) {
      console.log('Initializing MetaMask SDK');
      let sdk;
      try {
        // Try the new SDK initialization method
        sdk = new window.MetaMaskSDK({
          dappMetadata: {
            name: "IoT Fleet Manager",
            url: window.location.href,
          },
          logging: {
            sdk: false
          }
        });
        
        // Check if the SDK has initialization method
        if (typeof sdk.init === 'function') {
          console.log('Using new SDK init method');
          await sdk.init();
        }
        
        // Check which provider accessor method is available
        if (typeof sdk.getProvider === 'function') {
          console.log('Using getProvider method');
          return sdk.getProvider();
        } else if (sdk.provider) {
          console.log('Using provider property');
          return sdk.provider;
        } else {
          throw new Error('Unable to get provider from SDK');
        }
      } catch (error) {
        console.error('Error initializing SDK with new method:', error);
        // Fall back to older SDK initialization if available
        try {
          console.log('Trying legacy SDK initialization');
          if (window.ethereum) {
            console.log('Using window.ethereum from SDK');
            return window.ethereum;
          } else {
            throw new Error('No ethereum provider available from SDK');
          }
        } catch (fallbackError) {
          console.error('Error with legacy initialization:', fallbackError);
          throw new Error('Failed to initialize MetaMask: ' + fallbackError.message);
        }
      }
    } else if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      // For development/testing, provide a mock provider
      console.warn('MetaMask not detected, but running in development environment. Using mock provider.');
      return createMockProvider();
    } else {
      throw new Error('MetaMask is not installed. Please install MetaMask to use this application.');
    }
  } catch (error) {
    console.error('Error initializing MetaMask:', error);
    throw error;
  }
}; 

/**
 * Creates a mock Ethereum provider for development/testing
 * @returns {Object} Mock provider
 */
function createMockProvider() {
  const mockAccounts = ['0x1234567890123456789012345678901234567890'];
  
  return {
    isMetaMask: true,
    isMock: true,
    request: async ({ method, params }) => {
      console.log(`Mock provider received request: ${method}`, params);
      
      switch (method) {
        case 'eth_requestAccounts':
        case 'eth_accounts':
          return mockAccounts;
        case 'eth_chainId':
          return '0x1'; // Mainnet
        case 'net_version':
          return '1'; // Mainnet
        default:
          console.warn(`Mock provider: Unhandled method ${method}`);
          return null;
      }
    },
    on: (event, handler) => {
      console.log(`Mock provider: Registered handler for ${event}`);
      // We don't actually trigger any events in the mock
    },
    removeListener: () => {
      // No-op
    }
  };
}

// Wallet interaction functions
import { showToast } from './utils.js';

let web3;
let account;
let accounts;
let ethereum;

/**
 * Initialize Web3 and connect to the wallet
 * @returns {Object} Web3 instance and account
 */
async function initWeb3() {
  if (web3 && accounts) {
    return { web3, account: accounts[0] };
  } else if (window.ethereum) {
    try {
      // Request account access
      accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      web3 = new Web3(window.ethereum);
      
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
    web3 = new Web3(window.web3.currentProvider);
    accounts = await web3.eth.getAccounts();
    return { web3, account: accounts[0] };
  } else {
    throw new Error("No Ethereum browser extension detected. Please install MetaMask.");
  }
}


/**
 * Connect to wallet and return web3 instance and account
 * @returns {Promise<Object>} Object containing web3 instance and account
 */
export async function connectWallet() {
  if (web3 && account && ethereum) {
    return { web3, account, ethereum };
  }

  try {
    ethereum = await initializeMetaMask();
    let ret = await initWeb3();
    web3 = ret.web3;
    account = ret.account;
    
    // Setup event listeners for account changes
    ethereum.on('accountsChanged', (accounts) => {
      if (accounts.length === 0) {
        // User disconnected wallet
        window.isConnected = false;
        window.account = null;
        showToast(window.app, 'Wallet disconnected.');
      } else if (accounts[0] !== window.account) {
        // User switched accounts
        window.account = accounts[0];
        showToast(window.app, 'Account changed to ' + accounts[0]);
        
        // Reload data with new account
        if (typeof window.loadUserData === 'function') {
          window.loadUserData();
        }
      }
    });
    
    // Handle chain changes
    ethereum.on('chainChanged', () => {
      showToast(window.app, 'Network changed. Reloading...');
      window.location.reload();
    });
    
    return { web3, account, ethereum };
  } catch (error) {
    console.error('Error connecting wallet:', error);
    showToast(window.app, 'Failed to connect wallet: ' + error.message);
    throw error;
  }
}

/**
 * Get all available accounts from the wallet
 * @param {Object} web3 - Web3 instance
 * @returns {Promise<Array>} List of accounts
 */
export async function getAllAccounts(web3) {
  try {
    return await web3.eth.getAccounts();
  } catch (error) {
    console.error('Error getting accounts:', error);
    showToast(window.app, 'Failed to get accounts: ' + error.message);
    throw error;
  }
}

/**
 * Switch to a different account
 * @param {string} account - Account address to switch to
 */
export async function switchAccount(account) {
  try {
    if (window.ethereum) {
      await window.ethereum.request({
        method: 'wallet_requestPermissions',
        params: [{ eth_accounts: {} }]
      });
      
      // The user will be prompted to select an account
      // After selection, the accountsChanged event will fire
    }
  } catch (error) {
    console.error('Error switching account:', error);
    showToast(window.app, 'Failed to switch account: ' + error.message);
    throw error;
  }
} 