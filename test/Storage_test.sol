// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "../contracts/Storage.sol";

contract StorageTest is Storage {
    uint256 simple_number_1;
    mapping(uint256 => uint256) hash_number_2;
    uint256[] list_number_3;

    constructor() {}

    function testSimple() public {
        uint256 slot;
        assembly { slot := simple_number_1.slot }

        simple_number_1 = 15;
        Assert.equal(simple_number_1, at(slot), "at() should return the same");

        set_at(slot, 16);
        Assert.equal(simple_number_1, 16, "set_at() should set the value");
    }

    function testHash() public {
        uint256 slot;
        assembly { slot := hash_number_2.slot }

        hash_number_2[349] = 15;
        Assert.equal(hash_number_2[349], hash_at(slot, 349), "hash_at() should return the same");

        hash_set_at(slot, 349, 16);
        Assert.equal(hash_number_2[349], 16, "hash_set_at() should set the value");
    }

    function testList() public {
        uint256 slot;
        assembly { slot := list_number_3.slot }

        list_number_3.push(15);
        Assert.equal(list_number_3[0], list_at(slot, 0), "list_at() should return the same");
        Assert.equal(1, list_size(slot), "list_size() should be one");

        Assert.equal(15, list_pop(slot), "list_pop() should return 15");
        Assert.equal(0, list_size(slot), "list_size() should return 0");

        list_push(slot, 38);
        Assert.equal(1, list_size(slot), "list_size() should return 1");
        Assert.equal(list_number_3[0], list_at(slot, 0), "list_at() should return the same");
        Assert.equal(38, list_at(slot, 0), "list_at() should return the same");
        list_set_at(slot, 0, 39);
        Assert.equal(39, list_number_3[0], "list_at() should return the same");

    }
}
