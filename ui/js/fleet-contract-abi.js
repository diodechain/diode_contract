const fleetContractAbi = [
  {
      "type": "constructor",
      "inputs": [],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "Accountant",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "address",
              "internalType": "address"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "DeviceAllowlist",
      "inputs": [
          {
              "name": "_client",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "Operator",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "address",
              "internalType": "address"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "SetDeviceAllowlist",
      "inputs": [
          {
              "name": "_client",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_value",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "SetDeviceWhitelist",
      "inputs": [
          {
              "name": "_client",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_value",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "accountant",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "address",
              "internalType": "address payable"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "addDeviceToTag",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "addUserToGroup",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "createDevice",
      "inputs": [
          {
              "name": "_name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_deviceType",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_location",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "createTag",
      "inputs": [
          {
              "name": "_name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_color",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "createUser",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_nickname",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_email",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_avatarURI",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "createUserGroup",
      "inputs": [
          {
              "name": "_name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_description",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "deviceWhitelist",
      "inputs": [
          {
              "name": "_client",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getAllDevices",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "address[]",
              "internalType": "address[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getAllTags",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "bytes32[]",
              "internalType": "bytes32[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getAllUserGroups",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "bytes32[]",
              "internalType": "bytes32[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getAllUsers",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "address[]",
              "internalType": "address[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getDevice",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "id",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "owner",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "deviceType",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "location",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "createdAt",
              "type": "uint256",
              "internalType": "uint256"
          },
          {
              "name": "lastSeen",
              "type": "uint256",
              "internalType": "uint256"
          },
          {
              "name": "active",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getDeviceProperty",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "string",
              "internalType": "string"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getDeviceTags",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32[]",
              "internalType": "bytes32[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getGroupUsers",
      "inputs": [
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "address[]",
              "internalType": "address[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getPropertyValue",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "string",
              "internalType": "string"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getPropertyValueDirect",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "string",
              "internalType": "string"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getTag",
      "inputs": [
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "id",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "color",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "createdAt",
              "type": "uint256",
              "internalType": "uint256"
          },
          {
              "name": "createdBy",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "active",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getTagDevices",
      "inputs": [
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32[]",
              "internalType": "bytes32[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getTagProperty",
      "inputs": [
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "string",
              "internalType": "string"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getUser",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "user",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "nickname",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "email",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "avatarURI",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "isAdmin",
              "type": "bool",
              "internalType": "bool"
          },
          {
              "name": "createdAt",
              "type": "uint256",
              "internalType": "uint256"
          },
          {
              "name": "active",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getUserDevices",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32[]",
              "internalType": "bytes32[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getUserGroup",
      "inputs": [
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "id",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "createdAt",
              "type": "uint256",
              "internalType": "uint256"
          },
          {
              "name": "createdBy",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "active",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "getUserGroups",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bytes32[]",
              "internalType": "bytes32[]"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "hasProperty",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "initialize",
      "inputs": [
          {
              "name": "_owner",
              "type": "address",
              "internalType": "address payable"
          }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "initialize",
      "inputs": [
          {
              "name": "_owner",
              "type": "address",
              "internalType": "address payable"
          },
          {
              "name": "_label",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "isDeviceInTag",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "isDeviceOwner",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "isUserAdmin",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "isUserInGroup",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "label",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "string",
              "internalType": "string"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "operator",
      "inputs": [],
      "outputs": [
          {
              "name": "",
              "type": "address",
              "internalType": "address"
          }
      ],
      "stateMutability": "view"
  },
  {
      "type": "function",
      "name": "removeDevice",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "removeDeviceFromTag",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "removeTag",
      "inputs": [
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "removeUser",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "removeUserFromGroup",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "removeUserGroup",
      "inputs": [
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "setDeviceProperty",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_value",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "setTagProperty",
      "inputs": [
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_key",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_value",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "setUserAdmin",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_isAdmin",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "transferDeviceOwnership",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_newOwner",
              "type": "address",
              "internalType": "address"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "updateDevice",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_deviceType",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_location",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "updateDeviceLastSeen",
      "inputs": [
          {
              "name": "_deviceId",
              "type": "bytes32",
              "internalType": "bytes32"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "updateLabel",
      "inputs": [
          {
              "name": "_newLabel",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "updateTag",
      "inputs": [
          {
              "name": "_tagId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_description",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_color",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "updateUser",
      "inputs": [
          {
              "name": "_userAddress",
              "type": "address",
              "internalType": "address"
          },
          {
              "name": "_nickname",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_email",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_avatarURI",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "function",
      "name": "updateUserGroup",
      "inputs": [
          {
              "name": "_groupId",
              "type": "bytes32",
              "internalType": "bytes32"
          },
          {
              "name": "_name",
              "type": "string",
              "internalType": "string"
          },
          {
              "name": "_description",
              "type": "string",
              "internalType": "string"
          }
      ],
      "outputs": [
          {
              "name": "",
              "type": "bool",
              "internalType": "bool"
          }
      ],
      "stateMutability": "nonpayable"
  },
  {
      "type": "event",
      "name": "DeviceAddedToTag",
      "inputs": [
          {
              "name": "deviceId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "tagId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "DeviceCreated",
      "inputs": [
          {
              "name": "deviceId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "owner",
              "type": "address",
              "indexed": false,
              "internalType": "address"
          },
          {
              "name": "name",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "DevicePropertySet",
      "inputs": [
          {
              "name": "deviceId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "key",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          },
          {
              "name": "value",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "DeviceRemoved",
      "inputs": [
          {
              "name": "deviceId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "DeviceRemovedFromTag",
      "inputs": [
          {
              "name": "deviceId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "tagId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "DeviceUpdated",
      "inputs": [
          {
              "name": "deviceId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "FleetLabelUpdated",
      "inputs": [
          {
              "name": "newLabel",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "TagCreated",
      "inputs": [
          {
              "name": "tagId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "TagPropertySet",
      "inputs": [
          {
              "name": "tagId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "key",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          },
          {
              "name": "value",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "TagRemoved",
      "inputs": [
          {
              "name": "tagId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "TagUpdated",
      "inputs": [
          {
              "name": "tagId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserAddedToGroup",
      "inputs": [
          {
              "name": "userAddress",
              "type": "address",
              "indexed": true,
              "internalType": "address"
          },
          {
              "name": "groupId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserCreated",
      "inputs": [
          {
              "name": "userAddress",
              "type": "address",
              "indexed": true,
              "internalType": "address"
          },
          {
              "name": "nickname",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserGroupCreated",
      "inputs": [
          {
              "name": "groupId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserGroupRemoved",
      "inputs": [
          {
              "name": "groupId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserGroupUpdated",
      "inputs": [
          {
              "name": "groupId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          },
          {
              "name": "name",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserRemoved",
      "inputs": [
          {
              "name": "userAddress",
              "type": "address",
              "indexed": true,
              "internalType": "address"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserRemovedFromGroup",
      "inputs": [
          {
              "name": "userAddress",
              "type": "address",
              "indexed": true,
              "internalType": "address"
          },
          {
              "name": "groupId",
              "type": "bytes32",
              "indexed": true,
              "internalType": "bytes32"
          }
      ],
      "anonymous": false
  },
  {
      "type": "event",
      "name": "UserUpdated",
      "inputs": [
          {
              "name": "userAddress",
              "type": "address",
              "indexed": true,
              "internalType": "address"
          },
          {
              "name": "nickname",
              "type": "string",
              "indexed": false,
              "internalType": "string"
          }
      ],
      "anonymous": false
  }
];

export default fleetContractAbi; 