// Initialize MetaMask SDK
let ethereum;

export const initializeMetaMask = async () => {
  if (ethereum) {
    return ethereum;
  }

  try {
    const sdk = new MetaMaskSDK.MetaMaskSDK({
      dappMetadata: {
        name: "ZTNA Perimeter Manager",
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
      ethereum = sdk.getProvider();
      return ethereum;
    } else if (sdk.provider) {
      console.log('Using provider property');
      ethereum = sdk.provider;
      return ethereum;
    } else {
      throw new Error('Unable to get provider from SDK');
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
    await initializeMetaMask();
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

// Network configurations
export var networks = [
  {
    index: 0,
    chainId: "0x5afe",
    name: "Oasis Sapphire",
    rpcUrls: ["https://sapphire.oasis.io"],
    nativeCurrency: {
      name: "ROSE",
      symbol: "ROSE",
      decimals: 18
    },
    blockExplorerUrls: ["https://explorer.oasis.io/mainnet/sapphire"]
  },
  {
    index: 1,
    chainId: "0x5aff",
    name: "Oasis Sapphire Testnet",
    rpcUrls: ["https://testnet.sapphire.oasis.io"],
    nativeCurrency: {
      name: "TEST",
      symbol: "TEST",
      decimals: 18
    },
    blockExplorerUrls: ["https://explorer.oasis.io/testnet/sapphire"],
    registry: '0x18D1c56474505893082e1B50A7c5a7cdc7854Eca'
  }
];

if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
  networks.push({
    index: 2,
    chainId: "0x539",
    name: "Anvil",
    rpcUrls: ["http://localhost:8545"],
    nativeCurrency: {
      name: "ETH",
      symbol: "ETH",
      decimals: 18
    },
    blockExplorerUrls: ["http://localhost:8545"],
    registry: '0x5FbDB2315678afecb367f032d93F642f64180aa3'
  });
}

export async function getCurrentChain() {
  try {
    const chainId = await ethereum.request({ 
      method: "eth_chainId" 
    });
    console.log("Current chain ID:", chainId);

    return networks.find(network => network.chainId === chainId);
    // return chainId;
  } catch (err) {
    console.error("Error getting chain:", err);
  }
}

export async function switchNetwork(networkKey) {
  const network = networks[networkKey];
  
  try {
    // Try to switch to the network
    await ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: network.chainId }]
    });
  } catch (err) {
    // If the error code is 4902, the network needs to be added
    if (err.code === 4902) {
      try {
        await ethereum.request({
          method: "wallet_addEthereumChain",
          params: [{
            chainId: network.chainId,
            chainName: network.name,
            rpcUrls: network.rpcUrls,
            nativeCurrency: network.nativeCurrency,
            blockExplorerUrls: network.blockExplorerUrls
          }]
        });
      } catch (addError) {
        console.error("Error adding network:", addError);
      }
    } else {
      console.error("Error switching network:", err);
    }
  }
}