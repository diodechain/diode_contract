// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";

contract Create2Test {
    bytes constant contractBytecode =
        hex"608060405234801561001057600080fd5b5061015d806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c806306fdde031461003b5780637872ab4914610059575b600080fd5b61004361009d565b6040518082815260200191505060405180910390f35b61009b6004803603602081101561006f57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291905050506100c5565b005b60007f736d617278000000000000000000000000000000000000000000000000000000905090565b8073ffffffffffffffffffffffffffffffffffffffff1663380c7a676040518163ffffffff1660e01b8152600401600060405180830381600087803b15801561010d57600080fd5b505af1158015610121573d6000803e3d6000fd5b505050505056fea265627a7a72315820fb2fc7a07f0eebf799c680bb1526641d2d905c19393adf340a04e48c9b527de964736f6c634300050c0032";
    bytes32 constant salt = hex"000102030405060708090A0B0C0D0E0F000102030405060708090A0B0C0D0E0F";
    address public result = address(0x0);
    address public result2 = address(0x0);

    function transfer(address payable to) public payable {
        to.transfer(msg.value);
    }

    function executeCreate2() public {
        bytes memory bytecode = contractBytecode;
        address addr;

        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        result2 = addr;
    }

    function executeCreate() public {
        bytes memory bytecode = contractBytecode;
        address addr;

        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        result = addr;
    }
}
