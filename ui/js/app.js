import registryAbi from './registry-abi.js';
import * as wallet from './wallet.js';
import * as fleetOperations from './fleet-operations.js';
import * as userManagement from './user-management.js';
import * as userGroupManagement from './user-group-management.js';
import { DeviceManagementComponent } from './device-management.js';
import { TagManagementComponent } from './tag-management.js';
import * as navigation from './navigation.js';
import * as utils from './utils.js';

const { createApp, ref, computed, watch, onMounted } = Vue;

// Create the app instance
const app = createApp({
  setup() {
    // State
    const isConnected = ref(false);
    const account = ref('');
    const ethereum = ref(null);
    const web3 = ref(null);
    const registryContract = ref(null);
    const registryAddress = ref('0x18D1c56474505893082e1B50A7c5a7cdc7854Eca');
    const registryVersion = ref(null);
    const ownFleetCount = ref(0);
    const ownFleets = ref([]);
    const sharedFleets = ref([]);
    const selectedFleet = ref(null);
    const fleetDetails = ref({});
    const fleetUsers = ref([]);
    const isLoading = ref(false);
    const isCreatingFleet = ref(false);
    const showingAddUserModal = ref(false);
    const targetFleetForUser = ref(null);
    const newUserAddress = ref('');
    const isAddingUser = ref(false);
    const availableAccounts = ref([]);
    const selectedAccountIndex = ref(0);
    const showFleetManagementModal = ref(false);
    const managedFleet = ref('');
    const managedFleetUsers = ref([]);
    const newFleetUserAddress = ref('');
    const showToast = ref(false);
    const toastMessage = ref('');
    const newFleetLabel = ref('');
    const fleetLabel = ref('');
    const isUpdatingLabel = ref(false);
    const showNetworkSelector = ref(false);
    const selectedNetworkIndex = ref(0);
    const networks = ref(wallet.networks);
    // New state variables for enhanced fleet management
    const activeTab = ref('users'); // users, devices, userGroups, tags
    
    // User management extended
    const fleetAllUsers = ref([]);
    const selectedUser = ref(null);
    const newUserData = ref({ address: '', nickname: '', email: '', avatarURI: '' });
    
    // User Group management
    const userGroups = ref([]);
    const selectedUserGroup = ref(null);
    const newUserGroupData = ref({ name: '', description: '' });
    const userGroupMembers = ref([]);
    
    // Device management
    const devices = ref([]);
    const selectedDevice = ref(null);
    const newDeviceData = ref({ 
      name: '', 
      description: '', 
      deviceType: '', 
      location: '', 
      properties: {} 
    });
    const deviceTags = ref([]);
    const selectedTagToAdd = ref('');
    const showDeviceTransferModal = ref(false);
    const newDeviceOwner = ref('');
    
    // Computed properties
    const groupedSharedFleets = computed(() => {
      const grouped = {};
      sharedFleets.value.forEach(fleet => {
        if (!grouped[fleet.owner]) {
          grouped[fleet.owner] = [];
        }
        grouped[fleet.owner].push(fleet);
      });
      return grouped;
    });

    // Handle account changes
    const handleAccountsChanged = async (accounts) => {
      if (accounts.length === 0) {
        isConnected.value = false;
        account.value = '';
        utils.showToastMessage('Please connect to MetaMask.');
      } else if (accounts[0] !== account.value) {
        account.value = accounts[0];
        isConnected.value = true;
        await loadUserData();
      }
    };

    // Connect wallet
    const connectWallet = async () => {
      try {
        utils.setLoadingWithSafety(true);
        
        try {
          // Initialize MetaMask and set ethereum.value
          ethereum.value = await wallet.initializeMetaMask();

          // Check the chain
          const chain = await wallet.getCurrentChain();

          if (!chain) {
            utils.showToastMessage('Please switch to the correct network.');
            await wallet.switchNetwork(0);
            return;
          }

          selectedNetworkIndex.value = chain.index;
          // Request accounts
          const accounts = await ethereum.value.request({ method: 'eth_requestAccounts' });
          await handleAccountsChanged(accounts);
          
          // Initialize Web3
          web3.value = new Web3(ethereum.value);
          
          // Initialize registry contract
          registryContract.value = new web3.value.eth.Contract(registryAbi, registryAddress.value);
          
          // Expose contract to window for debugging and external access
          window.web3 = web3.value;
          
          // Get registry version
          try {
            if (registryContract.value.methods.version) {
              registryVersion.value = await registryContract.value.methods.version().call();
              console.log('Registry version:', registryVersion.value);
            } else {
              console.log('Registry contract does not have a version method');
              registryVersion.value = 'Unknown';
            }
          } catch (versionError) {
            console.warn('Could not get registry version:', versionError);
            registryVersion.value = 'Unknown';
          }
          
          // Load user's fleets
          await loadUserData();
          
        } catch (walletError) {
          if (walletError.message && walletError.message.includes('MetaMask is not installed')) {
            utils.showToastMessage('MetaMask is not installed. Please install MetaMask to use this application.');
            console.warn('MetaMask is not installed. The application will have limited functionality.');
          } else {
            throw walletError; // Re-throw other errors to be caught by the outer catch block
          }
        }
        
      } catch (error) {
        console.error('Error connecting wallet:', error);
        utils.showToastMessage('Failed to connect wallet: ' + error.message);
      } finally {
        utils.setLoadingWithSafety(false);
      }
    };

    // Load user data (fleets)
    const loadUserData = async () => {
      try {
        if (!isConnected.value || !registryContract.value) return;
        
        utils.setLoadingWithSafety(true);
        
        // Get available accounts
        availableAccounts.value = await web3.value.eth.getAccounts();
        
        // Get own fleet count
        ownFleetCount.value = await registryContract.value.methods.GetOwnFleetCount().call({ from: account.value });
        console.log('Own fleet count:', ownFleetCount.value);
        
        // Get own fleets
        ownFleets.value = [];
        for (let i = 0; i < ownFleetCount.value; i++) {
          const fleet = await registryContract.value.methods.GetOwnFleet(i).call({ from: account.value });
          
          // Get fleet label
          let fleetLabel = '';
          try {
            fleetLabel = await fleetOperations.getFleetLabel(fleet.fleet);
          } catch (error) {
            console.warn(`Could not get label for fleet ${fleet.fleet}:`, error);
          }
          
          ownFleets.value.push({
            owner: fleet.owner,
            fleet: fleet.fleet,
            createdAt: new Date(fleet.createdAt * 1000),
            updatedAt: new Date(fleet.updatedAt * 1000),
            label: fleetLabel || ''
          });
        }
        
        // Get shared fleets
        sharedFleets.value = [];
        
        // Get sharing user count
        const sharingUserCount = await registryContract.value.methods.GetSharingUserCount().call({ from: account.value });
        console.log('Sharing user count:', sharingUserCount);
        
        // Get shared fleets for each sharing user
        for (let i = 0; i < sharingUserCount; i++) {
          const sharingUser = await registryContract.value.methods.GetSharingUser(i).call({ from: account.value });
          
          const sharedFleetCount = await registryContract.value.methods.GetSharedFleetCount(sharingUser).call({ from: account.value });
          
          for (let j = 0; j < sharedFleetCount; j++) {
            const fleet = await registryContract.value.methods.GetSharedFleet(sharingUser, j).call({ from: account.value });
            
            // Get fleet label
            let fleetLabel = '';
            try {
              fleetLabel = await fleetOperations.getFleetLabel(fleet.fleet);
            } catch (error) {
              console.warn(`Could not get label for shared fleet ${fleet.fleet}:`, error);
            }
            
            sharedFleets.value.push({
              owner: fleet.owner,
              fleet: fleet.fleet,
              createdAt: new Date(fleet.createdAt * 1000),
              updatedAt: new Date(fleet.updatedAt * 1000),
              label: fleetLabel || ''
            });
          }
        }
        
      } catch (error) {
        console.error('Error loading user data:', error);
        utils.showToastMessage('Failed to load fleet data: ' + error.message);
      } finally {
        utils.setLoadingWithSafety(false);
      }
    };

    // Switch account
    const switchAccount = async (index) => {
      try {
        if (index >= 0 && index < availableAccounts.value.length) {
          selectedAccountIndex.value = index;
          account.value = availableAccounts.value[index];
          await loadUserData();
        }
      } catch (error) {
        console.error('Error switching account:', error);
        utils.showToastMessage('Failed to switch account: ' + error.message);
      }
    };

    // Switch network
    const switchNetwork = async (index) => {
      console.log('Switching network:', index);
      selectedNetworkIndex.value = index;
      await wallet.switchNetwork(index);
      await connectWallet();
    };

    // Change account (MetaMask)
    const changeAccount = async () => {
      try {
        await ethereum.value.request({
          method: 'wallet_requestPermissions',
          params: [{ eth_accounts: {} }],
        });
      } catch (error) {
        console.error('Error changing account:', error);
      }
    };

    // Open add user modal
    const openAddUserModal = (fleetAddress) => {
      targetFleetForUser.value = fleetAddress;
      showingAddUserModal.value = true;
      newUserAddress.value = '';
    };

    // Close fleet management modal
    const closeFleetManagementModal = () => {
      showFleetManagementModal.value = false;
      managedFleet.value = '';
      managedFleetUsers.value = [];
      newFleetUserAddress.value = '';
    };

    // Manage fleet
    const manageFleet = async (fleetAddress) => {
      try {
        utils.setLoadingWithSafety(true);
        
        managedFleet.value = fleetAddress;
        
        // Get fleet users
        managedFleetUsers.value = [];
        const userCount = await registryContract.value.methods.GetFleetUserCount(fleetAddress).call({ from: account.value });
        
        for (let i = 0; i < userCount; i++) {
          const userAddress = await registryContract.value.methods.GetFleetUser(fleetAddress, i).call({ from: account.value });
          managedFleetUsers.value.push(userAddress);
        }
        
        showFleetManagementModal.value = true;
      } catch (error) {
        console.error('Error managing fleet:', error);
        utils.showToastMessage('Failed to load fleet data: ' + error.message);
      } finally {
        utils.setLoadingWithSafety(false);
      }
    };

    // Add fleet user from manager
    const addFleetUserFromManager = async () => {
      try {
        if (!utils.isValidAddress(newFleetUserAddress.value)) {
          utils.showToastMessage('Please enter a valid Ethereum address');
          return;
        }
        
        utils.setLoadingWithSafety(true);
        
        await fleetOperations.addFleetUser(
          managedFleet.value,
          newFleetUserAddress.value
        );
        
        // Refresh fleet users
        managedFleetUsers.value.push(newFleetUserAddress.value);
        
        newFleetUserAddress.value = '';
        utils.showToastMessage('User added successfully!');
      } catch (error) {
        console.error('Error adding fleet user:', error);
        utils.showToastMessage('Failed to add user: ' + error.message);
      } finally {
        utils.setLoadingWithSafety(false);
      }
    };

    // Update fleet label
    const updateFleetLabelImpl = async () => {
      try {
        if (!managedFleet.value) {
          utils.showToastMessage('No fleet selected');
          return;
        }

        if (!fleetLabel.value) {
          utils.showToastMessage('Please enter a fleet label');
          return;
        }

        isUpdatingLabel.value = true;
        
        await fleetOperations.updateFleetLabel(managedFleet.value, fleetLabel.value);
        utils.showToastMessage('Fleet label updated successfully!');
      } catch (error) {
        console.error('Error updating fleet label:', error);
        utils.showToastMessage('Failed to update fleet label: ' + error.message);
      } finally {
        isUpdatingLabel.value = false;
      }
    };

    // Initialize
    onMounted(async () => {
      try {
        ethereum.value = await wallet.initializeMetaMask();
        
        // Auto-connect if already connected
        if (ethereum.value && ethereum.value.selectedAddress) {
          await connectWallet();
        }
      } catch (error) {
        console.error('Error initializing app:', error);
      }
    });

    // Create a new fleet
    const createFleet = async () => {
      try {
        if (!isConnected.value || !registryContract.value) {
          utils.showToastMessage('Please connect your wallet first');
          return;
        }
        
        isCreatingFleet.value = true;
        const result = await registryContract.value.methods.CreateFleet(newFleetLabel.value).send({ from: account.value });
        console.log('Fleet created:', result);
        await loadUserData();
        utils.showToastMessage('Fleet created successfully!');
        newFleetLabel.value = '';
        navigation.showDashboard();
      } catch (error) {
        console.error('Error creating fleet:', error);
        utils.showToastMessage('Failed to create fleet: ' + error.message);
      } finally {
        isCreatingFleet.value = false;
      }
    };

    // Load user data
    window.loadUserData = () => loadUserData(); 

    // Return all functions and state variables
    return {
      isConnected,
      account,
      registryAddress,
      registryVersion,
      ownFleetCount,
      ownFleets,
      sharedFleets,
      selectedFleet,
      fleetDetails,
      fleetUsers,
      isLoading,
      isCreatingFleet,
      showingAddUserModal,
      newUserAddress,
      isAddingUser,
      groupedSharedFleets,
      availableAccounts,
      selectedAccountIndex,
      showFleetManagementModal,
      managedFleet,
      managedFleetUsers,
      newFleetUserAddress,
      showToast,
      toastMessage,
      newFleetLabel,
      fleetLabel,
      isUpdatingLabel,
      showNetworkSelector,
      selectedNetworkIndex,
      networks,
      switchNetwork,
      
      // New state variables for enhanced fleet management
      activeTab,
      
      // User management extended
      fleetAllUsers,
      selectedUser,
      newUserData,
      
      // User Group management
      userGroups,
      selectedUserGroup,
      newUserGroupData,
      userGroupMembers,
      
      // Device management
      devices,
      selectedDevice,
      newDeviceData,
      deviceTags,
      selectedTagToAdd,
      showDeviceTransferModal,
      newDeviceOwner,
      
      // Tag management variables removed - now handled by TagManagementComponent
      
      // Methods
      connectWallet,
      createFleet,
      addFleetUser: fleetOperations.addFleetUser,
      removeFleetUser: fleetOperations.removeFleetUser,
      closeFleetManagementModal,
      addFleetUserFromManager,
      updateFleetLabel: updateFleetLabelImpl,
      
      // Utility functions
      shortenAddress: utils.shortenAddress,
      formatDate: utils.formatDate,
      isValidAddress: utils.isValidAddress,
      switchAccount,
      changeAccount,
      manageFleet,
      
      // User management
      loadAllUsers: userManagement.loadAllUsers,
      selectUser: userManagement.selectUser,
      createNewUser: userManagement.createNewUser,
      updateUserDetails: userManagement.updateUserDetails,
      removeUserFromSystem: userManagement.removeUserFromSystem,
      isUserAdmin: userManagement.isUserAdmin,
      
      // User Group management
      loadUserGroups: userGroupManagement.loadUserGroups,
      selectUserGroup: userGroupManagement.selectUserGroup,
      loadGroupMembers: userGroupManagement.loadGroupMembers,
      createUserGroup: userGroupManagement.createUserGroup,
      updateUserGroup: userGroupManagement.updateUserGroup,
      removeUserGroup: userGroupManagement.removeUserGroup,
      addUserToGroup: userGroupManagement.addUserToGroup,
      removeUserFromGroup: userGroupManagement.removeUserFromGroup,
      
      // Navigation
      activePage: ref('dashboard'),
      showDashboard: navigation.showDashboard,
      showCreateFleetView: navigation.showCreateFleetView,
      showFleetManagement: navigation.showFleetManagement,
      
      // Modal state
      showingAddUserModal,
      targetFleetForUser,
      closeAddUserModal: () => {
        showingAddUserModal.value = false;
        targetFleetForUser.value = null;
        newUserAddress.value = '';
        isAddingUser.value = false;
        isLoading.value = false;
      },
      openAddUserModal
    };
  }
});

// Mount the app
app.component('device-management-component', DeviceManagementComponent);
app.component('tag-management-component', TagManagementComponent);
const mountedApp = app.mount('#app');

// Store the app reference in the window object for external access
window.app = mountedApp;
