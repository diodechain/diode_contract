// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./Storage.sol";
import "./deps/OwnableInitializable.sol";
import "./deps/Set.sol";

/**
 * Generic Group
 */
contract Group is Storage, OwnableInitializable {
    using Set for Set.Data;
    Set.Data members;

    constructor() public {
    }

    // function initialize(address _owner) public initializer {
    //     OwnableInitializable.initialize(_owner);
    // }
}