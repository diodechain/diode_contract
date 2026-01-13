// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Group.sol";
import "./deps/SetReverseLocation.sol";
import "cross/ChainId.sol";

/**
 * DriveMember and Identity Smart Contract
 *
 * When used as a DriveMember the `drive` member variable should point to the address of the drive "zone"
 * that this contract is a member of.
 *
 * When used as Identity the `drive` member variable will be `0`.
 *
 * The "owner" will always be the initial "master key". The contract is being deployed using the DriveFactory.sol
 * and thus upgradeable by the `owner()` only.
 *
 * "additional_drives" is temporary to store multiple Zones all used with this same identity. Will be replaced
 * once the client can handle multiple identity connections.
 *
 * TODO:
 * Implement fallback recovery options, such as social recovery or a PIN/PUK style cold storage backup master to
 * recover from cases when the "master key" got stolen.
 */
interface IDriveFactory {
    function Create2Address(bytes32 _salt) external view returns (address);
    function Upgrade(bytes32 _salt, address _target) external;
}

contract DriveMember is Group {
    using Set for Set.Data;
    using SetReverseLocation for SetReverseLocation.Data;

    bool protected;
    address drive;
    SetReverseLocation.Data additional_drives;
    Set.Data whitelist;
    mapping(address => uint256) nonces;

    modifier onlyMember() override {
        requireMember(msg.sender);
        _;
    }

    modifier onlyReader() {
        requireReader(msg.sender);
        _;
    }

    function requireReader(address _member) internal view {
        if (ChainId.THIS == ChainId.OASIS) {
            require(
                _member == address(this) || super.IsMember(_member) || additional_drives.IsMember(_member)
                    || whitelist.IsMember(_member),
                "Read access not allowed"
            );
        }
    }

    function requireMember(address _member) internal view override {
        // MetaTransaction calls AddDrive/SetDrive on itself
        if (_member == address(this)) return;

        if (protected) {
            require(owner() == _member, "Only the owner can call this in protected mode");
        } else {
            require(super.IsMember(_member), "Only members can call this");
        }
    }

    constructor() {
        initialize(msg.sender);
        update_change_tracker();
    }

    function Version() external pure virtual returns (int256) {
        return 120;
    }

    function Protect(bool _protect) external onlyMember {
        protected = _protect;
        update_change_tracker();
    }

    function AddMember(address _member) external onlyMember {
        members.Add(_member);
        update_change_tracker();
    }

    function RemoveMember(address _member) external onlyMember {
        members.Remove(_member);
        update_change_tracker();
    }

    function Destroy() external onlyOwner {
        selfdestruct(msg.sender);
    }

    function Drive() public view onlyReader returns (address) {
        return drive;
    }

    function SetDrive(address _drive) external onlyMember {
        drive = _drive;
        update_change_tracker();
    }

    function AddDrive(address _drive) external onlyMember {
        additional_drives.Add(_drive);
        update_change_tracker();
    }

    function RemoveDrive(address _drive) external onlyMember {
        additional_drives.Remove(_drive);
        update_change_tracker();
    }

    function Whitelist() external view onlyReader returns (address[] memory) {
        return whitelist.Members();
    }

    function AddWhitelist(address _reader) external onlyMember {
        whitelist.Add(_reader);
        update_change_tracker();
    }

    function RemoveWhitelist(address _reader) external onlyMember {
        whitelist.Remove(_reader);
        update_change_tracker();
    }

    function Drives() external view onlyReader returns (address[] memory) {
        return additional_drives.Members();
    }

    function Members() public override onlyReader returns (address[] memory) {
        return super.Members();
    }

    function IsMember(address _member) public view override onlyReader returns (bool) {
        return super.IsMember(_member);
    }

    function SubmitTransaction(address dst, bytes memory data) public onlyMember {
        require(external_call(dst, data.length, data), "General Transaction failed");
    }

    function SubmitCall(address destination, bytes memory data) public payable onlyMember {
        uint256 dataLength = data.length;
        uint256 value = msg.value;

        assembly {
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            let result := call(gas(), destination, value, d, dataLength, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 { revert(0, 0) }
            default { return(0, returndatasize()) }
        }
    }

    function SubmitDriveTransaction(bytes memory data) public onlyMember {
        require(external_call(drive, data.length, data), "Drive Transaction failed");
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId = 15;

        return keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256("DriveMember"),
                // Unchanged from v116 to keep compatibility through proxy upgrades.
                keccak256("116"),
                chainId,
                address(this)
            )
        );
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    function TransactionDigest(uint256 nonce, uint256 deadline, address dst, bytes memory data)
        public
        view
        returns (bytes32)
    {
        return toTypedDataHash(
            DOMAIN_SEPARATOR(),
            keccak256(
                abi.encode(
                    keccak256("Transaction(uint256 nonce,uint256 deadline,address dst,bytes data)"),
                    nonce,
                    deadline,
                    dst,
                    keccak256(data)
                )
            )
        );
    }

    function SubmitMetaTransaction(
        uint256 nonce,
        uint256 deadline,
        address dst,
        bytes memory data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp < deadline, "Transaction expired");
        bytes32 digest = TransactionDigest(nonce, deadline, dst, data);
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "Invalid signature");
        requireMember(signer);
        require(nonces[signer] == nonce, "Invalid nonce");
        nonces[signer]++;
        require(external_call(dst, data.length, data), "General Transaction failed");
    }

    function Nonce(address sender) public view onlyReader returns (uint256) {
        return nonces[sender];
    }

    function FactoryUpgrade(
        bytes32 _salt,
        address _target,
        uint8 v,
        uint256 nonce,
        uint256 deadline,
        bytes32 r,
        bytes32 s
    ) public {
        IDriveFactory dst = IDriveFactory(proxy_owner());
        require(dst != IDriveFactory(0), "Invalid factory");
        require(dst.Create2Address(_salt) == address(this), "Invalid salt");
        bytes32 digest = TransactionDigest(nonce, deadline, address(dst), abi.encode(_target));
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "Invalid signature");
        require(nonces[signer] == nonce, "Invalid nonce");
        nonces[signer]++;

        require(signer == owner(), "Invalid signer");
        OwnableInitializable.transferOwnership(payable(address(this)));
        dst.Upgrade(_salt, _target);
        OwnableInitializable.transferOwnership(payable(signer));
    }

    bytes32 internal constant OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    function proxy_owner() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_SLOT)
        }
        return owner;
    }
}
