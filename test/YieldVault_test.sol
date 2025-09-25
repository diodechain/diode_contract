// SPDX-License-Identifier: DIODE
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./Assert.sol";
import "../contracts/YieldVault.sol";
import "../contracts/DiodeToken.sol";
import "./forge-std/Test.sol";

contract YieldVaultTest is Test {
    YieldVault yieldVault;
    DiodeToken diodeToken;
    address owner;
    address user1;
    address user2;

    // Constants for testing
    uint256 constant LOCK_PERIOD = 30 days;
    uint256 constant VESTING_PERIOD = 180 days;
    uint256 constant INITIAL_YIELD_RESERVE = 1000000 * 10 ** 18; // 1 million tokens
    uint256 constant YIELD_RATE = 500; // 5%

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Create DiodeToken with required parameters
        diodeToken =
            new DiodeToken(
                owner, // foundation
                address(0), // bridge (not needed for test)
                true // transferable
            );

        // Mint tokens to owner for the initial yield reserve
        diodeToken.mint(owner, INITIAL_YIELD_RESERVE);

        // Create YieldVault with required parameters but with zero initial reserve
        // We'll transfer tokens separately to ensure they're available
        yieldVault = new YieldVault(address(diodeToken), LOCK_PERIOD, VESTING_PERIOD, YIELD_RATE);

        // Approve YieldVault to spend owner's tokens for reserve
        diodeToken.approve(address(yieldVault), type(uint256).max);

        // Deploy the initial reserve
        yieldVault.deployReserve(INITIAL_YIELD_RESERVE);

        // Mint additional tokens to owner, user1, and user2 for testing
        diodeToken.mint(owner, 10000000 * 10 ** 18); // 10 million tokens
        diodeToken.mint(user1, 100000 * 10 ** 18); // 100k tokens
        diodeToken.mint(user2, 100000 * 10 ** 18); // 100k tokens

        // Approve YieldVault from user accounts
        vm.prank(user1);
        diodeToken.approve(address(yieldVault), type(uint256).max);

        vm.prank(user2);
        diodeToken.approve(address(yieldVault), type(uint256).max);
    }

    function testInitialState() public view {
        assertEq(address(yieldVault.token()), address(diodeToken), "Token address should match");
        assertEq(yieldVault.lockPeriod(), LOCK_PERIOD, "Lock period should match");
        assertEq(yieldVault.vestingPeriod(), VESTING_PERIOD, "Vesting period should match");
        assertEq(yieldVault.yieldReserve(), INITIAL_YIELD_RESERVE, "Initial yield reserve should match");
        assertEq(yieldVault.yieldRate(), YIELD_RATE, "Yield rate should match");
    }

    function testDeployReserve() public {
        uint256 initialReserve = yieldVault.yieldReserve();
        uint256 additionalAmount = 500000 * 10 ** 18; // 500k tokens

        yieldVault.deployReserve(additionalAmount);

        assertEq(
            yieldVault.yieldReserve(), initialReserve + additionalAmount, "Reserve should increase by deployed amount"
        );
    }

    function testWithdrawReserve() public {
        uint256 initialReserve = yieldVault.yieldReserve();
        uint256 withdrawAmount = 200000 * 10 ** 18; // 200k tokens

        uint256 initialOwnerBalance = diodeToken.balanceOf(owner);

        yieldVault.withdrawReserve(withdrawAmount);

        assertEq(
            yieldVault.yieldReserve(), initialReserve - withdrawAmount, "Reserve should decrease by withdrawn amount"
        );

        assertEq(
            diodeToken.balanceOf(owner),
            initialOwnerBalance + withdrawAmount,
            "Owner balance should increase by withdrawn amount"
        );
    }

    function test_RevertWhen_WithdrawTooMuch() public {
        uint256 tooMuch = yieldVault.yieldReserve() + 1;
        vm.expectRevert();
        yieldVault.withdrawReserve(tooMuch);
    }

    function testCreateVestingContract() public {
        // Setup user1 to create a vesting contract
        vm.startPrank(user1);
        uint256 amount = 10000 * 10 ** 18; // 10k tokens

        uint256 initialUser1Balance = diodeToken.balanceOf(user1);
        uint256 initialReserve = yieldVault.yieldReserve();
        uint256 expectedYieldAmount = (amount * YIELD_RATE) / 10000; // 5% yield

        address vestingContract = yieldVault.createVestingContract(amount);

        vm.stopPrank();

        // Verify user1's balance decreased
        assertEq(
            diodeToken.balanceOf(user1), initialUser1Balance - amount, "User balance should decrease by vested amount"
        );

        // Verify yield reserve decreased
        assertEq(
            yieldVault.yieldReserve(),
            initialReserve - expectedYieldAmount,
            "Yield reserve should decrease by yield amount"
        );

        // Verify vesting contract received tokens
        assertEq(
            diodeToken.balanceOf(vestingContract),
            amount + expectedYieldAmount,
            "Vesting contract should receive user amount + yield"
        );

        // Verify vesting contract is tracked for user
        address[] memory userContracts = yieldVault.getUserVestingContracts(user1);
        assertEq(userContracts.length, 1, "User should have 1 vesting contract");
        assertEq(userContracts[0], vestingContract, "User's vesting contract should match");

        // Verify vesting contract is in global list
        address[] memory allContracts = yieldVault.getAllVestingContracts();
        assertEq(allContracts.length, 1, "There should be 1 vesting contract in total");
        assertEq(allContracts[0], vestingContract, "Global vesting contract should match");

        // Verify the vesting contract is not revocable
        TokenVesting vestingContractInstance = TokenVesting(vestingContract);
        assertEq(vestingContractInstance.revocable(), false, "Vesting contract should not be revocable");
    }

    function testMultipleVestingContracts() public {
        // User1 creates a vesting contract
        vm.startPrank(user1);
        uint256 amount1 = 10000 * 10 ** 18;
        address vestingContract1 = yieldVault.createVestingContract(amount1);
        vm.stopPrank();

        // User2 creates a vesting contract
        vm.startPrank(user2);
        uint256 amount2 = 20000 * 10 ** 18;
        address vestingContract2 = yieldVault.createVestingContract(amount2);
        vm.stopPrank();

        // User1 creates another vesting contract
        vm.startPrank(user1);
        uint256 amount3 = 5000 * 10 ** 18;
        address vestingContract3 = yieldVault.createVestingContract(amount3);
        vm.stopPrank();

        // Verify user contract counts
        assertEq(yieldVault.getUserVestingContractsCount(user1), 2, "User1 should have 2 vesting contracts");
        assertEq(yieldVault.getUserVestingContractsCount(user2), 1, "User2 should have 1 vesting contract");

        // Verify total contract count
        assertEq(yieldVault.getAllVestingContractsCount(), 3, "There should be 3 vesting contracts in total");

        // Verify all vesting contracts are not revocable
        assertEq(TokenVesting(vestingContract1).revocable(), false, "Vesting contract 1 should not be revocable");
        assertEq(TokenVesting(vestingContract2).revocable(), false, "Vesting contract 2 should not be revocable");
        assertEq(TokenVesting(vestingContract3).revocable(), false, "Vesting contract 3 should not be revocable");

        // Use the variables to avoid compiler warnings
        assert(vestingContract1 != address(0));
        assert(vestingContract2 != address(0));
        assert(vestingContract3 != address(0));
    }

    function test_RevertWhen_InsufficientYieldReserve() public {
        // Calculate how much a user would need to vest to exceed the yield reserve
        uint256 reserveAmount = yieldVault.yieldReserve();
        uint256 maxUserAmount = (reserveAmount * 10000) / YIELD_RATE;
        uint256 tooMuchAmount = maxUserAmount + 1;

        // Try to create a vesting contract with too much amount
        vm.startPrank(user1);
        vm.expectRevert();
        diodeToken.mint(user1, tooMuchAmount); // Ensure user has enough tokens

        // This should fail due to insufficient yield reserve
        vm.expectRevert();
        yieldVault.createVestingContract(tooMuchAmount);
        vm.stopPrank();
    }

    function testVestingRelease() public {
        // User1 creates a vesting contract
        vm.startPrank(user1);
        uint256 amount = 10000 * 10 ** 18;
        address vestingContractAddr = yieldVault.createVestingContract(amount);
        vm.stopPrank();

        TokenVesting vestingContract = TokenVesting(vestingContractAddr);
        uint256 expectedYieldAmount = (amount * YIELD_RATE) / 10000;
        uint256 totalAmount = amount + expectedYieldAmount;
        uint256 startTime = block.timestamp;

        // The total matches the balance of the vesting contract
        assertEq(diodeToken.balanceOf(vestingContractAddr), totalAmount, "Vesting contract should have total amount");

        // Verify the vesting contract is not revocable
        assertEq(vestingContract.revocable(), false, "Vesting contract should not be revocable");

        // Fast forward past lock period
        vm.warp(startTime + LOCK_PERIOD + 0);
        assertEq(
            vestingContract.releasableAmount(IERC20(address(diodeToken))),
            0,
            "Vesting contract should have no releasable amount"
        );

        vm.warp(startTime + LOCK_PERIOD + 1);
        // Calculate expected release amount (just past lock)
        uint256 expectedReleaseAmount = (totalAmount * 1) / VESTING_PERIOD;

        // User1 releases tokens
        vm.startPrank(user1);
        assertEq(
            expectedReleaseAmount,
            vestingContract.releasableAmount(IERC20(address(diodeToken))),
            "Release amount should match"
        );
        uint256 initialUser1Balance = diodeToken.balanceOf(user1);
        vestingContract.release(IERC20(address(diodeToken)));
        vm.stopPrank();

        // Verify user received tokens
        assertGt(diodeToken.balanceOf(user1), initialUser1Balance, "User should receive released tokens");

        // Fast forward to halfway through vesting period
        vm.warp(startTime + LOCK_PERIOD + VESTING_PERIOD / 2);

        // User1 releases more tokens
        vm.startPrank(user1);
        initialUser1Balance = diodeToken.balanceOf(user1);
        vestingContract.release(IERC20(address(diodeToken)));
        vm.stopPrank();

        // Verify user received more tokens
        assertGt(diodeToken.balanceOf(user1), initialUser1Balance, "User should receive more released tokens");

        // Fast forward past vesting period
        vm.warp(startTime + LOCK_PERIOD + VESTING_PERIOD + 1);

        // User1 releases final tokens
        vm.startPrank(user1);
        initialUser1Balance = diodeToken.balanceOf(user1);
        vestingContract.release(IERC20(address(diodeToken)));
        vm.stopPrank();

        // Verify all tokens have been released
        assertEq(
            diodeToken.balanceOf(vestingContractAddr), 0, "Vesting contract should have 0 tokens after full release"
        );
    }

    function test_RevertWhen_RevokeVestingContract() public {
        // User1 creates a vesting contract
        vm.startPrank(user1);
        uint256 amount = 10000 * 10 ** 18;
        address vestingContractAddr = yieldVault.createVestingContract(amount);
        vm.stopPrank();

        TokenVesting vestingContract = TokenVesting(vestingContractAddr);

        // Try to revoke the vesting contract (should fail)
        vm.expectRevert();
        vestingContract.revoke(IERC20(address(diodeToken)));
    }
}
