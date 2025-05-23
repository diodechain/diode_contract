// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IBNS.sol";
import "./ChangeTracker.sol";

/**
 * BNS Blockchain Name System
 */
contract BNS is IBNS, ChangeTracker {
    address public _reserved;
    mapping(bytes32 => BNSEntry) public names;

    struct ReverseEntry {
        string name;
        address setter;
    }

    mapping(address => ReverseEntry) public reverse;
    bytes32[] public namesIndex;

    function Version() external pure override returns (int256) {
        return 318;
    }

    /**
     * Resolve `_name` and return one of the registered destinations.
     * @param _name the name to be resolved.
     */
    function Resolve(string calldata _name) external view override returns (address) {
        BNSEntry memory current = resolveEntry(_name);
        if (current.destinations.length == 0) {
            return current.destination;
        }

        return current.destinations[block.number % current.destinations.length];
    }

    /**
     * Resolve `_name` and return one of the registered destinations.
     * @param _name the name to be resolved.
     */
    function ResolveAll(string calldata _name) external view override returns (address[] memory) {
        BNSEntry memory current = resolveEntry(_name);
        if (current.destinations.length == 0) {
            address[] memory destinations = new address[](1);
            destinations[0] = current.destination;
            return destinations;
        }

        return current.destinations;
    }

    /**
     * Resolve `_name` and return one of the full BNSEntry.
     * @param _name the name to be resolved.
     */
    function ResolveEntry(string calldata _name) external view override returns (BNSEntry memory) {
        return resolveEntry(_name);
    }

    /**
     * Resolve `_name` and return the owner.
     * @param _name the name to be resolved.
     */
    function ResolveOwner(string calldata _name) external view override returns (address) {
        return resolveEntry(_name).owner;
    }

    /**
     * Registers `_name` and assigns it to a single `_destination` address.
     * @param _name the name to be created.
     * @param _destination the single destination to be assigned.
     */
    function Register(string calldata _name, address _destination) external override {
        register(_name, _destination);
    }

    /**
     * Transfers the ownership in `_name` to the new owner `_newowner`.
     * @param _name the name to be transferred.
     * @param _newowner the new owner to be assigned.
     */
    function TransferOwner(string calldata _name, address _newowner) external override {
        BNSEntry storage current = names[convert(_name)];
        requireOnlyOwner(current);
        current.owner = _newowner;
        update_change_tracker();
    }

    /**
     * Renames the domain `_name` if and only if the new name `_newname` is free.
     * @param _name the name to be changed.
     * @param _newname the new name.
     */
    function Rename(string calldata _name, string calldata _newname) external override {
        bytes32 key = convert(_name);
        BNSEntry storage current = names[key];
        requireOnlyOwner(current);
        BNSEntry storage newentry = names[convert(_newname)];
        require(!isLocked(newentry), "The new name is not available you");
        newentry = current;
        delete names[key];
        update_change_tracker();
    }

    /**
     * Registers `_name` and assigns it to multiple `_destinations` addresses.
     * @param _name the name to be created.
     * @param _destinations array of destinations to be assigned.
     */
    function RegisterMultiple(string calldata _name, address[] calldata _destinations) external override {
        registerMultiple(_name, _destinations);
    }

    /**
     * Unregister `_name` is a hashed name that is beeing deleted.
     * @param _name the name to be deleted.
     */
    function Unregister(string calldata _name) external override {
        bytes32 key = convert(_name);
        BNSEntry memory current = names[key];
        require(current.owner == msg.sender || !isLocked(current), "This name is not yours to unregister");
        delete names[key];
        update_change_tracker();
    }

    /**
     * AddProperty adds a new property to the domain.
     * @param _name the name of the domain.
     * @param _property the property string to be added.
     */
    function AddProperty(string calldata _name, string calldata _property) external override {
        BNSEntry storage current = names[convert(_name)];
        requireOnlyOwner(current);
        current.properties.push(_property);
        update_change_tracker();
    }

    /**
     * DeleteProperty remove a property from the domain.
     * @param _name the name of the domain.
     * @param _idx the zero based index of the property to be deleted.
     */
    function DeleteProperty(string calldata _name, uint256 _idx) external override {
        BNSEntry storage current = names[convert(_name)];
        requireOnlyOwner(current);
        uint256 last = current.properties.length - 1;
        require(_idx <= last, "Index out of bounds");
        if (_idx != last) {
            current.properties[_idx] = current.properties[last];
        }
        current.properties.pop();
        update_change_tracker();
    }

    /**
     * GetProperty retrieves the indexed property of a domain.
     * @param _name the name of the domain.
     * @param _idx the zero based index of the property to be retrieved.
     */
    function GetProperty(string calldata _name, uint256 _idx) external view override returns (string memory) {
        return resolveEntry(_name).properties[_idx];
    }

    /**
     * GetPropertyLength retrieves the number of properties for a domain.
     * @param _name the name of the domain.
     */
    function GetPropertyLength(string calldata _name) external view override returns (uint256) {
        return resolveEntry(_name).properties.length;
    }

    /**
     * GetProperties retrieves all properties of a domain.
     * @param _name the name of the domain.
     */
    function GetProperties(string calldata _name) external view override returns (string[] memory) {
        return resolveEntry(_name).properties;
    }

    /**
     * RegisterReverse sets at reverse lookup entry from `_address` to `_name`.
     * This requires an existing forward lookup from `_name` to `_address`.
     *
     * @param _address the single destination to be assigned.
     * @param _name the name to be set.
     */
    function RegisterReverse(address _address, string calldata _name) external override {
        BNSEntry memory entry = resolveEntry(_name);
        forwardLookup(_address, entry);

        if (reverse[_address].setter != address(0)) {
            require(
                msg.sender == _address || msg.sender == reverse[_address].setter,
                "Only the address owner can override an owned entry."
            );
        }

        reverse[_address] = ReverseEntry(_name, msg.sender);
        update_change_tracker();
    }

    /**
     * UnregisterReverse deletes at reverse lookup entry for `_address`
     *
     * @param _address the single destination to be assigned.
     */
    function UnregisterReverse(address _address) external override {
        if (reverse[_address].setter != address(0)) {
            require(
                msg.sender == _address || msg.sender == reverse[_address].setter,
                "Only the address owner can unregister an owned entry."
            );
        }

        delete reverse[_address];
        update_change_tracker();
    }

    /**
     * ResolveReverse resolves `_address` into a single name if a reverse lookup entry has
     * been created before using `RegisterReverse(address,string)`.
     * @param _address the name to be created.
     */
    function ResolveReverse(address _address) external view override returns (string memory) {
        ReverseEntry memory rentry = reverse[_address];
        if (bytes(rentry.name).length == 0) {
            return rentry.name;
        }
        BNSEntry memory entry = resolveEntry(rentry.name);
        forwardLookup(_address, entry);
        return rentry.name;
    }

    /**
     */
    function AllNames() external view returns (bytes32[] memory) {
        return namesIndex;
    }

    function AllNamesLength() external view returns (uint256) {
        return namesIndex.length;
    }

    /**
     *
     *   INTERNAL FUNCTIONS **********************
     *
     */
    function requireOnlyOwner(BNSEntry storage current) internal view {
        require(
            isOwned(current) && current.owner == msg.sender,
            "This name is not registered by you, or it's lease has ended"
        );
    }

    function isOwned(BNSEntry memory current) internal pure returns (bool) {
        return current.owner != address(0);
        //return block.number < current.leaseEnd || (current.leaseEnd == 0 && current.owner != address(0));
    }

    function isLocked(BNSEntry memory current) internal pure returns (bool) {
        return current.owner != address(0);
    }

    function register(string memory _name, address destination) internal {
        address[] memory destinations = new address[](1);
        destinations[0] = destination;
        registerMultiple(_name, destinations);
    }

    function registerMultiple(string memory _name, address[] memory destinations) internal {
        bytes32 _hash = convert(_name);

        BNSEntry memory current = names[_hash];
        require(current.owner == msg.sender || !isLocked(current), "This name is already taken");
        if (current.owner == address(0)) {
            namesIndex.push(_hash);
        }
        current.destination = destinations[0];
        current.destinations = destinations;
        current.owner = msg.sender;
        current.name = _name;
        current.leaseEnd = block.number + 518400;
        current.lockEnd = block.number + 518400 * 2;
        names[_hash] = current;
        update_change_tracker();
    }

    function forwardLookup(address _address, BNSEntry memory entry) internal pure {
        if (entry.destination != _address) {
            for (uint256 i = 0; i < entry.destinations.length; i++) {
                if (entry.destinations[i] == _address) {
                    break;
                } else if (i == entry.destinations.length - 1) {
                    revert("Forward lookup failed");
                }
            }
        }
    }

    function convert(string memory name) internal pure returns (bytes32) {
        validate(name);
        return keccak256(bytes(name));
    }

    function Convert(string memory name) external pure returns (bytes32) {
        return convert(name);
    }

    function validate(string memory name) internal pure {
        bytes memory b = bytes(name);

        require(b.length > 7, "Names must be longer than 7 characters");
        require(b.length <= 32, "Names must be within 32 characters");

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            require(
                (char >= 0x30 && char <= 0x39) //9-0
                    || (char >= 0x61 && char <= 0x7A) //a-z
                    || (char == 0x2D), //-
                "Names can only contain: [0-9a-z-]"
            );
        }

        require(b[0] != 0x2D && b[b.length - 1] != 0x2D, "Names can't start or end with '-'");
    }

    function resolveEntry(string memory _name) internal view returns (BNSEntry memory) {
        BNSEntry memory current = names[convert(_name)];
        if (isOwned(current)) {
            return current;
        }

        BNSEntry memory empty;
        return empty;
    }
}
