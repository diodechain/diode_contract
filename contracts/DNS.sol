// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity 0.4.26;

/**
 * DNS Diode Name System
 *
 */
contract DNS {
  struct Meta {
      address destination;
      address owner;
      string  name;
  }

  address public operator;
  mapping(bytes32 => Meta) public names;

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  constructor (address _operator) public {
    operator = _operator;
  }

  function Resolve(string name) public view returns (address) {
      return names[convert(name)].destination;
  }

  function Register(string name, address destination) public {
      validate(name);
      bytes32 key = convert(name);
      Meta memory current = names[key];
      require(current.owner == address(0) || current.owner == msg.sender, "This name is already taken");
      current.destination = destination;
      if (current.owner == address(0)) {
          current.owner = msg.sender;
          current.name = name;
      }
      names[key] = current;
  }
  
  function convert(string name) internal pure returns (bytes32) {
      return keccak256(bytes(name));
  }

  function validate(string name) internal pure {
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
