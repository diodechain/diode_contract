// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/DiodeRegistryLight.sol";
import "../contracts/DiodeToken.sol";
import "../contracts/FleetContract.sol";
import "../contracts/deps/Utils.sol";

import "./forge-std/Test.sol";

contract DiodeRegistryLightTest is Test {
    DiodeRegistryLight reg;
    DiodeToken diode;
    address foundation;
    CallForwarder foundation_cf;
    DiodeToken foundation_token;
    FleetContract fleet1;
    FleetContract fleet2;
    CallForwarder relay1;
    CallForwarder relay2;

    constructor() {
        relay1 = new CallForwarder(address(0));
        relay2 = new CallForwarder(address(0));
        foundation_cf = new CallForwarder(address(0));
        foundation = address(foundation_cf);
        diode = new DiodeToken(foundation, foundation, true);
        foundation_cf.__updateTarget(address(diode));
        foundation_token = DiodeToken(foundation);
        reg = new DiodeRegistryLight(foundation, diode);

        fleet1 = new FleetContract(address(this), address(this));
        fleet2 = new FleetContract(address(this), address(this));

        // Initializing fleet1 with some stake
        uint amount = 100000;
        foundation_token.mint(address(this), amount);
        assertEq(diode.balanceOf(address(this)), amount);

        diode.approve(address(reg), amount);
    }

    function testUnstake() public {
        uint amount = 100000;
        reg.ContractStake(fleet1, amount);

        assertEq(diode.balanceOf(address(reg)), amount);
        assertEq(diode.balanceOf(address(diode)), 0);

        DiodeRegistryLight.FleetStat memory f = reg.GetFleet(fleet1);
        assertEq(f.currentBalance, amount);

        reg.ContractUnstake(fleet1, amount);
        f = reg.GetFleet(fleet1);
        assertEq(f.currentBalance, amount);
        assertEq(f.withdrawRequestSize, amount);
        assertEq(f.withdrawableBalance, 0);
        uint epoch = f.currentEpoch;

        vm.warp(block.timestamp + reg.SecondsPerEpoch() + 1);
        reg.EndEpochForAllFleets();

        f = reg.GetFleet(fleet1);
        assertEq(f.currentEpoch, epoch + 1, "nextEpoch");
        assertEq(f.currentBalance, 0, "currentBalance==0");
        assertEq(f.withdrawRequestSize, 0, "withdrawRequestSize==0");
        assertEq(f.withdrawableBalance, amount, "withdrawableBalance==amount");
    }

    function testReward_100k() public {
        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        uint amount = 100000;
        reg.ContractStake(fleet1, amount);
        uint blockHeight = block.number + 1;
        uint totalConnections = 3;
        uint totalBytes = 5;
        vm.roll(block.number + 2);

        bytes32[] memory ticket = new bytes32[](6);
        ticket[0] = blockhash(blockHeight);
        ticket[1] = Utils.addressToBytes32(address(fleet1));
        ticket[2] = Utils.addressToBytes32(address(relay1));
        ticket[3] = bytes32(totalConnections);
        ticket[4] = bytes32(totalBytes);
        ticket[5] = "fake";

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePk,
            Utils.bytes32Hash(ticket)
        );

        bytes32[3] memory sig = [r, s, bytes32(uint256(v))];

        fleet1.SetDeviceAllowlist(alice, true);

        reg.SubmitTicket(
            blockHeight,
            fleet1,
            address(relay1),
            totalConnections,
            totalBytes,
            ticket[5],
            sig
        );

        DiodeRegistryLight.FleetStat memory f = reg.GetFleet(fleet1);
        assertEq(f.score, 3077, "prev fleetScore==3077");
        assertEq(f.currentBalance, amount, "currentBalance==amount");
        assertEq(f.withdrawRequestSize, 0, "withdrawRequestSize==0");

        vm.warp(block.timestamp + reg.SecondsPerEpoch() + 1);
        reg.EndEpochForAllFleets();

        f = reg.GetFleet(fleet1);
        uint expectedReward = amount / 100;
        uint expectedTax = expectedReward / 100;

        assertEq(f.score, 0, "fleetScore==0");
        assertEq(
            f.currentBalance,
            amount - expectedReward,
            "currentBalance==0"
        );
        assertEq(
            reg.foundationWithdrawableBalance(),
            expectedTax,
            "foundationWithdrawableBalance==10"
        );
        assertEq(
            reg.relayRewards(address(relay1)),
            expectedReward - expectedTax,
            "relayRewards==1000"
        );

        reg.FoundationWithdraw();
        reg.RelayWithdraw(address(relay1));

        assertEq(
            reg.foundationWithdrawableBalance(),
            0,
            "foundationWithdrawableBalance==0"
        );
        assertEq(reg.relayRewards(address(relay1)), 0, "relayRewards==0");

        assertEq(
            diode.balanceOf(address(relay1)),
            expectedReward - expectedTax
        );
        assertEq(diode.balanceOf(foundation), expectedTax);
        assertEq(diode.balanceOf(address(reg)), amount - expectedReward);
    }

    function testReward_1k() public {
        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        uint amount = 1000;
        reg.ContractStake(fleet1, amount);
        uint blockHeight = block.number + 1;
        uint totalConnections = 3;
        uint totalBytes = 5;
        vm.roll(block.number + 2);

        bytes32[] memory ticket = new bytes32[](6);
        ticket[0] = blockhash(blockHeight);
        ticket[1] = Utils.addressToBytes32(address(fleet1));
        ticket[2] = Utils.addressToBytes32(address(relay1));
        ticket[3] = bytes32(totalConnections);
        ticket[4] = bytes32(totalBytes);
        ticket[5] = "fake";

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePk,
            Utils.bytes32Hash(ticket)
        );

        bytes32[3] memory sig = [r, s, bytes32(uint256(v))];

        fleet1.SetDeviceAllowlist(alice, true);

        reg.SubmitTicket(
            blockHeight,
            fleet1,
            address(relay1),
            totalConnections,
            totalBytes,
            ticket[5],
            sig
        );

        DiodeRegistryLight.FleetStat memory f = reg.GetFleet(fleet1);
        assertEq(f.score, 3077, "prev fleetScore==3077");
        assertEq(f.currentBalance, amount, "currentBalance==amount");
        assertEq(f.withdrawRequestSize, 0, "withdrawRequestSize==0");

        vm.warp(block.timestamp + reg.SecondsPerEpoch() + 1);
        reg.EndEpochForAllFleets();

        f = reg.GetFleet(fleet1);
        uint expectedReward = amount / 100;
        uint expectedTax = expectedReward / 100;

        assertEq(f.score, 0, "fleetScore==0");
        assertEq(
            f.currentBalance,
            amount - expectedReward,
            "currentBalance==0"
        );
        assertEq(
            reg.foundationWithdrawableBalance(),
            expectedTax,
            "foundationWithdrawableBalance==10"
        );
        assertEq(
            reg.relayRewards(address(relay1)),
            expectedReward - expectedTax,
            "relayRewards==1000"
        );

        reg.FoundationWithdraw();
        reg.RelayWithdraw(address(relay1));

        assertEq(
            reg.foundationWithdrawableBalance(),
            0,
            "foundationWithdrawableBalance==0"
        );
        assertEq(reg.relayRewards(address(relay1)), 0, "relayRewards==0");

        assertEq(
            diode.balanceOf(address(relay1)),
            expectedReward - expectedTax
        );
        assertEq(diode.balanceOf(foundation), expectedTax);
        assertEq(diode.balanceOf(address(reg)), amount - expectedReward);
    }

    function testReward_2_relays() public {
        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        // (address bob, uint256 bobPk) = makeAddrAndKey("bob");
        // Testing for rounding errors with 1001 divided by to relays
        uint amount = 1100;
        reg.ContractStake(fleet1, amount);
        uint blockHeight = block.number + 1;
        uint totalConnections = 3;
        uint totalBytes = 5;
        vm.roll(block.number + 2);

        bytes32[] memory ticket = new bytes32[](6);
        ticket[0] = blockhash(blockHeight);
        ticket[1] = Utils.addressToBytes32(address(fleet1));
        ticket[2] = Utils.addressToBytes32(address(relay1));
        ticket[3] = bytes32(totalConnections);
        ticket[4] = bytes32(totalBytes);
        ticket[5] = "fake";

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePk,
            Utils.bytes32Hash(ticket)
        );

        bytes32[3] memory sig = [r, s, bytes32(uint256(v))];
        fleet1.SetDeviceAllowlist(alice, true);
        reg.SubmitTicket(
            blockHeight,
            fleet1,
            address(relay1),
            totalConnections,
            totalBytes,
            ticket[5],
            sig
        );

        // Update the ticket for a different relay
        ticket[2] = Utils.addressToBytes32(address(relay2));
        (v, r, s) = vm.sign(alicePk, Utils.bytes32Hash(ticket));

        sig = [r, s, bytes32(uint256(v))];
        reg.SubmitTicket(
            blockHeight,
            fleet1,
            address(relay2),
            totalConnections,
            totalBytes,
            ticket[5],
            sig
        );

        // Check values
        DiodeRegistryLight.FleetStat memory f = reg.GetFleet(fleet1);
        assertEq(f.score, 6154, "prev fleetScore==6154");
        assertEq(f.currentBalance, amount, "currentBalance==amount");
        assertEq(f.withdrawRequestSize, 0, "withdrawRequestSize==0");

        // Finish epoch
        vm.warp(block.timestamp + reg.SecondsPerEpoch() + 1);
        reg.EndEpochForAllFleets();

        // Check rewards
        f = reg.GetFleet(fleet1);
        uint expectedReward = amount / (2 * 100);
        uint expectedTax = expectedReward / 100;

        assertEq(f.score, 0, "fleetScore==0");
        assertEq(
            f.currentBalance,
            amount - 2 * expectedReward - 1,
            "currentBalance==1089"
        );
        assertEq(
            reg.foundationWithdrawableBalance(),
            2 * expectedTax + 1,
            "foundationWithdrawableBalance==2"
        );
        assertEq(
            reg.relayRewards(address(relay1)),
            expectedReward - expectedTax,
            "relayRewards==5"
        );
        assertEq(
            reg.relayRewards(address(relay2)),
            expectedReward - expectedTax,
            "relayRewards==5"
        );
        assertEq(
            diode.balanceOf(address(reg)),
            reg.relayRewards(address(relay1)) +
                reg.relayRewards(address(relay2)) +
                reg.foundationWithdrawableBalance() +
                f.currentBalance,
            "sum==amount"
        );

        reg.FoundationWithdraw();
        reg.RelayWithdraw(address(relay1));
        reg.RelayWithdraw(address(relay2));

        assertEq(
            reg.foundationWithdrawableBalance(),
            0,
            "foundationWithdrawableBalance==0"
        );
        assertEq(reg.relayRewards(address(relay1)), 0, "relay1Rewards==0");
        assertEq(reg.relayRewards(address(relay2)), 0, "relay2Rewards==0");

        assertEq(
            diode.balanceOf(address(relay1)),
            expectedReward - expectedTax,
            "relay1 got reward"
        );
        assertEq(
            diode.balanceOf(address(relay2)),
            expectedReward - expectedTax,
            "relay2 got reward"
        );
        assertEq(
            diode.balanceOf(foundation),
            2 * expectedTax + 1,
            "Foundation got tax rounded up"
        );
        assertEq(diode.balanceOf(foundation), 1, "Foundation got tax");
        assertEq(
            diode.balanceOf(address(reg)),
            amount - 2 * expectedReward - 1,
            "registry deducted rewards rounded down"
        );
    }
}
