import registryAbi from './registry-abi.js';
import fleetContractAbi from './fleet-contract-abi.js';
import { initializeMetaMask } from './wallet.js';
import { 
  createFleet, 
  viewFleetDetails, 
  addFleetUser, 
  removeFleetUser, 
  updateFleetLabel 
} from './fleet-operations.js';
import {
  loadAllUsers,
  selectUser,
  createNewUser,
  updateUserDetails,
  removeUserFromSystem,
  isUserAdmin
} from './user-management.js';
import {
  loadUserGroups,
  selectUserGroup,
  loadGroupMembers,
  createUserGroup,
  updateUserGroup,
  removeUserGroup,
  addUserToGroup,
  removeUserFromGroup
} from './user-group-management.js';
import {
  loadDevices,
  selectDevice,
  loadDeviceTags,
  createNewDevice,
  updateDeviceDetails,
  updateDeviceLastSeen,
  transferDeviceDialog,
  transferDevice,
  removeDevice,
  addTagToDevice,
  removeTagFromDevice
} from './device-management.js';
import {
  loadTags,
  selectTag,
  loadTagDevices,
  createTag,
  updateTag,
  removeTag,
  removeDeviceFromTag
} from './tag-management.js';
import { 
  showDashboard, 
  showCreateFleetView, 
  showFleetManagement 
} from './navigation.js';
import { 
  showToastMessage, 
  setLoadingWithSafety, 
  shortenAddress, 
  formatDate, 
  isValidAddress,
  showToast,
  handleError
} from './utils.js';
import { 
  initWeb3, 
  getAccounts,
  getFleetManagerContract, 
  getOwnFleets, 
  getSharedFleets,
  getFleetUsers
} from './blockchain.js';

const { createApp, ref, computed, watch, onMounted } = Vue;

