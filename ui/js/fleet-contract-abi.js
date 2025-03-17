// ABI for IoTFleetContract
const fleetContractAbi = [
  {
    "inputs": [],
    "name": "label",
    "outputs": [{"type": "string", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "string", "name": "_newLabel"}],
    "name": "updateLabel",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  // User Management
  {
    "inputs": [
      {"type": "address", "name": "_userAddress"}, 
      {"type": "string", "name": "_nickname"}, 
      {"type": "string", "name": "_email"}, 
      {"type": "string", "name": "_avatarURI"}
    ],
    "name": "createUser",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "address", "name": "_userAddress"}, 
      {"type": "string", "name": "_nickname"}, 
      {"type": "string", "name": "_email"}, 
      {"type": "string", "name": "_avatarURI"}
    ],
    "name": "updateUser",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}, {"type": "bool", "name": "_isAdmin"}],
    "name": "setUserAdmin",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}],
    "name": "removeUser",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}],
    "name": "getUser",
    "outputs": [
      {"type": "address", "name": "user"}, 
      {"type": "string", "name": "nickname"}, 
      {"type": "string", "name": "email"}, 
      {"type": "string", "name": "avatarURI"}, 
      {"type": "bool", "name": "isAdmin"}, 
      {"type": "uint256", "name": "createdAt"}, 
      {"type": "bool", "name": "active"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}],
    "name": "getUserGroups",
    "outputs": [{"type": "bytes32[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllUsers",
    "outputs": [{"type": "address[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  // User Group Management
  {
    "inputs": [{"type": "string", "name": "_name"}, {"type": "string", "name": "_description"}],
    "name": "createUserGroup",
    "outputs": [{"type": "bytes32", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_groupId"}, {"type": "string", "name": "_name"}, {"type": "string", "name": "_description"}],
    "name": "updateUserGroup",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_groupId"}],
    "name": "removeUserGroup",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}, {"type": "bytes32", "name": "_groupId"}],
    "name": "addUserToGroup",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}, {"type": "bytes32", "name": "_groupId"}],
    "name": "removeUserFromGroup",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_groupId"}],
    "name": "getUserGroup",
    "outputs": [
      {"type": "bytes32", "name": "id"}, 
      {"type": "string", "name": "name"}, 
      {"type": "string", "name": "description"}, 
      {"type": "uint256", "name": "createdAt"}, 
      {"type": "address", "name": "createdBy"}, 
      {"type": "bool", "name": "active"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_groupId"}],
    "name": "getGroupUsers",
    "outputs": [{"type": "address[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllUserGroups",
    "outputs": [{"type": "bytes32[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  // Device Management
  {
    "inputs": [
      {"type": "string", "name": "_name"}, 
      {"type": "string", "name": "_description"}, 
      {"type": "string", "name": "_deviceType"}, 
      {"type": "string", "name": "_location"}
    ],
    "name": "createDevice",
    "outputs": [{"type": "bytes32", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "_deviceId"}, 
      {"type": "string", "name": "_name"}, 
      {"type": "string", "name": "_description"}, 
      {"type": "string", "name": "_deviceType"}, 
      {"type": "string", "name": "_location"}
    ],
    "name": "updateDevice",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}],
    "name": "updateDeviceLastSeen",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}, {"type": "address", "name": "_newOwner"}],
    "name": "transferDeviceOwnership",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}],
    "name": "removeDevice",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}],
    "name": "getDevice",
    "outputs": [
      {"type": "bytes32", "name": "id"},
      {"type": "address", "name": "owner"},
      {"type": "string", "name": "name"},
      {"type": "string", "name": "description"},
      {"type": "string", "name": "deviceType"},
      {"type": "string", "name": "location"},
      {"type": "uint256", "name": "createdAt"},
      {"type": "uint256", "name": "lastSeen"},
      {"type": "bool", "name": "active"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}],
      "name": "getUserDevices",
      "outputs": [{"type": "bytes32[]", "name": ""}],
      "stateMutability": "view",
      "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllDevices",
    "outputs": [{"type": "bytes32[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  // Tag Management
  {
    "inputs": [{"type": "string", "name": "_name"}, {"type": "string", "name": "_description"}, {"type": "string", "name": "_color"}],
    "name": "createTag",
    "outputs": [{"type": "bytes32", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_tagId"}, {"type": "string", "name": "_name"}, {"type": "string", "name": "_description"}, {"type": "string", "name": "_color"}],
    "name": "updateTag",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_tagId"}],
    "name": "removeTag",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}, {"type": "bytes32", "name": "_tagId"}],
    "name": "addDeviceToTag",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}, {"type": "bytes32", "name": "_tagId"}],
    "name": "removeDeviceFromTag",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_tagId"}],
    "name": "getTag",
    "outputs": [
      {"type": "bytes32", "name": "id"}, 
      {"type": "string", "name": "name"}, 
      {"type": "string", "name": "description"}, 
      {"type": "string", "name": "color"}, 
      {"type": "uint256", "name": "createdAt"}, 
      {"type": "address", "name": "createdBy"}, 
      {"type": "bool", "name": "active"}
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}],
    "name": "getDeviceTags",
    "outputs": [{"type": "bytes32[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_tagId"}],
    "name": "getTagDevices",
    "outputs": [{"type": "bytes32[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllTags",
    "outputs": [{"type": "bytes32[]", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  // Access Control
  {
    "inputs": [{"type": "address", "name": "_userAddress"}, {"type": "bytes32", "name": "_groupId"}],
    "name": "isUserInGroup",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"type": "bytes32", "name": "_deviceId"}, {"type": "bytes32", "name": "_tagId"}],
      "name": "isDeviceInTag",
      "outputs": [{"type": "bool", "name": ""}],
      "stateMutability": "view",
      "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}],
      "name": "isUserAdmin",
      "outputs": [{"type": "bool", "name": ""}],
      "stateMutability": "view",
      "type": "function"
  },
  {
    "inputs": [{"type": "address", "name": "_userAddress"}, {"type": "bytes32", "name": "_deviceId"}],
    "name": "isDeviceOwner",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  // Property Management
  {
    "inputs": [
      {"type": "bytes32", "name": "_deviceId"}, 
      {"type": "string", "name": "_key"}, 
      {"type": "string", "name": "_value"}
    ],
    "name": "setDeviceProperty",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "_deviceId"}, 
      {"type": "string", "name": "_key"}
    ],
    "name": "getDeviceProperty",
    "outputs": [{"type": "string", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "_tagId"}, 
      {"type": "string", "name": "_key"}, 
      {"type": "string", "name": "_value"}
    ],
    "name": "setTagProperty",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "_tagId"}, 
      {"type": "string", "name": "_key"}
    ],
    "name": "getTagProperty",
    "outputs": [{"type": "string", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "_deviceId"}, 
      {"type": "string", "name": "_key"}
    ],
    "name": "getPropertyValue",
    "outputs": [{"type": "string", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {"type": "bytes32", "name": "_deviceId"}, 
      {"type": "string", "name": "_key"}
    ],
    "name": "hasProperty",
    "outputs": [{"type": "bool", "name": ""}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "device",
        "type": "address"
      }
    ],
    "name": "addDevice",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "description",
        "type": "string"
      }
    ],
    "name": "addTag",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "addUser",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "description",
        "type": "string"
      }
    ],
    "name": "createUserGroup",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "index",
        "type": "uint256"
      }
    ],
    "name": "getDevice",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getDeviceCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getLabel",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getOwner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "index",
        "type": "uint256"
      }
    ],
    "name": "getTag",
    "outputs": [
      {
        "components": [
          {
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "internalType": "string",
            "name": "description",
            "type": "string"
          }
        ],
        "internalType": "struct Fleet.Tag",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getTagCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "index",
        "type": "uint256"
      }
    ],
    "name": "getUser",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getUserCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "index",
        "type": "uint256"
      }
    ],
    "name": "getUserGroup",
    "outputs": [
      {
        "components": [
          {
            "internalType": "string",
            "name": "name",
            "type": "string"
          },
          {
            "internalType": "string",
            "name": "description",
            "type": "string"
          }
        ],
        "internalType": "struct Fleet.UserGroup",
        "name": "",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getUserGroupCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "device",
        "type": "address"
      }
    ],
    "name": "removeDevice",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "tagId",
        "type": "uint256"
      }
    ],
    "name": "removeTag",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "removeUser",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "groupId",
        "type": "uint256"
      }
    ],
    "name": "removeUserGroup",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "newLabel",
        "type": "string"
      }
    ],
    "name": "updateLabel",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

export default fleetContractAbi; 