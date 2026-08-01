// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/BNS.sol";
import "../contracts/Drive.sol";
import "../contracts/DriveFactory.sol";
import "../contracts/DriveMember.sol";
import "../contracts/MembershipHistory.sol";
import "../contracts/Roles.sol";
import "./forge-std/Test.sol";

contract MembershipHistoryTest is Test {
    BNS bns;
    DriveFactory factory;
    Drive drive;
    bytes32 salt32;
    address member1;
    address member2;

    uint8 constant STATUS_UNKNOWN = 0;
    uint8 constant STATUS_NONE = 1;
    uint8 constant STATUS_MEMBER = 2;

    function owner() public view returns (address) {
        return address(this);
    }

    function Members() public pure returns (address[] memory) {
        return new address[](0);
    }

    function setUp() public {
        vm.warp(1_700_000_000);
        bns = new BNS();
        factory = new DriveFactory();
        Drive code = new Drive(address(bns));
        salt32 = bytes32(uint256(uint160(address(code))));
        drive = Drive(factory.Create(payable(address(this)), salt32, address(code)));
        member1 = address(new CallForwarder(address(drive)));
        member2 = address(new CallForwarder(address(drive)));
    }

    function testVersion() public {
        Assert.equal(drive.Version(), int256(161), "Drive version should be 161");
    }

    function testFreshDriveHistoryStartAndOwner() public {
        uint256 start = drive.MembershipHistoryStart();
        Assert.greaterThan(start, uint256(0), "history start should be set on initialize");
        Assert.equal(start, block.timestamp, "history start should equal deploy timestamp");

        MembershipHistory.MembershipAtResult memory r = drive.RoleAt(address(this), block.timestamp);
        Assert.equal(uint256(r.status), uint256(STATUS_MEMBER), "owner should be Member at now");
        Assert.equal(r.role, RoleType.Owner, "owner role should be Owner");
        Assert.equal(r.validFrom, start, "owner interval starts at history start");
        Assert.equal(r.validTo, uint256(0), "owner interval should be open");

        MembershipHistory.MembershipAtResult memory before = drive.RoleAt(address(this), start - 1);
        Assert.equal(uint256(before.status), uint256(STATUS_UNKNOWN), "before history start is Unknown");
        Assert.equal(before.validFrom, uint256(0), "Unknown has zero bounds");
        Assert.equal(before.validTo, uint256(0), "Unknown has zero bounds");
    }

    function testJoinLeaveIntervals() public {
        uint256 start = drive.MembershipHistoryStart();
        vm.warp(block.timestamp + 100);
        uint256 joinTime = block.timestamp;
        drive.AddMember(member1, RoleType.Member);

        MembershipHistory.MembershipAtResult memory mid = drive.RoleAt(member1, joinTime);
        Assert.equal(uint256(mid.status), uint256(STATUS_MEMBER), "member at join time");
        Assert.equal(mid.role, RoleType.Member, "role Member");
        Assert.equal(mid.validFrom, joinTime, "validFrom is join");
        Assert.equal(mid.validTo, uint256(0), "still open");

        // Mid-membership cacheability
        vm.warp(block.timestamp + 50);
        MembershipHistory.MembershipAtResult memory mid2 = drive.RoleAt(member1, joinTime + 25);
        Assert.equal(mid2.validFrom, mid.validFrom, "same validFrom while open");
        Assert.equal(mid2.validTo, mid.validTo, "same validTo while open");
        Assert.equal(mid2.role, mid.role, "same role while open");

        vm.warp(block.timestamp + 50);
        uint256 leaveTime = block.timestamp;
        drive.RemoveMember(member1);

        Assert.equal(drive.Role(member1), RoleType.None, "live Role after leave is None");
        Assert.ok(!drive.IsMember(member1), "live IsMember after leave is false");

        MembershipHistory.MembershipAtResult memory during = drive.RoleAt(member1, joinTime + 10);
        Assert.equal(uint256(during.status), uint256(STATUS_MEMBER), "historic membership remains");
        Assert.equal(during.role, RoleType.Member, "historic role");
        Assert.equal(during.validFrom, joinTime, "closed interval from join");
        Assert.equal(during.validTo, leaveTime, "closed interval to leave");

        MembershipHistory.MembershipAtResult memory afterLeave = drive.RoleAt(member1, leaveTime);
        Assert.equal(uint256(afterLeave.status), uint256(STATUS_NONE), "at leave time is None (exclusive end)");
        Assert.equal(afterLeave.validFrom, leaveTime, "open-none starts at leave");
        Assert.equal(afterLeave.validTo, uint256(0), "open-none after leave");

        // Before join but after history start: None
        MembershipHistory.MembershipAtResult memory beforeJoin = drive.RoleAt(member1, start + 1);
        Assert.equal(uint256(beforeJoin.status), uint256(STATUS_NONE), "never-member before join is None");
        Assert.equal(beforeJoin.validFrom, start, "none gap from history start");
        Assert.equal(beforeJoin.validTo, joinTime, "none gap until join");
    }

    function testGapCacheAfterRejoin() public {
        vm.warp(block.timestamp + 10);
        uint256 join1 = block.timestamp;
        drive.AddMember(member1, RoleType.Admin);

        vm.warp(block.timestamp + 100);
        uint256 leave1 = block.timestamp;
        drive.RemoveMember(member1);

        vm.warp(block.timestamp + 100);
        uint256 join2 = block.timestamp;
        drive.AddMember(member1, RoleType.Member);

        MembershipHistory.MembershipAtResult memory gap = drive.RoleAt(member1, leave1 + 50);
        Assert.equal(uint256(gap.status), uint256(STATUS_NONE), "gap is None");
        Assert.equal(gap.validFrom, leave1, "gap from leave");
        Assert.equal(gap.validTo, join2, "gap until rejoin is fully cacheable");

        MembershipHistory.MembershipAtResult memory first = drive.RoleAt(member1, join1 + 1);
        Assert.equal(uint256(first.status), uint256(STATUS_MEMBER), "first interval still Member");
        Assert.equal(first.role, RoleType.Admin, "first interval Admin");
        Assert.equal(first.validTo, leave1, "first interval closed at leave");

        MembershipHistory.MembershipAtResult memory second = drive.RoleAt(member1, join2);
        Assert.equal(uint256(second.status), uint256(STATUS_MEMBER), "second interval Member");
        Assert.equal(second.role, RoleType.Member, "second interval Member role");
        Assert.equal(second.validTo, uint256(0), "second interval open");
    }

    function testRoleChangeClosesAndOpens() public {
        vm.warp(block.timestamp + 10);
        uint256 asAdmin = block.timestamp;
        drive.AddMember(member1, RoleType.Admin);

        vm.warp(block.timestamp + 100);
        uint256 asMember = block.timestamp;
        drive.AddMember(member1, RoleType.Member);

        MembershipHistory.MembershipAtResult memory a = drive.RoleAt(member1, asAdmin + 1);
        Assert.equal(uint256(a.status), uint256(STATUS_MEMBER), "admin segment");
        Assert.equal(a.role, RoleType.Admin, "Admin role");
        Assert.equal(a.validFrom, asAdmin, "admin from");
        Assert.equal(a.validTo, asMember, "admin until role change");

        MembershipHistory.MembershipAtResult memory m = drive.RoleAt(member1, asMember);
        Assert.equal(uint256(m.status), uint256(STATUS_MEMBER), "member segment");
        Assert.equal(m.role, RoleType.Member, "Member role");
        Assert.equal(m.validFrom, asMember, "member from");
        Assert.equal(m.validTo, uint256(0), "member open");
    }

    function testUnknownVersusNone() public {
        uint256 start = drive.MembershipHistoryStart();
        MembershipHistory.MembershipAtResult memory unknown = drive.RoleAt(member2, start - 1);
        Assert.equal(uint256(unknown.status), uint256(STATUS_UNKNOWN), "pre-history is Unknown");

        MembershipHistory.MembershipAtResult memory none = drive.RoleAt(member2, start);
        Assert.equal(uint256(none.status), uint256(STATUS_NONE), "never-member after start is None not Unknown");
        Assert.equal(none.validFrom, start, "open-none from start");
        Assert.equal(none.validTo, uint256(0), "open-none");
    }

    function testEnsureAfterSimulatedUpgrade() public {
        // Simulate a proxy that had members before history existed by writing nothing to history
        // and calling Ensure after warping (fresh drive already ensured at init — use a DriveMember
        // path: create identity, then upgrade-like ensure after adding devices under controlled start).
        // For Drive: clear is impossible; instead verify Ensure is idempotent and backfill is stable.
        uint256 startBefore = drive.MembershipHistoryStart();
        drive.AddMember(member1, RoleType.Reader);
        drive.EnsureMembershipHistory();
        Assert.equal(drive.MembershipHistoryStart(), startBefore, "Ensure is idempotent");

        MembershipHistory.MembershipAtResult memory r = drive.RoleAt(member1, block.timestamp);
        Assert.equal(uint256(r.status), uint256(STATUS_MEMBER), "member still tracked after Ensure");
        Assert.equal(r.role, RoleType.Reader, "reader role preserved");
    }

    function testDriveMemberMemberAt() public {
        DriveMember impl = new DriveMember();
        bytes32 mSalt = keccak256("membership-history-member");
        DriveMember identity = DriveMember(factory.Create(payable(address(this)), mSalt, address(impl)));

        Assert.equal(identity.Version(), int256(124), "DriveMember version 124");
        uint256 start = identity.MembershipHistoryStart();
        Assert.greaterThan(start, uint256(0), "DriveMember history started on initialize");

        MembershipHistory.MembershipAtResult memory ownerAt = identity.MemberAt(address(this), block.timestamp);
        Assert.equal(uint256(ownerAt.status), uint256(STATUS_MEMBER), "owner is member");
        Assert.equal(ownerAt.role, uint256(1), "membership marker role is 1");

        MembershipHistory.MembershipAtResult memory pre = identity.MemberAt(address(this), start - 1);
        Assert.equal(uint256(pre.status), uint256(STATUS_UNKNOWN), "pre-history Unknown");

        address device = address(0xBEEF);
        vm.warp(block.timestamp + 20);
        uint256 joinTime = block.timestamp;
        identity.AddMember(device);

        MembershipHistory.MembershipAtResult memory joined = identity.MemberAt(device, joinTime);
        Assert.equal(uint256(joined.status), uint256(STATUS_MEMBER), "device joined");
        Assert.equal(joined.role, uint256(1), "device marker role");
        Assert.equal(joined.validTo, uint256(0), "open membership");

        vm.warp(block.timestamp + 40);
        uint256 leaveTime = block.timestamp;
        identity.RemoveMember(device);
        Assert.ok(!identity.IsMember(device), "live IsMember false after remove");

        MembershipHistory.MembershipAtResult memory historic = identity.MemberAt(device, joinTime + 1);
        Assert.equal(uint256(historic.status), uint256(STATUS_MEMBER), "historic device membership");
        Assert.equal(historic.validFrom, joinTime, "from join");
        Assert.equal(historic.validTo, leaveTime, "to leave");

        MembershipHistory.MembershipAtResult memory afterLeave2 = identity.MemberAt(device, leaveTime);
        Assert.equal(uint256(afterLeave2.status), uint256(STATUS_NONE), "after leave None");
        Assert.equal(afterLeave2.validFrom, leaveTime, "none from leave");
        Assert.equal(afterLeave2.validTo, uint256(0), "open none");
    }

    function testCacheabilitySameWindow() public {
        vm.warp(block.timestamp + 5);
        uint256 joinTime = block.timestamp;
        drive.AddMember(member1, RoleType.Member);
        vm.warp(block.timestamp + 200);
        uint256 leaveTime = block.timestamp;
        drive.RemoveMember(member1);

        MembershipHistory.MembershipAtResult memory a = drive.RoleAt(member1, joinTime + 10);
        MembershipHistory.MembershipAtResult memory b = drive.RoleAt(member1, leaveTime - 1);
        Assert.equal(a.validFrom, b.validFrom, "same window validFrom");
        Assert.equal(a.validTo, b.validTo, "same window validTo");
        Assert.equal(a.role, b.role, "same window role");
        Assert.equal(uint256(a.status), uint256(STATUS_MEMBER), "both Member");
    }

    function testLibraryUnknownUntilEnsure() public {
        HistoryHarness h = new HistoryHarness();
        Assert.equal(h.start(), uint256(0), "uninitialized history start is 0");

        MembershipHistory.MembershipAtResult memory u = h.at(address(0x1), block.timestamp);
        Assert.equal(uint256(u.status), uint256(STATUS_UNKNOWN), "before ensure all queries Unknown");

        vm.warp(block.timestamp + 5);
        uint256 ensuredAt = block.timestamp;
        h.ensureAndSeed(address(0x1), RoleType.Member);

        Assert.equal(h.start(), ensuredAt, "history starts at ensure time");
        MembershipHistory.MembershipAtResult memory pre = h.at(address(0x1), ensuredAt - 1);
        Assert.equal(uint256(pre.status), uint256(STATUS_UNKNOWN), "pre-ensure timestamp stays Unknown");

        MembershipHistory.MembershipAtResult memory post = h.at(address(0x1), ensuredAt);
        Assert.equal(uint256(post.status), uint256(STATUS_MEMBER), "backfilled member after ensure");
        Assert.equal(post.role, RoleType.Member, "backfilled role");
        Assert.equal(post.validFrom, ensuredAt, "seeded from history start");
        Assert.equal(post.validTo, uint256(0), "seeded open interval");
    }

    function testTransferOwnershipHistory() public {
        drive.AddMember(member1, RoleType.Admin);
        vm.warp(block.timestamp + 30);
        uint256 transferTime = block.timestamp;
        address prevOwner = address(this);
        drive.transferOwnership(payable(member1));

        MembershipHistory.MembershipAtResult memory prev = drive.RoleAt(prevOwner, transferTime);
        Assert.equal(uint256(prev.status), uint256(STATUS_MEMBER), "previous owner still member as Admin");
        Assert.equal(prev.role, RoleType.Admin, "previous owner demoted to Admin in history");

        MembershipHistory.MembershipAtResult memory neu = drive.RoleAt(member1, transferTime);
        Assert.equal(uint256(neu.status), uint256(STATUS_MEMBER), "new owner in history");
        Assert.equal(neu.role, RoleType.Owner, "new owner recorded as Owner");
        Assert.equal(drive.Role(member1), RoleType.Owner, "live Role is Owner");
    }
}

/// @dev Direct library harness to simulate post-upgrade Ensure without prior history.
contract HistoryHarness {
    function start() external view returns (uint256) {
        return MembershipHistory.historyStart();
    }

    function at(address member, uint256 timestamp)
        external
        view
        returns (MembershipHistory.MembershipAtResult memory)
    {
        return MembershipHistory.at(member, timestamp);
    }

    function ensureAndSeed(address member, uint256 role) external {
        require(MembershipHistory.ensureStart(), "already started");
        MembershipHistory.seedOpen(member, role);
    }
}
