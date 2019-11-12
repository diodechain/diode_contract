// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity 0.4.26;

library Utils {
  // spilit signature
  function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    require(sig.length == 65, "Wrong signature length");

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    return (v, r, s);
  }

  // bytesToAddress
  function bytesToAddress(bytes memory _addressBytes) internal pure returns (address) {
    address _address;
    assembly {
      _address := mload(add(_addressBytes, 32))
    }
    return _address;
  }

  // bytes32ToAddress
  function bytes32ToAddress(bytes32 _addressBytes) internal pure returns (address) {
    uint256 _address;
    assembly {
      _address := add(_addressBytes, 0)
    }
    return address(_address);
  }

  // bytes32Hash
  function bytes32Hash(bytes32[] memory _src) internal pure returns (bytes32) {
    uint256 _srcLen = _src.length;
    bytes memory _msg = new bytes(32 * _srcLen);
    for (uint256 i=0; i<_srcLen; i++) {
      for (uint256 j=0; j<32; j++) {
        _msg[i * 32 + j] = _src[i][j];
      }
    }
    return keccak256(_msg);
  }
}