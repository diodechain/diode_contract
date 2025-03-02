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

    // Tokens are locked for cliff period and then after the cliff period
    // they are vested linearly over the vesting period
    uint256 public immutable cliffPeriod;
    uint256 public immutable vestingPeriod;
    
    // Yield rate as percentage (e.g., 500 = 5%)
    uint256 public immutable yieldRate;

    constructor(address _token, uint256 _cliffPeriod, uint256 _vestingPeriod, uint256 _yieldReserve, uint256 _yieldRate) {
        token = IERC20(_token);
        cliffPeriod = _cliffPeriod;
        vestingPeriod = _vestingPeriod;
        yieldReserve = _yieldReserve;
        yieldRate = _yieldRate;
    }

    // Amount of tokens available for yield distribution
    uint256 public yieldReserve;

    /**
     * @dev Allows owner to deposit additional tokens into the yield reserve
     * @param amount Amount of tokens to add to reserve
     */
    function deployReserve(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        token.safeTransferFrom(msg.sender, address(this), amount);
        yieldReserve = yieldReserve.add(amount);
    }

    /**
     * @dev Allows owner to withdraw tokens from the yield reserve
     * @param amount Amount of tokens to withdraw from reserve
     */
    function withdrawReserve(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= yieldReserve, "Insufficient reserve balance");
        yieldReserve = yieldReserve.sub(amount);
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Returns the current token balance of this contract
     * @return Current balance of tokens held by this contract
     */
    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
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
     * @param startTime The time (as Unix time) at which point vesting starts
     * @return The address of the newly created vesting contract
     */
    function createVestingContract(uint256 amount, uint256 startTime) external returns (address) {
        require(amount > 0, "Amount must be greater than 0");
        
        // Calculate yield amount based on yield rate
        uint256 yieldAmount = amount.mul(yieldRate).div(10000);
        require(yieldAmount <= yieldReserve, "Insufficient yield reserve");
        
        // Transfer tokens from user to this contract
        token.safeTransferFrom(msg.sender, address(this), amount);
        
        // Create new vesting contract (always non-revocable)
        TokenVesting vestingContract = new TokenVesting(
            msg.sender,
            startTime,
            cliffPeriod,
            vestingPeriod,
            false // Always non-revocable
        );
        
        // Update yield reserve
        yieldReserve = yieldReserve.sub(yieldAmount);
        
        // Transfer total tokens (user amount + yield) to vesting contract
        uint256 totalAmount = amount.add(yieldAmount);
        token.safeTransfer(address(vestingContract), totalAmount);
        
        // Store vesting contract in user's list
        userVestingContracts[msg.sender].push(address(vestingContract));
        
        // Store vesting contract in global list
        allVestingContracts.push(address(vestingContract));
        
        emit VestingContractCreated(msg.sender, address(vestingContract), amount, yieldAmount);
        
        return address(vestingContract);
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