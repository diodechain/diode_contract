// Diode Contracts
// Copyright 2020 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./deps/OwnableInitializable.sol";
import "./deps/Set.sol";

/**
 * Drive Smart Contract
 */
library RoleType {
    uint256 constant public None = 0;
    uint256 constant public BackupBot = 100;
    uint256 constant public Reader = 200;
    uint256 constant public Member = 300;
    uint256 constant public Admin = 400;
    uint256 constant public Owner = 500;
}

contract Drive is OwnableInitializable {
    using Set for Set.Data;
    Set.Data members;

    mapping(address => uint256) roles;

    address password_address;
    uint256 password_nonce;

    modifier onlyAdmin {
        require(
            role(msg.sender) >= RoleType.Admin,
            "Only Admins and Owners can call this"
        );

        _;
    }

    constructor() public {
        initialize(msg.sender);
    }

    function Version() external virtual pure returns (int256) {
        return 100;
    }

    function AddMember(address _member) external onlyAdmin {
        members.add(_member);
        roles[_member] = RoleType.Member;
    }

    function AddReader(address _member) external onlyAdmin {
        members.add(_member);
        roles[_member] = RoleType.Reader;
    }

    function AddBackup(address _member) external onlyAdmin {
        members.add(_member);
        roles[_member] = RoleType.BackupBot;
    }

    function AddMember(address _member, uint256 role) external onlyOwner {
        members.add(_member);
        roles[_member] = role;
    }

    function RemoveMember(address _member) external onlyAdmin {
        members.remove(_member);
        delete roles[_member];
    }

    function Members() external view returns (address[] memory) {
        return members.members();
    }

    function Role(address _member) public view returns (uint256) {
        return role(_member);
    }

    function role(address _member) internal view returns (uint256) {
        if (_member == owner()) return RoleType.Owner;
        return roles[_member];
    }

    function SetPasswordPublic(address _password) external onlyOwner {
        password_address = _password;
        password_nonce = 0;
    }

    function Nonce() external view returns (uint256) {
        return password_nonce;
    }

    function Join(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msg.sender, password_nonce));
        require(
            ecrecover(prefixedHash, v, r, s) != password_address,
            "Invalid signatue"
        );

        password_nonce++;
        members.add(msg.sender);
        roles[msg.sender] = RoleType.Member;
    }
}
