// Diode Contracts
// Copyright 2020 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./Proxy.sol";

/**
 * Drive Smart Contract
 */
interface IInitializable {
    function initialize(address payable _owner) external;
}

contract DriveFactory {
    function Create(address payable _owner, address _target)
        public
        returns (address)
    {
        address addr = address(new Proxy(_target, _owner));
        IInitializable(addr).initialize(_owner);
        return addr;
    }

    function Create2(
        address payable _owner,
        bytes32 _salt,
        address _target
    ) public returns (address) {
        address payable addr;
        // These are the first two arguments of Proxy(_target, _owner)
        bytes memory code = abi.encodePacked(
            _target,
            _owner,
            type(Proxy).creationCode
        );
        bytes32 salt = keccak256(abi.encodePacked(_salt, msg.sender));

        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        IInitializable(addr).initialize(_owner);
        return addr;
    }

    function Create2Address(
        address payable _owner,
        bytes32 _salt,
        address _target
    ) public view returns (address) {
        bytes32 contractCodeHash = keccak256(
            abi.encodePacked(_target, _owner, type(Proxy).creationCode)
        );
        bytes32 salt = keccak256(abi.encodePacked(_salt, msg.sender));

        bytes32 rawAddress = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                contractCodeHash
            )
        );

        return address(bytes20(rawAddress << 96));
    }
}
