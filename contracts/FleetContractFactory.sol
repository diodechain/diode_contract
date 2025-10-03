// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity >=0.8.20;

import "./Proxy8.sol";
import "./FleetContractUpgradeable.sol";
import "./deps/Ownable.sol";

contract FleetContractFactory is Ownable {
    mapping(address => address[]) creatorToFleetContract;
    mapping(address => address[]) operatorToFleetContract;
    mapping(address => address[]) accountantToFleetContract;
    address fleetContractImplementation;

    constructor(address _fleetContractImplementation) {
        fleetContractImplementation = _fleetContractImplementation;
    }

    function SetFleetContractImplementation(address _fleetContractImplementation) public onlyOwner {
        fleetContractImplementation = _fleetContractImplementation;
    }

    function GetFleetContractImplementation() public view returns (address) {
        return fleetContractImplementation;
    }

    function CreateFleetContract(address _operator, address payable _accountant) public returns (address) {
        FleetContractUpgradeable fleetContract =
            FleetContractUpgradeable(address(new Proxy8(fleetContractImplementation, msg.sender)));
        fleetContract.initialize(_operator, _accountant);
        creatorToFleetContract[msg.sender].push(address(fleetContract));
        operatorToFleetContract[_operator].push(address(fleetContract));
        accountantToFleetContract[_accountant].push(address(fleetContract));
        return address(fleetContract);
    }

    function GetCreatorFleetContractCount(address _creator) public view returns (uint256) {
        return creatorToFleetContract[_creator].length;
    }

    function GetOperatorFleetContractCount(address _operator) public view returns (uint256) {
        return operatorToFleetContract[_operator].length;
    }

    function GetAccountantFleetContractCount(address _accountant) public view returns (uint256) {
        return accountantToFleetContract[_accountant].length;
    }

    function GetOperatorFleetContract(address _operator, uint256 _index) public view returns (address) {
        return operatorToFleetContract[_operator][_index];
    }

    function GetAccountantFleetContract(address _accountant, uint256 _index) public view returns (address) {
        return accountantToFleetContract[_accountant][_index];
    }

    function GetCreatorFleetContract(address _creator, uint256 _index) public view returns (address) {
        return creatorToFleetContract[_creator][_index];
    }
}
