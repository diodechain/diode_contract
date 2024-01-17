// Diode Contracts
// Copyright 2021 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./IBNS.sol";
import "./IDrive.sol";
import "./RoleGroup.sol";
import "./Roles.sol";
import "./Chat.sol";
import "./ManagedProxy.sol";
import "./IProxyResolver.sol";

/**
 * Drive Smart Contract
 */
contract Drive is RoleGroup, IDrive, IProxyResolver {
    address password_address;
    uint256 password_nonce;
    bytes   bns_name;
    uint256 bns_members;
    address private immutable BNS;
    address private immutable CHAT_IMPL = address(new Chat());
    bytes32 constant CHAT_REF = keccak256("CHAT_REF");

    Set.Data chats;
    mapping(address => address) chat_contracts;

    constructor(address bns) public {
        BNS = bns;
        initialize(msg.sender);
    }

    function Version() external virtual override pure returns (int256) {
        return 135;
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

    function Swap(address payable _multisig) external override {
        uint32 _size;
        address _sender = msg.sender;
        assembly { _size := extcodesize(_multisig) }
        require(_size > 0, "Can only swap for multisig smart contracts");
        assembly { _size := extcodesize(_sender) }
        require(_size == 0, "Can only swap from plain addresses");
        require(members.isMember(msg.sender) || owner() == msg.sender, "Can only swap from members addresses");

        uint256 _role = role(msg.sender);
        if (owner() == msg.sender) {
            super.transferOwnership(_multisig);
            _role = RoleType.Owner;
        } else {
            uint256 _multirole = role(_multisig);
            if (_multirole > _role) _role = _multirole;
        }
        remove(msg.sender);
        add(_multisig, _role);
    }

    function RemoveSelf() external override {
        remove(msg.sender);
    }

    function RemoveMember(address _member) external override onlyAdmin {
        remove(_member);
    }

    function Members() external view override(Group, IDrive) returns (address[] memory) {
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
        /*TEST_IF
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(prefix, address(0), password_nonce)
        );
        /*TEST_ELSE*/
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(prefix, msg.sender, password_nonce)
        );
        /*TEST_END*/
        require(
            ecrecover(prefixedHash, v, r, s) == password_address,
            "Invalid signature"
        );

        password_nonce++;
        add(msg.sender, RoleType.Member);
    }

    function Name() public override returns (string memory) {
        if (bns_name.length == 0) {
            bns_name = abi.encodePacked("drive-", encode(uint160(address(this))));
        }
        return string(bns_name);
    }

    function Migrate() public override {
        add(owner(), RoleType.Owner);
    }

    function AddChat(address owner, address initial_key) external onlyMember {
        require(chat_contracts[initial_key] == address(0), "Chat already exists");
        Chat chat = Chat(address(new ManagedProxy(this, CHAT_REF)));
        chat.initialize(payable(owner), initial_key);
        chats.add(address(chat));
        chat_contracts[initial_key] = address(chat);
    }

    function resolve(bytes32 ref) external view override returns (address) {
        if (ref == CHAT_REF) {
            return address(CHAT_IMPL);
        }
        return address(0);
    }

    function Chat(address initial_key) external view returns (address) {
        return chat_contracts[initial_key];
    }

    // ######## ######## ######## ######## ######## ######## ######## ######## ########
    // ######## ######## ########   Internal only functions  ######## ######## ########
    // ######## ######## ######## ######## ######## ######## ######## ######## ########

    function bns() internal virtual view returns (IBNS) {
        return IBNS(BNS);
    }

    function register() internal {
        uint256 size = members.size();
        if (size > 0 && size != bns_members && bns() != IBNS(0)) {
            bns().RegisterMultiple(Name(), members.members());
            bns_members = size;
        }
    }

    function add(address _member, uint256 _role) internal override {
        super.add(_member, _role);
        register();
    }

    function remove(address _member) internal override {
        super.remove(_member);
        register();
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
