# ZTNA Organisation & Perimeter Ownership Specification v0.1.0

> **Spec type:** Feature — Documents ownership and management of perimeters through organisations.
> **Path:** `docs/specs/feature-ztna-org-perimeter-ownership.md`

## Overview

ZTNAOrganisation and ZTNAPerimeterContract together provide a hierarchical ownership and access-control model. An organisation can own multiple perimeters (ZTNA fleets), and organisation members—with roles Owner, Admin, or Member—receive permissions that propagate to owned perimeters. The main use case is enterprise fleet management: a single organisation owns many perimeters, and admins can manage them without needing EOA-level ownership.

**Identity model:** EOAs (externally owned accounts) do **not** directly participate as org or perimeter members. Each EOA has an on-chain identity contract—a **ZTNAWallet**—created by the registry. The ZTNAWallet address is the actual member/owner in organisations and perimeters; the EOA owns and controls the wallet via `submit()`. All membership and ownership in this spec refers to **ZTNAWallet addresses**, unless explicitly noted.

**Integration context:**

- `ZTNAWallet` — On-chain identity contract; EOA owns it; used as member/owner address in orgs and perimeters
- `ZTNAOrganisation` — Organisation contract; roles, membership, perimeter ownership (members = wallet addresses)
- `ZTNAPerimeterContract` — Perimeter (fleet) contract; users, devices, tags (users = wallet addresses)
- `FleetContractUpgradeable` — Base contract; `operator` is the on-chain owner (wallet or org)
- `ZTNAPerimeterRegistry` — Registry for creating fleets/orgs/wallets, tracking ownership and membership
- `ManagedProxy` — Proxy pattern for deployable instances

---

## Design Principles

1. **Operator equals on-chain ownership.** The perimeter’s `operator` (from FleetContractUpgradeable) is the single on-chain owner; only they can transfer ownership.
2. **Organisation as owner.** When an organisation owns a perimeter, the organisation contract address is the perimeter’s `operator`.
3. **Role hierarchy.** Owner > Admin > Member; each role has strictly defined permissions, no overlap beyond inheritance.
4. **Explicit admin propagation.** Organisation admins must call `addSelfAsPerimeterAdmin` to become perimeter admins; membership does not imply perimeter access.
5. **Registry as source of truth.** The registry tracks org membership (admin/member) and org-owned fleets for UI and discovery.
6. **Wallet as identity.** ZTNAWallet contracts are the on-chain identities; EOAs own and control them via `submit()`.

---

## Identity Model: EOA → ZTNAWallet → Membership

```
  ┌─────────────┐         owns         ┌─────────────────────┐         member of       ┌──────────────────┐
  │  EOA        │ ───────────────────> │  ZTNAWallet         │ ─────────────────────>  │  Organisation    │
  │  (human/    │   Owner() = EOA      │  (on-chain identity)│   owner, members,       │  Perimeter       │
  │   key)      │                      │  submit() from EOA  │   admins = wallet addr  │  users = wallet  │
  └─────────────┘                      └─────────────────────┘                         └──────────────────┘
                                               │
                                               │ Registry.CreateUserWallet()
                                               │ UserWallet(eoa) → wallet
                                               ▼
                                       Registry creates one wallet
                                       per EOA (deterministic key)
```

**Flow:** EOA calls `registry.CreateUserWallet()` → gets ZTNAWallet. EOA owns wallet (`wallet.Owner() == eoa`). EOA signs and calls `wallet.submit(dest, token, data)` to act as the wallet. Organisation and perimeter store **wallet addresses** as owner/members/users—never raw EOA addresses for membership.

---

## Architecture Diagrams

### 1. High-Level Ownership Model

```
                    ┌─────────────────────────────────────┐
                    │      ZTNAPerimeterRegistry          │
                    │  - CreateUserWallet()               │
                    │  - CreateFleet()                    │
                    │  - CreateOrganisation()             │
                    │  - org callbacks (membership)       │
                    └──────────────┬──────────────────────┘
                                   │
           ┌───────────────────────┼───────────────────────┐
           │                       │                       │
           ▼                       ▼                       ▼
  ┌────────────────┐    ┌─────────────────────┐   ┌────────────────┐
  │ EOA ──owns──>  │    │ ZTNAOrganisation    │   │ EOA ──owns──>  │
  │ Wallet A       │    │ owner: Wallet X     │   │ Wallet C       │
  │ (operator of   │    │ members: [WX,WY,WZ] │   │ (operator of   │
  │  Perimeter A)  │    │ admins: [WX]        │   │  Perimeter C)  │
  └───────┬────────┘    └──────────┬──────────┘   └────────────────┘
          │                         │ operator (owns)
          │                         ▼
          │               ┌────────────────────┐
          │               │ Perimeter B        │
          │               │ operator = Org     │
          │               │ (Org owns it)      │
          │               └────────────────────┘
          │
          ▼
  ┌────────────────────┐
  │ Perimeter A        │
  │ operator = Wallet A│
  └────────────────────┘
```

