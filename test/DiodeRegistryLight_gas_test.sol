// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./CallForwarder.sol";
import "../contracts/DiodeRegistryLight.sol";
import "../contracts/DiodeToken.sol";
import "../contracts/FleetContract.sol";
import "../contracts/deps/Utils.sol";
import "./forge-std/Test.sol";
import "./forge-std/console2.sol";

/// Gas benchmarks for DiodeRegistryLight epoch finalization vs ticket tree size.
///
/// EndEpochForFleet gas reference (measured via gasleft delta):
///   v111 delete-on-end:  scenarioB count=100 ~7_083_670
///   v112 epoch-scoped:   scenarioB count=100 ~6_864_308
///   v113 micro-opts:     scenarioB count=100 ~2_319_299
///   v114 layout-safe:    scenarioB count=100 ~4_543_999 (RelayReward struct restored for proxy slots)
contract DiodeRegistryLightGas is Test {
    /// v112 EndEpochForFleet at 100 relays (epoch-scoped, pre micro-optimization)
    uint256 internal constant V112_SCENARIO_B_100 = 6_864_308;
    /// v114 with proxy-safe RelayReward mapping at slot 52
    uint256 internal constant V114_SCENARIO_B_100 = 4_543_999;
    uint256 internal constant STAKE_AMOUNT = 100_000;
    uint256 internal constant CONNECTIONS = 3;
    uint256 internal constant BYTES = 5;

    uint256[] internal counts = [1, 10, 25, 50, 100];

    struct Env {
        DiodeRegistryLight reg;
        DiodeToken diode;
        DiodeToken foundationToken;
        FleetContract fleet1;
        FleetContract fleet2;
        CallForwarder relay1;
        address foundation;
    }

    function _deployEnv() internal returns (Env memory env) {
        CallForwarder foundationCf = new CallForwarder(address(0));
        env.foundation = address(foundationCf);
        env.diode = new DiodeToken(env.foundation, env.foundation, true);
        foundationCf.__updateTarget(address(env.diode));
        env.foundationToken = DiodeToken(env.foundation);
        env.reg = new DiodeRegistryLight(env.foundation, env.diode);
        env.fleet1 = new FleetContract(address(this), address(this));
        env.fleet2 = new FleetContract(address(this), address(this));
        env.relay1 = new CallForwarder(address(0));

        vm.pauseGasMetering();
        env.foundationToken.mint(address(this), STAKE_AMOUNT * 2);
        env.diode.approve(address(env.reg), STAKE_AMOUNT * 2);
        env.reg.ContractStake(env.fleet1, STAKE_AMOUNT);
        vm.resumeGasMetering();
    }

    function _ticketEpoch() internal view returns (uint256) {
        return block.timestamp / 2_592_000;
    }

    function _warpToNextEpoch(DiodeRegistryLight reg) internal {
        vm.warp(block.timestamp + reg.SecondsPerEpoch() + 1);
    }

    function _signTicket(
        uint256 ticketEpoch,
        FleetContract fleet,
        address relay,
        uint256 clientPk,
        bytes32 localAddress
    ) internal view returns (bytes32[3] memory sig) {
        bytes32[] memory ticket = new bytes32[](7);
        ticket[0] = bytes32(block.chainid);
        ticket[1] = bytes32(ticketEpoch);
        ticket[2] = Utils.addressToBytes32(address(fleet));
        ticket[3] = Utils.addressToBytes32(relay);
        ticket[4] = bytes32(CONNECTIONS);
        ticket[5] = bytes32(BYTES);
        ticket[6] = localAddress;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(clientPk, Utils.bytes32Hash(ticket));
        sig = [r, s, bytes32(uint256(v))];
    }

    function _submitTicket(
        Env memory env,
        uint256 ticketEpoch,
        address relay,
        uint256 clientPk,
        bytes32 localAddress
    ) internal {
        bytes32[3] memory sig = _signTicket(ticketEpoch, env.fleet1, relay, clientPk, localAddress);
        env.reg.SubmitTicket(ticketEpoch, env.fleet1, relay, CONNECTIONS, BYTES, localAddress, sig);
    }

    function _relayAddress(uint256 index) internal returns (address) {
        return makeAddr(string(abi.encodePacked("relay", index)));
    }

    /// Warp once, then submit `count` tickets for the previous epoch (matches DiodeRegistryLight_test).
    /// @param relayCount 1 = all tickets on relay1; count = one client per distinct relay
    function _accumulateTickets(Env memory env, uint256 count, uint256 relayCount) internal {
        uint256 ticketEpoch = _ticketEpoch();
        _warpToNextEpoch(env.reg);
        _submitDistinctTickets(env, ticketEpoch, count, relayCount);
    }

    function _submitDistinctTickets(Env memory env, uint256 ticketEpoch, uint256 count, uint256 relayCount)
        internal
    {
        vm.pauseGasMetering();
        vm.roll(block.number + 2);

        for (uint256 i = 0; i < count; i++) {
            (address client, uint256 clientPk) = makeAddrAndKey(string(abi.encodePacked("client", i)));
            env.fleet1.SetDeviceAllowlist(client, true);

            address relay;
            if (relayCount == 1) {
                relay = address(env.relay1);
            } else {
                relay = _relayAddress(i);
            }

            bytes32 localAddress = keccak256(abi.encodePacked("local", i));
            _submitTicket(env, ticketEpoch, relay, clientPk, localAddress);
        }
        vm.resumeGasMetering();
    }

    function _finalizeEpochAndMeasure(Env memory env, string memory label)
        internal
        returns (uint256 endEpochGas, uint256 endEpochForFleetGas)
    {
        _warpToNextEpoch(env.reg);

        uint256 g0 = gasleft();
        env.reg.EndEpoch();
        endEpochGas = g0 - gasleft();

        g0 = gasleft();
        env.reg.EndEpochForFleet(env.fleet1);
        endEpochForFleetGas = g0 - gasleft();

        console2.log(label, "EndEpoch", endEpochGas);
        console2.log(label, "EndEpochForFleet", endEpochForFleetGas);

        DiodeRegistryLight.FleetStat memory f = env.reg.GetFleet(env.fleet1);
        assertEq(f.score, 0, "fleet score cleared");
    }

    function _assertFleetScore(Env memory env, uint256 expectedMin) internal view {
        DiodeRegistryLight.FleetStat memory f = env.reg.GetFleet(env.fleet1);
        assertGe(f.score, expectedMin, "tickets recorded");
    }

    // --- Scenario A: 1 relay, N unique clients (inner loop scales) ---

    function testGas_scenarioA_oneRelay_manyClients() public {
        for (uint256 i = 0; i < counts.length; i++) {
            uint256 count = counts[i];
            Env memory env = _deployEnv();
            _accumulateTickets(env, count, 1);
            _assertFleetScore(env, count > 0 ? 1 : 0);

            string memory label = string(abi.encodePacked("scenarioA_count=", vm.toString(count)));
            _finalizeEpochAndMeasure(env, label);
        }
    }

    // --- Scenario B: N relays, 1 client each (outer loop scales) ---

    function testGas_scenarioB_manyRelays_oneClientEach() public {
        for (uint256 i = 0; i < counts.length; i++) {
            uint256 count = counts[i];
            Env memory env = _deployEnv();
            _accumulateTickets(env, count, count);
            _assertFleetScore(env, count > 0 ? 1 : 0);

            string memory label = string(abi.encodePacked("scenarioB_count=", vm.toString(count)));
            (, uint256 fleetGas) = _finalizeEpochAndMeasure(env, label);

            if (count == 100) {
                assertLt(fleetGas, V112_SCENARIO_B_100, "v114 scenarioB below v112");
                assertApproxEqAbs(fleetGas, V114_SCENARIO_B_100, 200_000, "v114 scenarioB benchmark");
            }
        }
    }

    /// Document marginal EndEpochForFleet gas per relay (v113).
    function testGas_scenarioB_marginalPerRelay_v113() public {
        uint256 gas1;
        uint256 gas100;
        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, 1, 1);
            (, gas1) = _finalizeEpochAndMeasure(env, "marginal_1");
        }
        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, 100, 100);
            (, gas100) = _finalizeEpochAndMeasure(env, "marginal_100");
        }
        uint256 marginal = (gas100 - gas1) / 99;
        console2.log("v113_scenarioB_marginal_gas_per_relay", marginal);
        assertLt(marginal, 50_000, "~45k per relay with RelayReward struct");
        assertLt(gas100, V112_SCENARIO_B_100);
    }

    // --- Scenario C: sqrt(N) relays x sqrt(N) clients ---

    function testGas_scenarioC_mixedTopology() public {
        uint256[2] memory mixedCounts = [uint256(25), 100];
        for (uint256 i = 0; i < mixedCounts.length; i++) {
            uint256 count = mixedCounts[i];
            uint256 side = _isqrt(count);
            if (side == 0) side = 1;

            Env memory env = _deployEnv();
            uint256 ticketEpoch = _ticketEpoch();
            _warpToNextEpoch(env.reg);

            vm.pauseGasMetering();
            vm.roll(block.number + 2);

            uint256 submitted;
            for (uint256 r = 0; r < side && submitted < count; r++) {
                address relay = r == 0 ? address(env.relay1) : _relayAddress(r);
                for (uint256 c = 0; c < side && submitted < count; c++) {
                    (address client, uint256 clientPk) =
                        makeAddrAndKey(string(abi.encodePacked("mix", r, c)));
                    env.fleet1.SetDeviceAllowlist(client, true);
                    bytes32 localAddress = keccak256(abi.encodePacked("mix", r, c));
                    _submitTicket(env, ticketEpoch, relay, clientPk, localAddress);
                    submitted++;
                }
            }
            vm.resumeGasMetering();

            string memory label = string(abi.encodePacked("scenarioC_count=", vm.toString(count)));
            _finalizeEpochAndMeasure(env, label);
        }
    }

    function _isqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // --- EndEpoch baseline: flat cost regardless of tickets ---

    function testGas_endEpoch_baselineFlat() public {
        uint256 gasAt1;
        uint256 gasAt100;

        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, 1, 1);
            _warpToNextEpoch(env.reg);
            uint256 g0 = gasleft();
            env.reg.EndEpoch();
            gasAt1 = g0 - gasleft();
        }

        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, 100, 1);
            _warpToNextEpoch(env.reg);
            uint256 g0 = gasleft();
            env.reg.EndEpoch();
            gasAt100 = g0 - gasleft();
        }

        console2.log("EndEpoch_gas_count=1", gasAt1);
        console2.log("EndEpoch_gas_count=100", gasAt100);
        assertApproxEqAbs(gasAt1, gasAt100, 500, "EndEpoch should be ~flat");
    }

    // --- Production path: first SubmitTicket on epoch boundary ---

    function testGas_epochBoundarySubmitTicket() public {
        uint256[2] memory sampleCounts = [uint256(10), 100];

        for (uint256 i = 0; i < sampleCounts.length; i++) {
            uint256 count = sampleCounts[i];
            Env memory env = _deployEnv();
            _accumulateTickets(env, count, 1);
            uint256 closingEpoch = _ticketEpoch();
            _warpToNextEpoch(env.reg);

            (address client, uint256 clientPk) = makeAddrAndKey("boundaryClient");
            env.fleet1.SetDeviceAllowlist(client, true);
            bytes32[3] memory sig =
                _signTicket(closingEpoch, env.fleet1, address(env.relay1), clientPk, "boundary");

            uint256 g0 = gasleft();
            env.reg.SubmitTicket(
                closingEpoch, env.fleet1, address(env.relay1), CONNECTIONS, BYTES, "boundary", sig
            );
            uint256 boundaryGas = g0 - gasleft();

            console2.log(
                string(abi.encodePacked("epochBoundarySubmit_count=", vm.toString(count))),
                boundaryGas
            );

            DiodeRegistryLight.FleetStat memory f = env.reg.GetFleet(env.fleet1);
            assertEq(f.score, CONNECTIONS * 1024 + BYTES, "new epoch ticket applied");
        }
    }

    // --- EndEpochForAllFleets: 1 vs 2 registered fleets ---

    function testGas_endEpochForAllFleets_fleetCount() public {
        uint256 count = 25;

        uint256 gasOneFleet;
        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, count, 1);
            _warpToNextEpoch(env.reg);
            uint256 g0 = gasleft();
            env.reg.EndEpochForAllFleets();
            gasOneFleet = g0 - gasleft();
        }

        uint256 gasTwoFleets;
        {
            Env memory env = _deployEnv();
            env.reg.ContractStake(env.fleet2, STAKE_AMOUNT);
            _accumulateTickets(env, count, 1);
            _warpToNextEpoch(env.reg);
            uint256 g0 = gasleft();
            env.reg.EndEpochForAllFleets();
            gasTwoFleets = g0 - gasleft();
        }

        console2.log("EndEpochForAllFleets_1fleet", gasOneFleet);
        console2.log("EndEpochForAllFleets_2fleets", gasTwoFleets);
        assertGt(gasTwoFleets, gasOneFleet, "second fleet adds cost");
    }

    // --- Scenario A: EndEpochForFleet flat in client count (single relay / one node) ---

    function testGas_endEpochForFleet_flat_scenarioA() public {
        uint256 gasAt1;
        uint256 gasAt100;

        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, 1, 1);
            _warpToNextEpoch(env.reg);
            env.reg.EndEpoch();
            uint256 g0 = gasleft();
            env.reg.EndEpochForFleet(env.fleet1);
            gasAt1 = g0 - gasleft();
        }

        {
            Env memory env = _deployEnv();
            _accumulateTickets(env, 100, 1);
            _warpToNextEpoch(env.reg);
            env.reg.EndEpoch();
            uint256 g0 = gasleft();
            env.reg.EndEpochForFleet(env.fleet1);
            gasAt100 = g0 - gasleft();
        }

        console2.log("scenarioA_EndEpochForFleet_count=1", gasAt1);
        console2.log("scenarioA_EndEpochForFleet_count=100", gasAt100);
        assertApproxEqAbs(gasAt1, gasAt100, 5000, "EndEpochForFleet flat vs client count with one node");
    }
}
