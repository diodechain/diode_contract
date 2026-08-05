# Client Usage Spec: Membership History (`RoleAt` / `MemberAt`)

This document describes how Diode Collab (ddrive) and other clients should use the on-chain membership history APIs to verify file signatures after a member or linked device has left.

## Versions

| Contract | Min version | APIs |
|---|---|---|
| `Drive` (zone) | `162` | `RoleAt`, `MembershipHistoryStart`, `EnsureMembershipHistory` |
| `DriveMember` (identity / linked devices) | `125` | `MemberAt`, `MembershipHistoryStart`, `EnsureMembershipHistory` |

Live ACL APIs (`Role`, `IsMember`, `Members`) are unchanged and still mean **authorized now**.

## Problem these APIs solve

A file signed while Alice was a zone member must remain verifiable after Alice leaves. The same applies to a linked device under `DriveMember` that is later removed.

Do **not** call `Role(addr)` / `IsMember(addr)` for historic file verification — those reflect current state only.

## Return type

Both `RoleAt` and `MemberAt` return:

```solidity
struct MembershipAtResult {
    uint8 status;      // see Status below
    uint256 role;      // meaningful only when status == Member
    uint256 validFrom; // inclusive unix timestamp
    uint256 validTo;   // exclusive unix timestamp; 0 = open-ended
}
```

### Status

| Value | Name | Meaning |
|---|---|---|
| `0` | `Unknown` | Timestamp is before history tracking began, or history was never initialized |
| `1` | `None` | Definitely **not** authorized in `[validFrom, validTo)` |
| `2` | `Member` | Authorized in `[validFrom, validTo)` with `role` |

### Role values

**Drive / `RoleAt`** — same constants as live `Role`:

| Role | Value |
|---|---|
| None | `0` |
| BackupBot | `100` |
| Reader | `200` |
| Member | `300` |
| Admin | `400` |
| Owner | `500` |

**DriveMember / `MemberAt`** — no zone roles; when `status == Member`, `role == 1` (membership marker).

### Interval semantics

- Authorization holds for timestamps `T` where `validFrom <= T < validTo`.
- If `validTo == 0`, the interval is **open-ended** as of chain head: holds for all `T >= validFrom` until membership changes again.
- Leave time is exclusive: at the leave timestamp, status is `None` (not `Member`).

## Access control (Oasis vs other chains)

History views use the same reader gate as live read APIs (`Role`, `IsMember`, …):

| API | Gate |
|---|---|
| `RoleAt` | `ProtectedRoleGroup.onlyReader` (zone) |
| `MemberAt` | `onlyReader` on `DriveMember` |
| `MembershipHistoryStart` | same as above per contract |
| `EnsureMembershipHistory` | **public** (any caller; needed after proxy upgrade) |

### Non-Oasis (Diode, Moonbeam, Base, …)

`requireReader` is a no-op. Anyone can call view history APIs. Third-party signature verification can query freely.

### Oasis (`ChainId.THIS == OASIS`)

Reads are **private**: the caller must be an authorized reader, identical to `Role` / other protected views.

**Drive / `ProtectedRoleGroup`:** caller must be `address(this)` or have `role(caller) > RoleType.None` (BackupBot and above). `Drive` additionally allows zone whitelist and registered chat contracts before that check.

**DriveMember:** caller must be `address(this)`, a member (or owner), an additional-drive address, or on the identity whitelist.

Implications for clients on Oasis:

- Signature verification must run as a reader (zone member / identity member / whitelisted verifier), not as an arbitrary third-party EOA.
- After a member leaves, that address can no longer call `RoleAt` / `MemberAt` — verify and cache intervals **while** the verifier still has read access, or use a long-lived reader/whitelist account for verification.
- On Oasis, do not assume public RPC eth_call as a stranger will succeed for membership history.

## Contract calls

### Drive (zone membership)

```text
RoleAt(address member, uint256 timestamp) → MembershipAtResult
MembershipHistoryStart() → uint256
EnsureMembershipHistory()  // state-changing; call once after proxy upgrade if needed
```

Use `RoleAt` when verifying that an identity (or EOA) was a zone member with a sufficient role at the file’s signature time.

### DriveMember (linked devices)

```text
MemberAt(address device, uint256 timestamp) → MembershipAtResult
MembershipHistoryStart() → uint256
EnsureMembershipHistory()
```

Use `MemberAt` when verifying that a device key was linked to an identity at the file’s signature time.

### Typical verification flow

```
1. Read file signature → signer address S, file time T (unix seconds)
2. If S is a DriveMember contract (identity):
     a. Optionally MemberAt(deviceKey, T) on that identity if the signer is a linked device
     b. RoleAt(identityAddress, T) on the Drive (zone)
   If S is an EOA member of the zone:
     RoleAt(S, T) on the Drive
3. Interpret status (see below)
4. Cache the returned interval for future files
```