*Wallet = ZTNAWallet contract address. EOA owns wallet; wallet is operator/member.*

### 2. Organisation Internal Structure

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        ZTNAOrganisation                                  │
│                                                                          │
│  owner: Wallet (single; EOA owns wallet)                                 │
│  members: Set<address>  memberInfo: address => Member  (address = wallet)│
│  perimeters: Set<address> perimeterInOrg: address => bool                │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ ROLE HIERARCHY (all addresses = ZTNAWallet)                       │   │
│  │                                                                   │   │
│  │   OWNER (1)          Full control: transfer ownership, remove     │   │
│  │       │              perimeters, add/remove admins, update org    │   │
│  │       ▼                                                           │   │
│  │   ADMIN (N)          Manage members (non-admin only), create      │   │
│  │       │              perimeters, transfer perimeters to org,      │   │
│  │       │              add self as perimeter admin                  │   │
│  │       ▼                                                           │   │
│  │   MEMBER (N)         View-only: getMembers, getPerimeters, etc.   │   │
│  │                                                                   │   │
│  └───────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

### 3. Perimeter Internal Structure (Roles)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     ZTNAPerimeterContract                                │
│                     (extends FleetContractUpgradeable)                   │
│                                                                          │
│  operator: address  ← On-chain owner (ZTNAWallet or Org contract)        │
│                                                                          │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │ PERIMETER ROLES (addr = ZTNAWallet or Org)                        │   │
│  │                                                                   │   │
│  │   OPERATOR          Same as owner: can transferOperator           │   │
│  │   (inherited)       Full admin rights (users[op].isAdmin implied) │   │
│  │       │                                                           │   │
│  │       ▼                                                           │   │
│  │   ADMIN            users[addr].isAdmin == true OR addr == operator│   │
│  │   (N)              - create/update/remove users, groups, devices, │   │
│  │                    tags; addPerimeterAdmin                        │   │
│  │       │                                                           │   │
│  │       ▼                                                           │   │
│  │   MEMBER           users[addr].active == true (addr = wallet)     │   │
│  │   (N)              - read data; own devices; update own devices   │   │
│  │                                                                   │   │
│  └───────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4. Organisation Owns Perimeter: Permission Flow

```
  EOA ──> Wallet (Admin)               Organisation Contract              Perimeter
       │  (via submit)                        │                                │
       │  addSelfAsPerimeterAdmin(P)          │                                │
       │ ───────────────────────────────────> │                                │
       │  msg.sender = Wallet                 │  addPerimeterAdmin(walletAddr) │
       │                                      │ ──────────────────────────────>│
       │                                      │  (org is operator;             │
       │                                      │   org calls as operator,       │
       │                                      │   so onlyAdmin passes)         │
       │                                      │                                │
       │                                      │  users[wallet] created/updated │
       │                                      │  isAdmin = true                │
       │                                      │                                │
```

### 5. How Organisation Acquires a Perimeter

```
  Scenario A: Create new perimeter
  ─────────────────────────────────
  Wallet (Owner/Admin) ──> org.createPerimeter(label) ──> Registry.CreateFleet(label)
  (EOA via submit)            msg.sender = Org
                              operator = Org
                              Org registers perimeter

  Scenario B: Transfer existing perimeter
  ───────────────────────────────────────
  Wallet (operator of P) ──> Org.transferPerimeterToOrganisation(P)
  (EOA via submit)            Requires: Wallet is owner/admin of Org
                              P.transferOperator(Org)
                              Org registers perimeter

  Scenario C: Register already-transferred perimeter
  ──────────────────────────────────────────────────
  Wallet ──> P.transferOperator(Org)  (direct, if Wallet is operator)
  Org Admin (Wallet) ──> registerPerimeter(P)
                         Requires: P.Operator() == Org
```

---

## Roles & Permissions

### Organisation Roles

| Role    | Who                    | Permissions |
|---------|------------------------|-------------|
| **Owner** | Single ZTNAWallet (`owner`) | Update org name/description; transfer ownership; add/remove members and admins; remove perimeters (with new owner); all Admin permissions |
| **Admin** | Wallet addresses with `isAdmin == true` | Add members (non-admin only); update member info; remove non-admin members; create perimeter; transfer perimeter to org; register perimeter; add self as perimeter admin; view all org data |
| **Member** | Wallet addresses with `active == true` | View members, admins, perimeters; no write access |

