// Simple MetaMask SDK fallback when the actual SDK can't be loaded
window.MetaMaskSDK = window.MetaMaskSDK || {
  init: function() {
    console.log('Using simplified MetaMask connector');
    return Promise.resolve();
  },
  getProvider: function() {
    if (!window.ethereum) {
      throw new Error('MetaMask not detected. Please install the MetaMask extension.');
    }
    return window.ethereum;
  }
};

console.log('Simplified MetaMask SDK loaded');