// Diode Contracts
// Copyright 2020 IoT Blockchain Technology Corporation LLC (IBTC)
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./IBNS.sol";
import "./IDrive.sol";
import "./deps/OwnableInitializable.sol";
import "./deps/Set.sol";

/**
 * Drive Smart Contract
 */
contract Drive is OwnableInitializable, IDrive {
    using Set for Set.Data;
    Set.Data members;

    mapping(address => uint256) roles;

    address password_address;
    uint256 password_nonce;
    bytes   bns_name;
    uint256 bns_members;

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

    function Version() external virtual override pure returns (int256) {
        return 110;
    }

    function AddMember(address _member) external override onlyAdmin {
        add(_member, RoleType.Member);
    }

    function AddReader(address _member) external override onlyAdmin {
        add(_member, RoleType.Reader);
    }

    function AddBackup(address _member) external override onlyAdmin {
        add(_member, RoleType.BackupBot);
    }

    function AddMember(address _member, uint256 role)
        external
        override
        onlyOwner
    {
        add(_member, role);
    }

    function RemoveMember(address _member) external override onlyAdmin {
        remove(_member);
    }

    function Members() external override view returns (address[] memory) {
        return members.members();
    }

    function Role(address _member) public override view returns (uint256) {
        return role(_member);
    }

    function SetPasswordPublic(address _password) external override onlyOwner {
        password_address = _password;
        password_nonce = 0;
    }

    function Nonce() external override view returns (uint256) {
        return password_nonce;
    }

    function Join(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(prefix, msg.sender, password_nonce)
        );
        require(
            ecrecover(prefixedHash, v, r, s) != password_address,
            "Invalid signatue"
        );

        password_nonce++;
        members.add(msg.sender);
        roles[msg.sender] = RoleType.Member;
    }

    function Name() public override returns (string memory) {
        if (bns_name.length == 0) {
            bns_name = abi.encodePacked("drive-", encode(uint160(address(this))));
        }
        return string(bns_name);
    }

    function Migrate() public override {
        add(owner(), RoleType.Owner);
        register();
    }

    // ######## ######## ######## ######## ######## ######## ######## ######## ########
    // ######## ######## ########   Internal only functions  ######## ######## ########
    // ######## ######## ######## ######## ######## ######## ######## ######## ########

    function bns() internal virtual view returns (IBNS) {
        return IBNS(0xaF60fAA5cd840b724742f1AF116168276112d6A6);
    }

    function register() internal {
        uint256 size = members.size();
        if (size > 0 && size != bns_members && bns() != IBNS(0)) {
            bns().RegisterMultiple(Name(), members.members());
            bns_members = size;
        }
    }

    function add(address _member, uint256 _role) internal {
        members.add(_member);
        roles[_member] = _role;
        register();
    }

    function remove(address _member) internal {
        members.remove(_member);
        delete roles[_member];
        register();
    }

    function role(address _member) internal view returns (uint256) {
        if (_member == owner()) return RoleType.Owner;
        return roles[_member];
    }

    bytes constant chars = "0123456789abcdefghijklmnopqrstuvwxyz";
    function encode(uint160 _arg) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            ret[i] = chars[_arg % 36];
            _arg = _arg / 36;
        }
        return ret;
    }

}