### Perimeter Roles (Internal)

| Role     | Who                            | Permissions |
|----------|---------------------------------|-------------|
| **Operator** | `operator` (ZTNAWallet or Org contract) | Transfer operator; implicit admin rights; full control |
| **Admin**    | `users[addr].isAdmin` or `addr == operator` (addr = wallet) | Create/update/remove users, groups, devices, tags; add perimeter admins |
| **Member**   | `users[addr].active` (addr = ZTNAWallet) | Read data; create/update/remove own devices; transfer device ownership |
| **Device Owner** | `devices[id].owner == addr` or admin (addr = wallet) | Update device, add/remove from tags, set device properties |

### Ownership Semantics

| Entity       | Owner                    | Meaning |
|-------------|--------------------------|---------|
| ZTNAWallet  | `owner` (EOA)            | EOA owns wallet; controls via `submit()` |
| Organisation | `owner` (ZTNAWallet)    | Single owner; can transfer to another wallet |
| Perimeter    | `operator` (ZTNAWallet or Org) | On-chain owner; only they can call `transferOperator` |
| Device       | `devices[id].owner`      | Wallet address; can update device, transfer ownership |
| Organisation membership | Registry callbacks | Registry tracks `adminOrganisations`, `memberOrganisations` per wallet address |

---

## Output Structure

**Do generate:** Spec document, role/permission tables, diagrams, test cases (yaml), integration notes.

**Do not generate:** New contract implementations, breaking changes to existing contracts, package metadata.

---

## Type Conventions

> **Platform:** Solidity ^0.8.20, Foundry tests.

| Type       | Meaning                         | Examples |
|------------|----------------------------------|----------|
| `address`  | Ethereum address                 | `0x1234...` |
| `address payable` | Same, for transfers     | `payable(0x...)` |
| `string`   | UTF-8 text                      | `"Fleet 1"` |
| `bool`     | Boolean                         | `true`, `false` |
| `bytes32`  | Contract type identifier         | `"ZTNAOrganisation"` |
| `error`    | Revert with short code           | `"YNO"`, `"YNOA"` |

---

## Error Handling

| Context  | Error style |
|----------|-------------|
| Solidity | `require(cond, "CODE")` — revert with short error code |
| Foundry | `vm.expectRevert("CODE")` or custom error |

**Error codes (organisation):**

| Code | Meaning |
|------|---------|
| `AI` | Already initialized |
| `YNO` | You are not owner |
| `YNOA` | You are not owner or admin |
| `YNOM` | You are not owner or member |
| `YNM` | You are not member |
| `YNPO` | You are not perimeter owner |
| `INVALID_OWNER` | New owner is zero |
| `INVALID_MEMBER` | Member address is zero |
| `ALREADY_MEMBER` | Address already a member |
| `ONLY_OWNER_CAN_ADD_ADMIN` | Non-owner tried to add admin |
| `ALREADY_SET` | Admin status unchanged |
| `NOT_ADMIN` | Member is not admin |
| `ONLY_OWNER_CAN_REMOVE_ADMIN` | Admin tried to remove another admin |
| `PERIMETER_ALREADY_IN_ORG` | Perimeter already registered |
| `PERIMETER_NOT_OWNED_BY_ORG` | Perimeter operator ≠ org |
| `PERIMETER_NOT_IN_ORG` | Perimeter not in org set |
| `INVALID_NEW_OWNER` | New owner for removePerimeter is zero |

**Error codes (perimeter):**

| Code | Meaning |
|------|---------|
| `AUTH` | Not authorised |
| `UNE` | User does not exist |
| `UGNE` | User group does not exist |
| `DNE` | Device does not exist |
| `TNE` | Tag does not exist |
| `IUA` | Invalid user address |
| `UAE` | User already exists |
| `IDA` | Invalid device address |
| `DAE` | Device already exists |
| `DUP` | Device key pair already exists |

---

## API Surface

### Organisation: Role & Membership

#### addMember(member, nickname?, email?, avatarURI?, asAdmin?) → void

Add a member to the organisation. Only owner can set `asAdmin == true`.

**Arguments:** `member` (ZTNAWallet address), optional profile strings, `asAdmin` (bool, default false).

**Behavior:** Reverts if `member` is zero, already a member, or non-owner adds admin. Calls registry `orgAddMember` (and `orgAddAdmin` if admin).

---

#### addAdmin(admin) → void

Convenience: add member as admin. Owner only.

---

#### setAdmin(member, adminStatus) → void

Set or remove admin status. Owner only. Reverts if already in desired state.

---

