// Diode Contracts
// Copyright 2020 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

library RoleType {
    uint256 public constant None = 0;
    uint256 public constant BackupBot = 100;
    uint256 public constant Reader = 200;
    uint256 public constant Member = 300;
    uint256 public constant Admin = 400;
    uint256 public constant Owner = 500;
}

interface IDrive {
    function Version() external pure returns (int256);

    function AddMember(address _member) external;

    function AddReader(address _member) external;

    function AddBackup(address _member) external;

    function AddMember(address _member, uint256 role) external;

    function RemoveMember(address _member) external;

    function Members() external view returns (address[] memory);

    function Role(address _member) external view returns (uint256);

    function SetPasswordPublic(address _password) external;

    function Nonce() external view returns (uint256);

    function Join(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
