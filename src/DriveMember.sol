// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./deps/OwnableInitializable.sol";
import "./deps/Set.sol";

/**
 * Drive Smart Contract
 */
contract DriveMember is OwnableInitializable {
    using Set for Set.Data;
    Set.Data members;
    address drive;

    modifier onlyMember {
        require(members.isMember(msg.sender), "Only members can call this");

        _;
    }

    constructor() public {
        initialize(msg.sender);
    }

    function Version() external virtual pure returns (int256) {
        return 100;
    }

    function AddMember(address _member) external onlyMember {
        members.add(_member);
    }


    function RemoveMember(address _member) external onlyMember {
        members.remove(_member);
    }

    function Destroy() external onlyMember {
        selfdestruct(msg.sender);
    }

    function Drive() public view returns (address) {
        return drive;
    }

    function SetDrive(address _drive) external virtual onlyOwner {
        drive = _drive;
    }

    function SubmitTransaction(bytes memory data) public onlyMember
    {
        require(external_call(data.length, data), "Transaction failed");
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(uint _dataLength, bytes memory _data) internal returns (bool) {
        address destination = drive;
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(_data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                0,                 // value is always zero
                d,
                _dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}
