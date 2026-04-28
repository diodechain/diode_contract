// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;

import "../contracts/FleetContractUpgradeable.sol";
import "./forge-std/Test.sol";

/// @dev Calls `initialize` from the constructor so `initializer` accepts (`isConstructor()`).
contract FleetContractHarness is FleetContractUpgradeable {
    constructor(address registry, address payable operatorAccount) FleetContractUpgradeable(registry) {
        initialize(operatorAccount);
    }
}

contract FleetContractUpgradeableTest is Test {
    FleetContractUpgradeable internal fleet;
    address internal constant REGISTRY = address(0xBEEF);

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");

    function setUp() public {
        fleet = FleetContractUpgradeable(address(new FleetContractHarness(REGISTRY, payable(address(this)))));
    }

    function test_Version_returns_400() public view {
        assertEq(fleet.Version(), 400);
    }

    function test_AddDeviceBatch_sets_allowlist_and_count() public {
        address[] memory batch = new address[](2);
        batch[0] = alice;
        batch[1] = bob;
        fleet.AddDeviceBatch(batch);

        assertEq(fleet.GetDeviceCount(), 2);
        assertTrue(fleet.DeviceAllowlist(alice));
        assertTrue(fleet.DeviceAllowlist(bob));

        address[] memory page = fleet.GetDeviceList(0, 10);
        assertEq(page.length, 2);
        assertEq(page[0], alice);
        assertEq(page[1], bob);
    }

    function test_AddDeviceBatch_idempotent_same_address() public {
        address[] memory once = new address[](1);
        once[0] = alice;
        fleet.AddDeviceBatch(once);
        fleet.AddDeviceBatch(once);

        assertEq(fleet.GetDeviceCount(), 1);
        assertTrue(fleet.DeviceAllowlist(alice));
    }

    function test_RemoveDeviceBatch_clears_allowlist_and_enumeration() public {
        address[] memory batch = new address[](2);
        batch[0] = alice;
        batch[1] = bob;
        fleet.AddDeviceBatch(batch);

        address[] memory rm = new address[](1);
        rm[0] = alice;
        fleet.RemoveDeviceBatch(rm);

        assertEq(fleet.GetDeviceCount(), 1);
        assertFalse(fleet.DeviceAllowlist(alice));
        assertTrue(fleet.DeviceAllowlist(bob));

        address[] memory page = fleet.GetDeviceList(0, 10);
        assertEq(page.length, 1);
        assertEq(page[0], bob);
    }

    function test_SetDeviceAllowlist_updates_enumeration() public {
        fleet.SetDeviceAllowlist(alice, true);
        assertEq(fleet.GetDeviceCount(), 1);
        fleet.SetDeviceAllowlist(alice, false);
        assertEq(fleet.GetDeviceCount(), 0);
        assertFalse(fleet.DeviceAllowlist(alice));
    }

    function test_GetDeviceList_pagination_and_limit_cap() public {
        address[] memory batch = new address[](5);
        batch[0] = alice;
        batch[1] = bob;
        batch[2] = carol;
        batch[3] = makeAddr("d");
        batch[4] = makeAddr("e");
        fleet.AddDeviceBatch(batch);

        address[] memory first = fleet.GetDeviceList(0, 2);
        assertEq(first.length, 2);
        assertEq(first[0], alice);
        assertEq(first[1], bob);

        address[] memory mid = fleet.GetDeviceList(2, 2);
        assertEq(mid.length, 2);
        assertEq(mid[0], carol);

        address[] memory tail = fleet.GetDeviceList(4, 10);
        assertEq(tail.length, 1);
    }

    function test_GetDeviceList_zero_limit_returns_empty() public view {
        assertEq(fleet.GetDeviceList(0, 0).length, 0);
    }

    function test_GetDeviceList_offset_past_end_returns_empty() public {
        address[] memory batch = new address[](1);
        batch[0] = alice;
        fleet.AddDeviceBatch(batch);

        assertEq(fleet.GetDeviceList(5, 5).length, 0);
    }

    function test_non_operator_reverts_on_AddDeviceBatch() public {
        address[] memory batch = new address[](1);
        batch[0] = alice;

        vm.prank(alice);
        vm.expectRevert();
        fleet.AddDeviceBatch(batch);
    }

    function test_non_operator_reverts_on_RemoveDeviceBatch() public {
        address[] memory batch = new address[](1);
        batch[0] = alice;
        fleet.AddDeviceBatch(batch);

        vm.prank(bob);
        vm.expectRevert();
        fleet.RemoveDeviceBatch(batch);
    }

    function test_RemoveDeviceBatch_on_unknown_address_no_revert() public {
        address[] memory rm = new address[](1);
        rm[0] = alice;
        fleet.RemoveDeviceBatch(rm);
        assertEq(fleet.GetDeviceCount(), 0);
    }
}
