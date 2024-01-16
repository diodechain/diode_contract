pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "../contracts/Storage.sol";

contract StorageTest is Storage {
    uint256 simple_number_1;
    mapping(uint256 => uint256) hash_number_2;

    constructor() public {}

    function checkSimple() public {
        uint256 slot;
        assembly { slot := simple_number_1_slot }

        simple_number_1 = 15;
        Assert.equal(simple_number_1, at(slot), "at() should return the same");

        set_at(slot, 16);
        Assert.equal(simple_number_1, 16, "set_at() should set the value");
    }

    function checkHash() public {
        uint256 slot;
        assembly { slot := hash_number_2_slot }

        hash_number_2[349] = 15;
        Assert.equal(hash_number_2[349], hash_at(slot, 349), "hash_at() should return the same");

        hash_set_at(slot, 349, 16);
        Assert.equal(hash_number_2[349], 16, "hash_set_at() should set the value");
    }
}
