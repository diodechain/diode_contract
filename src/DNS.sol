// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.0;

/**
 * BNS Blockchain Name System
 *
 */
contract NNS {
  struct Meta {
      address   destination;
      address   owner;
      string    name;
      address[] destinations;
      uint256   lockEnd;
      uint256   leaseEnd;
  }

  address public operator;
  mapping(bytes32 => Meta) public names;

  modifier onlyOperator {
    require(msg.sender == operator, "Only the operator can make this call");
    _;
  }

  constructor (address _operator) public {
    operator = _operator;
  }

  function Resolve(string calldata name) external view returns (address) {
      bytes32 key = convert(name);
      Meta memory current = names[key];
      if (block.number < current.leaseEnd) {
        if (current.destinations.length == 0)
          return current.destination;
        else
          return current.destinations[block.number % current.destinations.length];
      }
      else
        return address(0);
  }

  function Register(string calldata name, address destination) external {
      register(convert(name), destination);
  }

  function RegisterM(string calldata name, address[] calldata destinations) external {
      registerM(convert(name), destinations);
  }

  function RegisterHash(bytes32 key, address destination) external {
      register(key, destination);
  }

  function RegisterHashM(bytes32 key, address[] calldata destinations) external {
      registerM(key, destinations);
  }

  function Unregister(bytes32 key) external {
      Meta memory current = names[key];
      require(current.owner == msg.sender || block.number > current.lockEnd, "This name is not yours to unregister");
      delete names[key];
  }

  function register(bytes32 key, address destination) internal {
      address[] memory destinations = new address[](1);
      destinations[0] = destination;
      registerM(key, destinations);
  }

  function registerM(bytes32 key, address[] memory destinations) internal {
      Meta memory current = names[key];
      require(current.owner == msg.sender || block.number > current.lockEnd, "This name is already taken");
      current.destination = destinations[0];
      current.destinations = destinations;
      current.owner = msg.sender;
      current.leaseEnd = block.number + 518400;
      current.lockEnd = block.number + 518400 * 2;
      names[key] = current;
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
            (char == 0x2D) //-
        , "Names can only contain: [0-9A-Za-z-]");
    }
  }
}