createApp({
  setup() {
    // State
    const isConnected = ref(false);
    const account = ref('');
    const ethereum = ref(null);
    const web3 = ref(null);
    const registryContract = ref(null);
    const fleetContract = ref(null);
    const registryAddress = ref('0x5FbDB2315678afecb367f032d93F642f64180aa3');
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
    const currentFleetForAddUser = ref('');
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
    
    // Tag management
    const tags = ref([]);
    const selectedTag = ref(null);
    const newTagData = ref({ name: '', description: '', color: '#3B82F6', properties: {} });
    const tagDevices = ref([]);

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
        showToastMessage('Please connect to MetaMask.');
      } else if (accounts[0] !== account.value) {
        account.value = accounts[0];
        isConnected.value = true;
        await loadUserData();
      }
    };

    // Connect wallet
    const connectWallet = async () => {
      try {
        setLoadingWithSafety(true);
        
        try {
          // Initialize MetaMask and set ethereum.value
          ethereum.value = await initializeMetaMask();
          
          // Request accounts
          const accounts = await ethereum.value.request({ method: 'eth_requestAccounts' });
          await handleAccountsChanged(accounts);
          
          // Initialize Web3
          web3.value = new Web3(ethereum.value);
          
          // Initialize registry contract
          registryContract.value = new web3.value.eth.Contract(registryAbi, registryAddress.value);
          
          // Get registry version
          try {
            registryVersion.value = await registryContract.value.methods.version().call();
            console.log('Registry version:', registryVersion.value);
          } catch (versionError) {
            console.warn('Could not get registry version:', versionError);
          }
          
          // Load user's fleets
          await loadUserData();
          
        } catch (walletError) {
          if (walletError.message && walletError.message.includes('MetaMask is not installed')) {
            showToastMessage('MetaMask is not installed. Please install MetaMask to use this application.');
            console.warn('MetaMask is not installed. The application will have limited functionality.');
          } else {
            throw walletError; // Re-throw other errors to be caught by the outer catch block
          }
        }
        
      } catch (error) {
        console.error('Error connecting wallet:', error);
        showToastMessage('Failed to connect wallet: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
      }
    };

    // Load user data (fleets)
    const loadUserData = async () => {
      try {
        if (!isConnected.value || !registryContract.value) return;
        
        setLoadingWithSafety(true);
        
        // Get available accounts
        availableAccounts.value = await web3.value.eth.getAccounts();
        
        // Get own fleet count
        ownFleetCount.value = await registryContract.value.methods.GetOwnFleetCount().call({ from: account.value });
        console.log('Own fleet count:', ownFleetCount.value);
        
        // Get own fleets
        ownFleets.value = [];
        for (let i = 0; i < ownFleetCount.value; i++) {
          const fleet = await registryContract.value.methods.GetOwnFleet(i).call({ from: account.value });
          ownFleets.value.push({
            owner: fleet.owner,
            fleet: fleet.fleet,
            createdAt: new Date(fleet.createdAt * 1000),
            updatedAt: new Date(fleet.updatedAt * 1000)
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
            sharedFleets.value.push({
              owner: fleet.owner,
              fleet: fleet.fleet,
              createdAt: new Date(fleet.createdAt * 1000),
              updatedAt: new Date(fleet.updatedAt * 1000)
            });
          }
        }
        
      } catch (error) {
        console.error('Error loading user data:', error);
        showToastMessage('Failed to load fleet data: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
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
        showToastMessage('Failed to switch account: ' + error.message);
      }
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
        setLoadingWithSafety(true);
        
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
        showToastMessage('Failed to load fleet data: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
      }
    };

    // Add fleet user from manager
    const addFleetUserFromManager = async () => {
      try {
        if (!isValidAddress(newFleetUserAddress.value)) {
          showToastMessage('Please enter a valid Ethereum address');
          return;
        }
        
        setLoadingWithSafety(true);
        
        await registryContract.value.methods.AddFleetUser(
          managedFleet.value,
          newFleetUserAddress.value
        ).send({ from: account.value });
        
        // Refresh fleet users
        managedFleetUsers.value.push(newFleetUserAddress.value);
        
        newFleetUserAddress.value = '';
        showToastMessage('User added successfully!');
      } catch (error) {
        console.error('Error adding fleet user:', error);
        showToastMessage('Failed to add user: ' + error.message);
      } finally {
        setLoadingWithSafety(false);
      }
    };

    // Initialize
    onMounted(async () => {
      try {
        await initializeMetaMask();
        
        // Auto-connect if already connected
        if (ethereum.value && ethereum.value.selectedAddress) {
          await connectWallet();
        }
      } catch (error) {
        console.error('Error initializing app:', error);
      }
    });

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
      
      // Tag management
      tags,
      selectedTag,
      newTagData,
      tagDevices,
      
      // Methods
      connectWallet,
      createFleet,
      viewFleetDetails,
      addFleetUser,
      removeFleetUser,
      closeFleetManagementModal,
      addFleetUserFromManager,
      updateFleetLabel,
      
      // Utility functions
      shortenAddress,
      formatDate,
      isValidAddress,
      switchAccount,
      changeAccount,
      manageFleet,
      
      // User management
      loadAllUsers,
      selectUser,
      createNewUser,
      updateUserDetails,
      removeUserFromSystem,
      isUserAdmin,
      
      // User Group management
      loadUserGroups,
      selectUserGroup,
      loadGroupMembers,
      createUserGroup,
      updateUserGroup,
      removeUserGroup,
      addUserToGroup,
      removeUserFromGroup,
      
      // Device management
      loadDevices,
      selectDevice,
      loadDeviceTags,
      createNewDevice,
      updateDeviceDetails,
      updateDeviceLastSeen,
      transferDeviceDialog,
      transferDevice,
      removeDevice,
      addTagToDevice,
      removeTagFromDevice,
      
      // Tag management
      loadTags,
      selectTag,
      loadTagDevices,
      createTag,
      updateTag,
      removeTag,
      removeDeviceFromTag,
      
      // Navigation
      activePage: ref('dashboard'),
      showDashboard,
      showCreateFleetView,
      showFleetManagement,
      
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
}).mount('#app'); 