#### removeMember(member) → void

Remove member. Owner can remove anyone; admin can remove only non-admins.

---

#### isOwner(user) → bool

Returns `owner == user`.

---

#### isAdmin(user) → bool

Returns member is active and `isAdmin == true`.

---

#### isMember(user) → bool

Returns member is active.

---

#### isOwnerOrAdmin(user) → bool

Returns owner or admin.

---

### Organisation: Perimeter Management

#### createPerimeter(label) → address

Create a new perimeter via registry. Registry creates fleet with `msg.sender = org`, so operator = org. Org adds perimeter to its set. Owner or admin.

---

#### transferPerimeterToOrganisation(perimeter) → void

Caller (ZTNAWallet) must be owner/admin of org and operator of perimeter. Transfers perimeter's operator to org, then registers. Reverts if perimeter already in org.

---

#### registerPerimeter(perimeter) → void

Register a perimeter already owned by org (operator == org). For when transfer was done out-of-band. Owner or admin.

---

#### removePerimeter(perimeter, newOwner) → void

Transfer perimeter to `newOwner` (ZTNAWallet or Org) and remove from org. Owner only. `newOwner` must not be zero.

---

#### addSelfAsPerimeterAdmin(perimeter, nickname) → void

Add caller (msg.sender = ZTNAWallet) as admin to the perimeter. Requires org owns perimeter; caller wallet must be owner or admin of org. Creates or updates perimeter user with `isAdmin = true`.

---

### Perimeter: Access Control (Relevant to Org)

#### addPerimeterAdmin(userAddress, nickname) → void

Add user (ZTNAWallet address) as perimeter admin. Creates user if needed. Admin only (operator or `users[addr].isAdmin`).

---

#### Operator() → address

Returns the on-chain owner (ZTNAWallet or org contract).

---

#### transferOperator(newOperator) → void

Transfer ownership. Operator only.

---

## Testing

### Test Data Format

Tests are defined in `docs/specs/tests-ztna-org-perimeter.yaml`. Example structure:

```yaml
addMember:
  - name: "owner adds member"
    input: { member: "0xAlice", nickname: "Alice", asAdmin: false }
    output: null
    error: false
  - name: "admin cannot add admin"
    input: { member: "0xBob", asAdmin: true }
    output: null
    error: "ONLY_OWNER_CAN_ADD_ADMIN"

addSelfAsPerimeterAdmin:
  - name: "org admin adds self to perimeter"
    input: { perimeter: "0xPerimeter", nickname: "OrgAdmin" }
    output: null
    error: false
  - name: "member cannot add self"
    input: { perimeter: "0xPerimeter", nickname: "Member" }
    output: null
    error: "YNOA"
```

### Input Field Mapping

- **addMember:** `{ member: address, nickname?: string, email?: string, avatarURI?: string, asAdmin?: bool }`
- **addSelfAsPerimeterAdmin:** `{ perimeter: address, nickname: string }`
- **transferPerimeterToOrganisation:** `{ perimeter: address }`
- **removePerimeter:** `{ perimeter: address, newOwner: address }`

Implementations MAY add tests; spec tests MUST pass unchanged.

---

## Integration Notes

1. **ZTNAWallet as identity:** Before joining orgs/perimeters, users call `registry.CreateUserWallet()` to get their wallet. The registry keys wallets by `keccak256("userWallet2", eoa)`. All org/perimeter membership uses wallet addresses.
2. **Wallet control:** EOA controls wallet via `wallet.submit(destination, data)` (direct) or `wallet.submit(destination, siweToken, data)` (signed). The wallet forwards calls as `msg.sender` to downstream contracts.
3. **Registry dependency:** Organisation holds immutable `REGISTRY`. CreateFleet, org callbacks depend on it.
4. **CreateFleet `msg.sender`:** When org calls `CreateFleet`, `msg.sender` is org address; fleet is created with operator = org.
5. **GetOwnFleetCount:** When org calls, registry returns fleets where `userFleets[org]`; org uses this after createPerimeter to fetch the new fleet.
6. **Proxy pattern:** Organisation and perimeter are deployed via ManagedProxy; storage layout must remain stable.

---

## Implementation Checklist

- [x] Roles and permissions documented
- [x] ASCII diagrams for ownership and permission flow
- [x] Error handling defined
- [x] API surface documented
- [x] tests-ztna-org-perimeter.yaml created
- [ ] Integration tests for org-perimeter flows (in test suite)

---

## Version History

- **v0.1.0** — Initial specification (roles, ownership, diagrams)
- **v0.1.1** — Identity model: EOA → ZTNAWallet → membership; diagrams updated for wallet-as-identity
