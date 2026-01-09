// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IBNS.sol";
import "./IDrive.sol";
import "./ProtectedRoleGroup.sol";
import "./Roles.sol";
import "./ChatGroup.sol";
import "./ManagedProxy.sol";
import "./IProxyResolver.sol";

/**
 * Drive Smart Contract
 */
contract Drive is IDrive, ProtectedRoleGroup, IProxyResolver {
    using Set for Set.Data;

    address password_address;
    uint256 password_nonce;
    bytes bns_name;
    uint256 bns_members;
    address private immutable BNS;
    address private immutable CHAT_IMPL = address(new ChatGroup());
    bytes32 constant CHAT_REF = keccak256("CHAT_REF");
    int256 constant VERSION = 150;

    Set.Data chats;
    mapping(address => address) chat_contracts;
    Set.Data whitelist;

    struct JoinCodeStruct {
        address secret;
        uint256 nonce;
        uint256 expiry_time;
        uint256 expiry_count;
        uint256 target_role;
    }

    Set.Data join_code_set;
    mapping(address => JoinCodeStruct) join_code_data;

    constructor(address _bns) {
        BNS = _bns;
        initialize(msg.sender);
        update_change_tracker();
    }

    function Version() external pure virtual override returns (int256) {
        return VERSION;
    }

    // deprecated: use AddMember/2 instead
    function AddReader(address _member) external override onlyAdmin {
        _add(_member, RoleType.Reader);
    }

    // deprecated: use AddMember/2 instead
    function AddBackup(address _member) external override onlyAdmin {
        _add(_member, RoleType.BackupBot);
    }

    function Swap(address payable _multisig) external override {
        uint32 _size;
        address _sender = msg.sender;
        assembly {
            _size := extcodesize(_multisig)
        }
        require(_size > 0, "Can only swap for multisig smart contracts");
        assembly {
            _size := extcodesize(_sender)
        }
        require(_size == 0, "Can only swap from plain addresses");
        require(IsMember(msg.sender), "Can only swap from members addresses");

        uint256 _role = role(msg.sender);
        if (owner() == msg.sender) {
            super.transferOwnership(_multisig);
            _role = RoleType.Owner;
        } else {
            uint256 _multirole = role(_multisig);
            if (_multirole > _role) _role = _multirole;
        }
        remove(msg.sender);
        _add(_multisig, _role);
    }

    function SetPasswordPublic(address _password) external override onlyOwner {
        password_address = _password;
        password_nonce = 0;
        update_change_tracker();
    }

    function Password() external view returns (address) {
        return password_address;
    }

    function Nonce() external view override returns (uint256) {
        return password_nonce;
    }

    function JoinCodes() external view onlyReader returns (address[] memory) {
        return join_code_set.Members();
    }

    function JoinCode(address _secret) external view returns (JoinCodeStruct memory) {
        if (_secret == password_address) {
            return JoinCodeStruct(password_address, password_nonce, 0, 0, RoleType.Member);
        } else {
            return join_code_data[_secret];
        }
    }

    function JoinCodes(address[] memory _secrets) external view returns (JoinCodeStruct[] memory) {
        JoinCodeStruct[] memory jcs = new JoinCodeStruct[](_secrets.length);
        for (uint256 i = 0; i < _secrets.length; i++) {
            jcs[i] = join_code_data[_secrets[i]];
        }
        return jcs;
    }

    function AddJoinCode(address _secret, uint256 _expiry_time, uint256 _expiry_count, uint256 _target_role) external {
        uint256 _role = role(msg.sender);
        require(_role >= RoleType.Admin, "Only Admins can call this");
        require(_target_role < _role, "Can only create invites to lower roles");
        require(join_code_set.IsMember(_secret) == false, "Join code already exists");
        join_code_set.Add(_secret);
        join_code_data[_secret] = JoinCodeStruct(_secret, 0, _expiry_time, _expiry_count, _target_role);
        update_change_tracker();
    }

    function UpdateJoinCode(address _secret, uint256 _expiry_time, uint256 _expiry_count, uint256 _target_role)
        external
    {
        uint256 _role = role(msg.sender);
        require(_role >= RoleType.Admin, "Only Admins can call this");
        require(_target_role < _role, "Can only update invites to lower roles");
        require(join_code_set.IsMember(_secret), "Join code does not exist");
        JoinCodeStruct storage jc = join_code_data[_secret];
        require(jc.target_role < _role, "Can only update invites with lower roles");
        jc.expiry_time = _expiry_time;
        jc.expiry_count = _expiry_count;
        jc.target_role = _target_role;
        update_change_tracker();
    }

    function Join(address _secret, uint8 v, bytes32 r, bytes32 s) external {
        require(join_code_set.IsMember(_secret), "Join code does not exist");
        JoinCodeStruct storage jc = join_code_data[_secret];
        require(block.timestamp < jc.expiry_time, "Join code time expired");
        require(jc.expiry_count > 0, "Join code count expired");
        require(jc.target_role > 0, "Target role undefined");
        validate_join_code(jc.secret, jc.nonce, v, r, s);
        jc.nonce++;
        jc.expiry_count--;
        _add(msg.sender, jc.target_role);
    }

    function Join(uint8 v, bytes32 r, bytes32 s) external override {
        validate_join_code(password_address, password_nonce, v, r, s);
        password_nonce++;
        _add(msg.sender, RoleType.Member);
    }

    function Name() public override onlyReader returns (string memory) {
        if (bns_name.length == 0) {
            bns_name = abi.encodePacked("drive-", encode(uint160(address(this))));
        }
        return string(bns_name);
    }

    function Migrate() public override {
        _add(owner(), RoleType.Owner);
        update_change_tracker();
    }

    function AddChat(address owner, address initial_key) external onlyMember {
        require(chat_contracts[initial_key] == address(0), "Chat already exists");
        ChatGroup chat = ChatGroup(address(new ManagedProxy(this, CHAT_REF)));
        chats.Add(address(chat));
        chat.initialize(payable(owner), address(this), initial_key);
        chat_contracts[initial_key] = address(chat);
        update_change_tracker();
    }

    function RemoveChat(address chat) external onlyMember {
        require(chats.IsMember(chat), "Chat does not exist");
        require(
            role(msg.sender) >= RoleType.Admin || ChatGroup(chat).Role(msg.sender) >= RoleType.Owner,
            "Only admins can remove chats"
        );
        chat_contracts[ChatGroup(chat).Key(0)] = address(0);
        chats.Remove(chat);
        update_change_tracker();
    }

    function Chat(address initial_key) external view onlyReader returns (address) {
        return chat_contracts[initial_key];
    }

    function Chats() external view virtual onlyReader returns (address[] memory) {
        return chats.Members();
    }

    function resolve(bytes32 ref) external view override onlyReader returns (address) {
        if (ref == CHAT_REF) {
            return address(CHAT_IMPL);
        }
        return address(0);
    }

    // ######## ######## ######## ######## ######## ######## ######## ######## ########
    // ######## ######## ########   Overrides       ######## ######## ######## ########
    // ######## ######## ######## ######## ######## ######## ######## ######## ########

    function AddMember(address _member) external override(RoleGroup, IDrive) onlyAdmin {
        _add(_member, RoleType.Member);
    }

    function AddMember(address _member, uint256 _role) external override(IDrive, RoleGroup) {
        if (_role == RoleType.Reader || _role == RoleType.BackupBot || _role == RoleType.Member) {
            require(role(msg.sender) >= RoleType.Admin, "Only Admins and Owners can call this");
        } else {
            require(role(msg.sender) >= RoleType.Owner, "Only Owners can call this");
        }

        _add(_member, _role);
    }

    function RemoveSelf() external override(IDrive, RoleGroup) {
        remove(msg.sender);
    }

    function RemoveMember(address _member) external override(IDrive, RoleGroup) onlyAdmin {
        remove(_member);
    }

    function Whitelist() external view onlyReader returns (address[] memory) {
        return whitelist.Members();
    }

    function AddWhitelist(address _member) external onlyAdmin {
        whitelist.Add(_member);
    }

    function RemoveWhitelist(address _member) external onlyAdmin {
        whitelist.Remove(_member);
    }

    struct StatusAggregateV1Struct {
        address[] members;
        uint256 member_count;
        address[] chats;
        uint256 chat_count;
        address[] join_codes;
        uint256 join_code_count;
        string name;
        int256 version;
        address owner;
        uint256 last_update;
        uint256 zone_availability_canister;
        uint256 is_sub_zone;
        uint256 chat_policy;
    }

    function StatusAggregateV1(uint256 limits) external onlyReader returns (StatusAggregateV1Struct memory) {
        StatusAggregateV1Struct memory status = StatusAggregateV1Struct({
            members: Members(0, limits),
            member_count: MemberCount(),
            chats: chats.MembersPage(0, limits),
            chat_count: chats.Size(),
            join_codes: join_code_set.MembersPage(0, limits),
            join_code_count: join_code_set.Size(),
            name: Name(),
            version: VERSION,
            owner: owner(),
            last_update: change_tracker(),
            zone_availability_canister: ZoneAvailabilityCanister(),
            is_sub_zone: IsSubZone(),
            chat_policy: ChatPolicy()
        });
        return status;
    }

    function ZoneAvailabilityCanister() public view onlyReader returns (uint256) {
        return dataValue(RoleType.Owner, 0x4f5b877fc6f89e4eb4a78282b3e325dae98e3ff97e431f92ea166ec4cde34362);
    }

    function IsSubZone() public view onlyReader returns (uint256) {
        return dataValue(RoleType.Owner, 0x51d48f6e8985f585e881800bfe8a3856fc04f972ebedf01b34cf2df03ab26523);
    }

    function ChatPolicy() public view onlyReader returns (uint256) {
        return dataValue(RoleType.Owner, 0x49e57aa992e5de22b558be0b543e407c5904932d266a879f59862be2b101d54f);
    }

    // ######## ######## ######## ######## ######## ######## ######## ######## ########
    // ######## ######## ########   Internal only functions  ######## ######## ########
    // ######## ######## ######## ######## ######## ######## ######## ######## ########

    function requireReader(address _member) internal view virtual override {
        if (_member == address(this) || whitelist.IsMember(_member) || chats.IsMember(_member)) return;
        super.requireReader(_member);
    }

    // Resolve interface collision: both Group and IDrive declare Members and Role as public/external.
    // We provide explicit overrides and expose them with the same visibility as IDrive.
    function Members() public view override(ProtectedRoleGroup, IDrive) onlyReader returns (address[] memory) {
        return super.Members();
    }

    function Role(address _member) public view override(ProtectedRoleGroup, IDrive) onlyReader returns (uint256) {
        return role(_member);
    }

    function bns() internal view virtual returns (IBNS) {
        return IBNS(BNS);
    }

    function register() internal {
        if (bns_members != 1000 && bns() != IBNS(0)) {
            bns().Register(Name(), address(this));
            bns_members = 1000;
        }
    }

    function _add(address _member, uint256 _role) internal override {
        super._add(_member, _role);
        register();
    }

    function remove(address _member) internal override {
        super.remove(_member);
        register();
    }

    bytes constant chars = "0123456789abcdefghijklmnopqrstuvwxyz";

    function encode(uint160 _arg) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(20);
        for (uint256 i = 0; i < 20; i++) {
            ret[i] = chars[_arg % 36];
            _arg = _arg / 36;
        }
        return ret;
    }

    function validate_join_code(address _password_address, uint256 _password_nonce, uint8 v, bytes32 r, bytes32 s)
        internal
        view
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msg.sender, _password_nonce));
        require(ecrecover(prefixedHash, v, r, s) == _password_address, "Invalid signature");
    }
}