Timestamps are **unix seconds**, matching `block.timestamp` — not block numbers. No binary search over blocks is required for membership once history is initialized.

On Oasis, steps 2a/2b must be submitted with a reader identity (see Access control).

## Interpreting results

### `status == Member` (2)

Signer was authorized. Use `role` for permission checks (e.g. “could change common settings”).

Cache key: `(driveOrIdentity, address, validFrom, validTo, role, status)`.

Reuse for any later file with the same contract + address and timestamp in range.

### `status == None` (1)

Signer was **not** authorized in that interval. Safe to reject the signature as unauthorized for that zone/identity.

Negative intervals are also cacheable (including gaps between leave and rejoin, where `validTo` is the rejoin time).

### `status == Unknown` (0)

History cannot answer. Causes:

1. Proxy not yet upgraded to Drive ≥ 162 / DriveMember ≥ 125
2. Upgraded but `EnsureMembershipHistory()` (or a membership mutation) has not run yet → `MembershipHistoryStart() == 0`
3. File timestamp `< MembershipHistoryStart()` (pre-upgrade / pre-ensure period)

**Client policy for Unknown:**

- Prefer falling back to the legacy archive `eth_call` / block-search path **only** for `Unknown`
- Do **not** treat `Unknown` as `None` (that would falsely reject valid pre-history signatures)
- Do **not** treat `Unknown` as `Member`

## Caching rules

```
cacheHit(T) =
  status != Unknown
  AND validFrom <= T
  AND (validTo == 0 OR T < validTo)
```

| Interval kind | Cache durability |
|---|---|
| Closed (`validTo != 0`) | Stable forever for that range |
| Open (`validTo == 0`) | Valid until the contract’s `change_tracker()` advances; then re-query |

Recommended invalidation for open intervals:

1. Store `change_tracker()` alongside the cached result
2. On next use, if `change_tracker()` differs, discard open-ended entries for that contract and re-call `RoleAt` / `MemberAt`

Batching: when verifying many files from the same signer, sort by timestamp and reuse one result across all files that fall in its interval.

## Upgrade / migration checklist

For **existing** zones and identities after deploying the new implementation:

1. Upgrade proxy to Drive `162` / DriveMember `125` via `DriveFactory.Upgrade`
2. Call `EnsureMembershipHistory()` once (any caller; public)
   - Sets `MembershipHistoryStart` to `block.timestamp`
   - Backfills open intervals for current members/devices from that start
3. Confirm `MembershipHistoryStart() > 0` (caller must be a reader on Oasis)
4. Switch verification path:
   - `T >= MembershipHistoryStart` → use `RoleAt` / `MemberAt`
   - `T < MembershipHistoryStart` or `status == Unknown` → legacy path

For **new** contracts created after this release, history starts automatically in `initialize` — no ensure tx required.

Membership mutations (`AddMember`, `RemoveMember`, role changes, etc.) also call ensure if history was not yet started.

## What history does *not* cover

- Membership before `MembershipHistoryStart` (always `Unknown`)
- Hard-revoke of past signatures (compromise); leave only closes the interval going forward
- Replacing archive nodes for other historical state — only membership-at-time is addressed here

## Minimal pseudocode

```elixir
def authorized_at?(contract, address, timestamp) do
  case role_or_member_at(contract, address, timestamp) do
    %{status: :member, role: role, valid_from: from, valid_to: to} ->
      cache_put(contract, address, from, to, role, :member)
      {:ok, role}

    %{status: :none, valid_from: from, valid_to: to} ->
      cache_put(contract, address, from, to, 0, :none)
      {:error, :not_authorized}

    %{status: :unknown} ->
      legacy_historical_role(contract, address, timestamp)
  end
end

defp role_or_member_at(drive, address, ts) when is_drive(drive),
  do: Contract.Drive.role_at(drive, address, ts)

defp role_or_member_at(identity, device, ts) when is_drive_member(identity),
  do: Contract.DriveMember.member_at(identity, device, ts)
```

## ABI reference

```text
RoleAt(address,uint256) → (uint8 status, uint256 role, uint256 validFrom, uint256 validTo)
MemberAt(address,uint256) → (uint8 status, uint256 role, uint256 validFrom, uint256 validTo)
MembershipHistoryStart() → uint256
EnsureMembershipHistory()
change_tracker() → uint256
```

View history APIs are reader-gated via `onlyReader` on Oasis (same family as `Role` / live membership reads) and unrestricted on other chains. `EnsureMembershipHistory` remains callable by anyone.
