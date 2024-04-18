// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";

contract DelegateCall {
    int storage_id = 2; 
    address TARGET = msg.sender;
    fallback() external payable{
        assembly {
            let target := sload(TARGET.slot)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}


contract CallCode {
    int storage_id = 3; 
    address TARGET = msg.sender;
    fallback() external payable {
        assembly {
            let target := sload(TARGET.slot)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := callcode(gas(), target, 0, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}

contract Call {
    int constant storage_id = 4; 
    address TARGET = msg.sender;
    fallback() external payable {
        assembly {
            let target := sload(TARGET.slot)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := call(gas(), target, 0, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}

contract CallTest {
    int storage_id = 1; 
    address TARGET; 
    DelegateCall private dc;
    CallCode private cc;
    Call private ca;

    constructor() {
        TARGET = address(this);
        dc = new DelegateCall();
        cc = new CallCode();
        ca = new Call();
    }

    struct Info {
        address origin;
        address sender;
        address destination;
        uint value;
        int storage_id;
    }

    function getInfo() payable public returns (Info memory) {
        return Info(tx.origin, msg.sender, address(this), msg.value, storage_id);
    }

    function testDelegateCall() payable public {
        CallTest test = CallTest(address(dc));
        Info memory info = test.getInfo{value: 123}();

        Assert.equal(info.origin, tx.origin, "dc origin should match msg.origin");
        Assert.equal(info.sender, address(this), "dc sender should match address(this)");
        Assert.equal(info.destination, address(test), "dc destination should match address(test)");
        Assert.equal(info.value, 123, "dc value should match 123");
        Assert.equal(info.storage_id, 2, "dc storage_id should match 2");
    }

    function testCallCode() payable public {
        CallTest test = CallTest(address(cc));
        Info memory info = test.getInfo{value: 124}();

        Assert.equal(info.origin, tx.origin, "cc origin should match msg.origin");
        Assert.equal(info.sender, address(test), "cc sender should match address(test)");
        Assert.equal(info.destination, address(test), "cc destination should match address(test)");
        Assert.equal(info.value, 0, "cc value should match 0");
        Assert.equal(info.storage_id, 3, "cc storage_id should match 3");
    }

    function testCall() payable public {
        CallTest test = CallTest(address(ca));
        Info memory info = test.getInfo{value: 125}();

        Assert.equal(info.origin, tx.origin, "ca origin should match msg.origin");
        Assert.equal(info.sender, address(test), "ca sender should match address(test)");
        Assert.equal(info.destination, address(this), "ca destination should match address(this)");
        Assert.equal(info.value, 0, "ca value should match 0");
        Assert.equal(info.storage_id, 1, "ca storage_id should match 1");
    }
}
