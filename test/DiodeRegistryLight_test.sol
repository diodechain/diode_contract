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
    CallForwarder relay;

    constructor() {
        relay = new CallForwarder(address(0));
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
        reg.ContractStake(fleet1, amount);

        assertEq(diode.balanceOf(address(reg)), amount);
        assertEq(diode.balanceOf(address(diode)), 0);

        DiodeRegistryLight.FleetStat memory f = reg.GetFleet(fleet1);
        assertEq(f.currentBalance, amount);
    }

    function testUnstake() public {
        uint amount = 100000;
        reg.ContractUnstake(fleet1, amount);
        DiodeRegistryLight.FleetStat memory f = reg.GetFleet(fleet1);
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

    function testReward() public {
        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        uint amount = 100000;
        uint blockHeight = block.number + 1;
        uint totalConnections = 3;
        uint totalBytes = 5;
        bytes32 localAddress = "fake";
        vm.roll(block.number + 2);

        bytes32[] memory ticket = new bytes32[](6);
        ticket[0] = blockhash(blockHeight);
        ticket[1] = Utils.addressToBytes32(address(fleet1));
        ticket[2] = Utils.addressToBytes32(address(relay));
        ticket[3] = bytes32(totalConnections);
        ticket[4] = bytes32(totalBytes);
        ticket[5] = localAddress;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            alicePk,
            Utils.bytes32Hash(ticket)
        );

        bytes32[3] memory sig = [r, s, bytes32(uint256(v))];

        fleet1.SetDeviceAllowlist(alice, true);

        reg.SubmitTicket(
            blockHeight,
            fleet1,
            address(relay),
            totalConnections,
            totalBytes,
            localAddress,
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
        assertEq(f.currentBalance, amount - expectedReward, "currentBalance==0");
        assertEq(reg.foundationWithdrawableBalance(), expectedTax, "foundationWithdrawableBalance==10");
        assertEq(reg.relayRewards(address(relay)), expectedReward - expectedTax, "relayRewards==1000");

        reg.FoundationWithdraw();
        reg.RelayWithdraw(address(relay));

        assertEq(reg.foundationWithdrawableBalance(), 0, "foundationWithdrawableBalance==0");
        assertEq(reg.relayRewards(address(relay)), 0, "relayRewards==0");

        assertEq(diode.balanceOf(address(relay)), expectedReward - expectedTax);
        assertEq(diode.balanceOf(foundation), expectedTax);
        assertEq(diode.balanceOf(address(reg)), amount - expectedReward);
    }
}
