// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenVesting.sol";

/**
 * @title YieldVault
 * @dev A contract vault for diode tokens which holds an amount of
 * available yield reserve and allows users to submit their tokens to lock them
 * in newly created TokenVesting contracts together with a fixed amount of
 * tokens from the yield reserve.
 */
contract YieldVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public immutable token;

    // Tokens are locked by delaying the start time
    // there is no cliff period
    uint256 public immutable lockPeriod;

    // they are vested linearly over the vesting period
    uint256 public vestingPeriod;

    // Yield rate as percentage (e.g., 500 = 5%)
    uint256 public yieldRate;

    constructor(address _token, uint256 _lockPeriod, uint256 _vestingPeriod, uint256 _yieldRate) {
        token = IERC20(_token);
        lockPeriod = _lockPeriod;
        vestingPeriod = _vestingPeriod;
        yieldRate = _yieldRate;
    }

    function setYieldRate(uint256 _yieldRate) external onlyOwner {
        yieldRate = _yieldRate;
    }

    function setVestingPeriod(uint256 _vestingPeriod) external onlyOwner {
        vestingPeriod = _vestingPeriod;
    }

    function yieldReserve() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Allows owner to deposit additional tokens into the yield reserve
     * @param amount Amount of tokens to add to reserve
     */
    function deployReserve(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Allows owner to withdraw tokens from the yield reserve
     * @param amount Amount of tokens to withdraw from reserve
     */
    function withdrawReserve(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= yieldReserve(), "Insufficient reserve balance");
        token.safeTransfer(msg.sender, amount);
    }

    // Mapping from user address to their vesting contracts
    mapping(address => address[]) private userVestingContracts;

    // Global list of all vesting contracts
    address[] private allVestingContracts;

    // Event emitted when a new vesting contract is created
    event VestingContractCreated(address indexed user, address vestingContract, uint256 amount, uint256 yieldAmount);

    /**
     * @dev Creates a new token vesting contract for the caller
     * @param amount Amount of tokens the user wants to vest
     * @return The address of the newly created vesting contract
     */
    function createVestingContract(uint256 amount) external returns (address) {
        (address vestingContract, string memory message) = createVestingContractFor(msg.sender, amount);
        if (vestingContract == address(0)) {
            revert(message);
        }
        return vestingContract;
    }

    /**
     * @dev Creates a new token vesting contract for the caller
     * @param amount Amount of tokens the user wants to vest
     * @return The address of the newly created vesting contract
     */
    function createVestingContractFor(address beneficiary, uint256 amount) public returns (address, string memory) {
        if (beneficiary == address(0)) {
            return (address(0), "Beneficiary is zero address");
        }

        if (amount == 0) {
            return (address(0), "Amount must be greater than 0");
        }

        // Calculate yield amount based on yield rate BEFORE transferring the user funds in
        uint256 yieldAmount = amount.mul(yieldRate).div(10000);
        if (yieldAmount > yieldReserve()) {
            return (address(0), "Insufficient yield reserve");
        }

        // Transfer tokens from user to this contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 startTime = block.timestamp + lockPeriod;

        // Create new vesting contract (always non-revocable)
        TokenVesting vestingContract = new TokenVesting(
            beneficiary,
            startTime,
            0,
            vestingPeriod,
            false // Always non-revocable
        );

        // Transfer total tokens (user amount + yield) to vesting contract
        uint256 totalAmount = amount.add(yieldAmount);
        token.safeTransfer(address(vestingContract), totalAmount);

        // Store vesting contract in user's list
        userVestingContracts[beneficiary].push(address(vestingContract));

        // Store vesting contract in global list
        allVestingContracts.push(address(vestingContract));

        emit VestingContractCreated(beneficiary, address(vestingContract), amount, yieldAmount);
        return (address(vestingContract), "");
    }

    /**
     * @dev Returns all vesting contracts for a specific user
     * @param user Address of the user
     * @return Array of vesting contract addresses
     */
    function getUserVestingContracts(address user) external view returns (address[] memory) {
        return userVestingContracts[user];
    }

    /**
     * @dev Returns all vesting contracts created through this vault
     * @return Array of all vesting contract addresses
     */
    function getAllVestingContracts() external view returns (address[] memory) {
        return allVestingContracts;
    }

    /**
     * @dev Returns the number of vesting contracts for a specific user
     * @param user Address of the user
     * @return Number of vesting contracts
     */
    function getUserVestingContractsCount(address user) external view returns (uint256) {
        return userVestingContracts[user].length;
    }

    /**
     * @dev Returns the total number of vesting contracts
     * @return Total number of vesting contracts
     */
    function getAllVestingContractsCount() external view returns (uint256) {
        return allVestingContracts.length;
    }
}
