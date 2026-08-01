// SPDX-License-Identifier: DIODE
// Diode Contracts
// Copyright 2021-2024 Diode
// Licensed under the Diode License, Version 1.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * Namespaced membership-interval history for upgradeable proxies.
 *
 * status: 0 = Unknown (pre-history / not tracking yet)
 *         1 = None    (definitely not authorized in [validFrom, validTo))
 *         2 = Member  (authorized with `role` in [validFrom, validTo))
 *
 * validTo == 0 means the interval is open-ended as of chain head.
 */
library MembershipHistory {
    uint8 internal constant STATUS_UNKNOWN = 0;
    uint8 internal constant STATUS_NONE = 1;
    uint8 internal constant STATUS_MEMBER = 2;

    bytes32 internal constant SLOT = keccak256("diode.membership.history.v1");

    struct Interval {
        uint256 role;
        uint64 from;
        uint64 to; // 0 = open
    }

    struct MembershipAtResult {
        uint8 status;
        uint256 role;
        uint256 validFrom;
        uint256 validTo;
    }

    struct Layout {
        uint256 historyStart;
        mapping(address => Interval[]) intervals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    function historyStart() internal view returns (uint256) {
        return layout().historyStart;
    }

    /// @dev Returns true if history was just started (caller should backfill).
    function ensureStart() internal returns (bool newlyStarted) {
        Layout storage l = layout();
        if (l.historyStart != 0) {
            return false;
        }
        l.historyStart = block.timestamp;
        return true;
    }

    /// @dev Seed an open interval for a current member. No-op if intervals already exist.
    function seedOpen(address member, uint256 role) internal {
        Layout storage l = layout();
        Interval[] storage list = l.intervals[member];
        if (list.length > 0) {
            return;
        }
        list.push(Interval({role: role, from: uint64(l.historyStart), to: 0}));
    }

    function recordJoin(address member, uint256 role) internal {
        Layout storage l = layout();
        require(l.historyStart != 0, "history not started");
        Interval[] storage list = l.intervals[member];
        uint256 len = list.length;
        if (len > 0 && list[len - 1].to == 0) {
            // Already an open membership; treat as role change if needed.
            if (list[len - 1].role != role) {
                list[len - 1].to = uint64(block.timestamp);
                list.push(Interval({role: role, from: uint64(block.timestamp), to: 0}));
            }
            return;
        }
        list.push(Interval({role: role, from: uint64(block.timestamp), to: 0}));
    }

    function recordLeave(address member) internal {
        Layout storage l = layout();
        require(l.historyStart != 0, "history not started");
        Interval[] storage list = l.intervals[member];
        uint256 len = list.length;
        if (len == 0) {
            return;
        }
        if (list[len - 1].to == 0) {
            list[len - 1].to = uint64(block.timestamp);
        }
    }

    function recordRoleChange(address member, uint256 newRole) internal {
        Layout storage l = layout();
        require(l.historyStart != 0, "history not started");
        Interval[] storage list = l.intervals[member];
        uint256 len = list.length;
        if (len == 0 || list[len - 1].to != 0) {
            list.push(Interval({role: newRole, from: uint64(block.timestamp), to: 0}));
            return;
        }
        if (list[len - 1].role == newRole) {
            return;
        }
        list[len - 1].to = uint64(block.timestamp);
        list.push(Interval({role: newRole, from: uint64(block.timestamp), to: 0}));
    }

    function at(address member, uint256 timestamp) internal view returns (MembershipAtResult memory result) {
        Layout storage l = layout();
        uint256 start = l.historyStart;
        if (start == 0 || timestamp < start) {
            return MembershipAtResult({status: STATUS_UNKNOWN, role: 0, validFrom: 0, validTo: 0});
        }

        Interval[] storage list = l.intervals[member];
        uint256 len = list.length;

        for (uint256 i = 0; i < len; i++) {
            Interval storage iv = list[i];
            if (timestamp >= uint256(iv.from) && (iv.to == 0 || timestamp < uint256(iv.to))) {
                return MembershipAtResult({
                    status: STATUS_MEMBER,
                    role: iv.role,
                    validFrom: uint256(iv.from),
                    validTo: uint256(iv.to)
                });
            }
        }

        // Not a member at timestamp: compute cacheable None gap.
        uint256 gapFrom = start;
        uint256 gapTo = 0;

        for (uint256 i = 0; i < len; i++) {
            Interval storage iv = list[i];
            if (iv.to != 0 && uint256(iv.to) <= timestamp && uint256(iv.to) > gapFrom) {
                gapFrom = uint256(iv.to);
            }
            if (uint256(iv.from) > timestamp) {
                gapTo = uint256(iv.from);
                break;
            }
        }

        return MembershipAtResult({status: STATUS_NONE, role: 0, validFrom: gapFrom, validTo: gapTo});
    }
}
