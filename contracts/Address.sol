// Diode Contracts
// Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity 0.4.26;

library Address {
  function IsContract(address _id) internal view returns(bool){
    uint256 size;
    assembly {
      size := extcodesize(_id)
    }
    return size > 0;
  }
}