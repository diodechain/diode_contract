// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;

import "../contracts/DiodeRegistryLight.sol";
import "../contracts/DiodeToken.sol";
import "./forge-std/Test.sol";

/// @notice Exposes storage slot numbers for layout regression tests (proxy upgrades).
contract DiodeRegistryLightStorageHarness is DiodeRegistryLight {
    constructor(address foundation, IERC20 token) DiodeRegistryLight(foundation, token) {}

    function slotRelayArray() external pure returns (uint256 s) {
        assembly {
            s := relayArray.slot
        }
    }

    function slotRelayRewards() external pure returns (uint256 s) {
        assembly {
            s := relayRewards.slot
        }
    }

    function slotCurrentEpoch() external pure returns (uint256 s) {
        assembly {
            s := currentEpoch.slot
        }
    }

    function slotCurrentEpochStart() external pure returns (uint256 s) {
        assembly {
            s := currentEpochStart.slot
        }
    }

    function slotPreviousEpochStart() external pure returns (uint256 s) {
        assembly {
            s := previousEpochStart.slot
        }
    }

    function slotFoundationTaxRate() external pure returns (uint256 s) {
        assembly {
            s := foundationTaxRate.slot
        }
    }

    function slotFoundationWithdrawableBalance() external pure returns (uint256 s) {
        assembly {
            s := foundationWithdrawableBalance.slot
        }
    }

    function slotConnectionScore() external pure returns (uint256 s) {
        assembly {
            s := connectionScore.slot
        }
    }

    function slotByteScore() external pure returns (uint256 s) {
        assembly {
            s := byteScore.slot
        }
    }

    function slotFleetArray() external pure returns (uint256 s) {
        assembly {
            s := fleetArray.slot
        }
    }

    function slotFleetStats() external pure returns (uint256 s) {
        assembly {
            s := fleetStats.slot
        }
    }

    function slotRelayInArray() external pure returns (uint256 s) {
        assembly {
            s := relayInArray.slot
        }
    }
}

/// @dev Slot layout from DiodeRegistryLight v111 (Initializable gap + state), via `forge inspect`.
contract DiodeRegistryLightStorageLayoutTest is Test {
    uint256 internal constant SLOT_RELAY_ARRAY = 51;
    uint256 internal constant SLOT_RELAY_REWARDS = 52;
    uint256 internal constant SLOT_CURRENT_EPOCH = 53;
    uint256 internal constant SLOT_CURRENT_EPOCH_START = 54;
    uint256 internal constant SLOT_PREVIOUS_EPOCH_START = 55;
    uint256 internal constant SLOT_FOUNDATION_TAX_RATE = 56;
    uint256 internal constant SLOT_FOUNDATION_WITHDRAWABLE = 57;
    uint256 internal constant SLOT_CONNECTION_SCORE = 58;
    uint256 internal constant SLOT_BYTE_SCORE = 59;
    uint256 internal constant SLOT_FLEET_ARRAY = 60;
    uint256 internal constant SLOT_FLEET_STATS = 61;
    /// @dev First slot after v111 layout; new variables must only be appended here.
    uint256 internal constant SLOT_RELAY_IN_ARRAY = 62;

    DiodeRegistryLightStorageHarness harness;

    function setUp() public {
        DiodeToken token = new DiodeToken(address(this), address(this), true);
        harness = new DiodeRegistryLightStorageHarness(address(this), token);
    }

    function testStorageLayout_matchesV111BaseSlots() public view {
        assertEq(harness.slotRelayArray(), SLOT_RELAY_ARRAY);
        assertEq(harness.slotRelayRewards(), SLOT_RELAY_REWARDS);
        assertEq(harness.slotCurrentEpoch(), SLOT_CURRENT_EPOCH);
        assertEq(harness.slotCurrentEpochStart(), SLOT_CURRENT_EPOCH_START);
        assertEq(harness.slotPreviousEpochStart(), SLOT_PREVIOUS_EPOCH_START);
        assertEq(harness.slotFoundationTaxRate(), SLOT_FOUNDATION_TAX_RATE);
        assertEq(harness.slotFoundationWithdrawableBalance(), SLOT_FOUNDATION_WITHDRAWABLE);
        assertEq(harness.slotConnectionScore(), SLOT_CONNECTION_SCORE);
        assertEq(harness.slotByteScore(), SLOT_BYTE_SCORE);
        assertEq(harness.slotFleetArray(), SLOT_FLEET_ARRAY);
        assertEq(harness.slotFleetStats(), SLOT_FLEET_STATS);
    }

    function testStorageLayout_newVariablesAppendedAfterFleetStats() public view {
        assertEq(harness.slotRelayInArray(), SLOT_RELAY_IN_ARRAY);
        assertGt(harness.slotRelayInArray(), harness.slotFleetStats());
    }
}
