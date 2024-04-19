// SPDX-License-Identifier: DIODE
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "./Assert.sol";
import "./CallForwarder.sol";
import "../contracts/DiodeRegistryLight.sol";
import "../contracts/DiodeToken.sol";
import "../contracts/FleetContract.sol";
import "./forge-std/Test.sol";

contract DiodeRegistryLightTest is Test {
    DiodeRegistryLight reg;
    DiodeToken diode;
    address foundation;
    CallForwarder foundation_cf;
    DiodeToken foundation_token;
    FleetContract fleet1;
    FleetContract fleet2;

    constructor() {
        foundation_cf = new CallForwarder(address(0));
        foundation = address(foundation_cf);
        diode = new DiodeToken(foundation, foundation, true);
        foundation_cf.__updateTarget(address(diode));
        foundation_token = DiodeToken(foundation);
        reg = new DiodeRegistryLight(foundation, diode);

        fleet1 = new FleetContract(address(this), address(this));
        fleet2 = new FleetContract(address(this), address(this));
    }

    function testJoin() public {
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
}
