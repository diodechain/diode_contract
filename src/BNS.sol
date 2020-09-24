// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/**
 * BNS Blockchain Name System
 */
contract BNS {
  struct BNSEntry {
      address   destination;
      address   owner;
      string    name;
      address[] destinations;
      string[]  properties;
      uint256   lockEnd;
      uint256   leaseEnd;
  }

  address public _reserved;
  mapping(bytes32 => BNSEntry) public names;

  struct ReverseEntry {
    string name;
    address setter;
  }

  mapping(address => ReverseEntry) public reverse;

  function Version() external pure returns (int) {
    return 300;
  }

  /**
   * Resolve `_name` and return one of the registered destinations.
   * @param _name the name to be resolved.
   */
  function Resolve(string calldata _name) external view returns (address) {
      BNSEntry memory current = resolveEntry(_name);
      if (current.destinations.length == 0)
        return current.destination;

      return current.destinations[block.number % current.destinations.length];
  }

  /**
   * Resolve `_name` and return one of the full BNSEntry.
   * @param _name the name to be resolved.
   */
  function ResolveEntry(string calldata _name) external view returns (BNSEntry memory) {
    return resolveEntry(_name);
  }

  /**
   * Resolve `_name` and return the owner.
   * @param _name the name to be resolved.
   */
  function ResolveOwner(string calldata _name) external view returns (address) {
    return resolveEntry(_name).owner;
  }

  /**
   * Registers `_name` and assigns it to a single `_destination` address.
   * @param _name the name to be created.
   * @param _destination the single destination to be assigned.
   */
  function Register(string calldata _name, address _destination) external {
    register(_name, _destination);
  }

  /**
   * Transfers the ownership in `_name` to the new owner `_newowner`.
   * @param _name the name to be transferred.
   * @param _newowner the new owner to be assigned.
   */
  function TransferOwner(string calldata _name, address _newowner) external {
    BNSEntry storage current = names[convert(_name)];
    require(current.owner == msg.sender && block.number < current.leaseEnd, "This name is not registered by you");
    current.owner = _newowner;
  }

  /**
   * Renames the domain `_name` if and only if the new name `_newname` is free.
   * @param _name the name to be changed.
   * @param _newname the new name.
   */
  function Rename(string calldata _name, string calldata _newname) external {
    bytes32 key = convert(_name);
    BNSEntry storage current = names[key];
    require(current.owner == msg.sender && block.number < current.leaseEnd, "This name is not registered by you");
    BNSEntry storage newentry = names[convert(_newname)];
    require(block.number > newentry.lockEnd, "This name is not registered by you");
    newentry = current;
    delete names[key];
  }

  /**
   * Registers `_name` and assigns it to multiple `_destinations` addresses.
   * @param _name the name to be created.
   * @param _destinations array of destinations to be assigned.
   */
  function RegisterMultiple(string calldata _name, address[] calldata _destinations) external {
      registerMultiple(_name, _destinations);
  }

  /**
   * RegisterHash `_hash` is a hashed name that is beeing assigned it to a single `_destination` address.
   * @param _hash the hash of the name to be registered.
   * @param _destination the single destination to be assigned.
   * @dev disabled because we can't currently protect against allocation of random names.
   */
  // function RegisterHash(bytes32 _hash, address _destination) external {
  //     register(_hash, _destination);
  // }

  /**
   * RegisterHashMultiple `_hash` is a hashed name that is beeing assigned it to multiple `_destinations` address.
   * @param _hash the hash of the name to be registered.
   * @param _destination the single destination to be assigned.
   * @dev disabled because we can't currently protect against allocation of random names.
   */
  // function RegisterHashMultiple(bytes32 _hash, address[] calldata _destinations) external {
  //     registerMultiple(_hash, _destinations);
  // }

  /**
   * Unregister `_name` is a hashed name that is beeing deleted.
   * @param _name the name to be deleted.
   */
  function Unregister(string calldata _name) external {
      bytes32 key = convert(_name);
      BNSEntry memory current = names[key];
      require(current.owner == msg.sender || (block.number > current.lockEnd && current.lockEnd > 0), "This name is not yours to unregister");
      delete names[key];
  }

  // /**
  //  * Unregister `_hash` is a hashed name that is beeing deleted.
  //  * @param _hash the hash of the name to be deleted.
  //  */
  // function UnregisterHash(bytes32 _hash) external {
  //     BNSEntry memory current = names[_hash];
  //     require(current.owner == msg.sender || block.number > current.lockEnd, "This entry is not yours to unregister");
  //     delete names[_hash];
  // }

  /**
   * AddProperty adds a new property to the domain.
   * @param _name the name of the domain.
   * @param _property the property string to be added.
   */
  function AddProperty(string calldata _name, string calldata _property) external {
    BNSEntry storage current = names[convert(_name)];
    require(current.owner == msg.sender && block.number < current.leaseEnd, "This name is not registered by you");
    current.properties.push(_property);
  }

  /**
   * DeleteProperty remove a property from the domain.
   * @param _name the name of the domain.
   * @param _idx the zero based index of the property to be deleted.
   */
  function DeleteProperty(string calldata _name, uint256 _idx) external {
    BNSEntry storage current = names[convert(_name)];
    require(current.owner == msg.sender && block.number < current.leaseEnd, "This name is not registered by you");
    uint256 last = current.properties.length - 1;
    require(_idx <= last, "Index out of bounds");
    if (_idx != last) {
      current.properties[_idx] = current.properties[last];
    }
    current.properties.pop();
  }

  /**
   * GetProperty retrieves the indexed property of a domain.
   * @param _name the name of the domain.
   * @param _idx the zero based index of the property to be retrieved.
   */
  function GetProperty(string calldata _name, uint256 _idx) external view returns (string memory) {
    return resolveEntry(_name).properties[_idx];
  }

  /**
   * GetPropertyLength retrieves the number of properties for a domain.
   * @param _name the name of the domain.
   */
  function GetPropertyLength(string calldata _name) external view returns (uint256) {
    return resolveEntry(_name).properties.length;
  }

  /**
   * GetProperties retrieves all properties of a domain.
   * @param _name the name of the domain.
   */
  function GetProperties(string calldata _name) external view returns (string[] memory) {
    return resolveEntry(_name).properties;
  }

  /**
   * RegisterReverse sets at reverse lookup entry from `_address` to `_name`.
   * This requires an existing forward lookup from `_name` to `_address`.
   *
   * @param _name the name to be created.
   * @param _address the single destination to be assigned.
   */
  function RegisterReverse(address _address, string calldata _name) external {
    BNSEntry memory entry = resolveEntry(_name);
    forwardLookup(_address, entry);

    if (reverse[_address].setter == _address)
      require(msg.sender == _address, "Only the address owner can override an authorized entry.");

    reverse[_address] = ReverseEntry(_name, msg.sender);
  }

  /**
   * ResolveReverse resolves `_address` into a single name if a reverse lookup entry has
   * been created before using `RegisterReverse(address,string)`.
   * @param _address the name to be created.
   */
  function ResolveReverse(address _address) external view returns (string memory) {
    ReverseEntry memory rentry = reverse[_address];
    if (bytes(rentry.name).length == 0) {
      return rentry.name;
    }
    BNSEntry memory entry = resolveEntry(rentry.name);
    forwardLookup(_address, entry);
    return rentry.name;
  }

  /*******************************************************
   ***********   INTERNAL FUNCTIONS **********************
   *******************************************************/
  function register(string memory _name, address destination) internal {
      address[] memory destinations = new address[](1);
      destinations[0] = destination;
      registerMultiple(_name, destinations);
  }

  function registerMultiple(string memory _name, address[] memory destinations) internal {
    bytes32 _hash = convert(_name);

    BNSEntry memory current = names[_hash];
    require(current.owner == msg.sender || current.owner == address(0) || (block.number > current.lockEnd && current.lockEnd > 0), "This name is already taken");
    current.destination = destinations[0];
    current.destinations = destinations;
    current.owner = msg.sender;
    current.name = _name;
    current.leaseEnd = block.number + 518400;
    current.lockEnd = block.number + 518400 * 2;
    names[_hash] = current;
  }

  function forwardLookup(address _address, BNSEntry memory entry) internal pure {
    if (entry.destination != _address) {
      for (uint i = 0; i < entry.destinations.length; i++) {
        if (entry.destinations[i] == _address)
          break;
        else if (i == entry.destinations.length - 1)
          revert("Forward lookup failed");
      }
    }
  }

  function convert(string memory name) internal pure returns (bytes32) {
    validate(name);
    return keccak256(bytes(name));
  }

  function validate(string memory name) internal pure {
    bytes memory b = bytes(name);

    require(b.length > 7, "Names must be longer than 7 characters");
    require(b.length <= 32, "Names must be within 32 characters");

    for(uint i; i < b.length; i++) {
      bytes1 char = b[i];

      require(
        (char >= 0x30 && char <= 0x39) || //9-0
        (char >= 0x41 && char <= 0x5A) || //A-Z
        (char >= 0x61 && char <= 0x7A) || //a-z
        (char == 0x2D), //-
        "Names can only contain: [0-9A-Za-z-]");
    }
  }

  function resolveEntry(string memory _name) internal view returns (BNSEntry memory) {
    BNSEntry memory current = names[convert(_name)];
    if (block.number < current.leaseEnd)
      return current;

    BNSEntry memory empty;
    return empty;
  }
}
