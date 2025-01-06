// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import the ERC20 interface from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DepositWithdraw Contract
/// @notice A contract that allows users to deposit ETH or USDT and withdraw them after a lock period with rewards.
contract DepositWithdraw {
    // State variables for USDT and USDC token contracts
    IERC20 public usdt;
    IERC20 public usdc;

    /// @notice Struct to store deposit details
    /// @param amount The amount deposited
    /// @param blockNumber The block number when the deposit was made
    /// @param isETH Flag to indicate if the deposit is in ETH
    struct Deposit {
        uint256 amount;
        uint256 blockNumber;
        bool isETH;
    }

    /// @notice Mapping to store deposits for each user
    mapping(address => Deposit) public deposits;

    /// @notice Prices for ETH and USDT (scaled by 1e6 for precision)
    uint256 public ethPrice = 2000 * 1e6;  // Initial ETH price: $2000
    uint256 public usdtPrice = 1 * 1e6;    // Initial USDT price: $1
    uint256 public reward;

    /// @notice Constructor to initialize the contract with USDT and USDC token addresses
    /// @param _usdt Address of the USDT token contract
    /// @param _usdc Address of the USDC token contract
    constructor(address _usdt, address _usdc) {
        usdt = IERC20(_usdt);  // Initialize USDT token contract
        usdc = IERC20(_usdc);  // Initialize USDC token contract
    }

    /// @notice Function to deposit ETH
    /// @dev Requires the deposit amount to be greater than 0 and no existing deposit for the user
    function depositETH() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        ethPrice = ethPrice * 1001 / 1000;  // Increase ETH price by 0.1%

        // Store the deposit details in the mapping
        deposits[msg.sender] = Deposit({
            amount: msg.value,
            blockNumber: block.number,
            isETH: true
        });
    }

    /// @notice Function to deposit USDT
    /// @dev Requires the deposit amount to be greater than 0 and no existing deposit for the user
    /// @param amount The amount of USDT to deposit
    function depositUSDT(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        usdtPrice = usdtPrice * 999 / 1000;  // Decrease USDT price by 0.1%

        // Transfer USDT from the user to the contract
        usdt.transferFrom(msg.sender, address(this), amount);

        // Store the deposit details in the mapping
        deposits[msg.sender] = Deposit({
            amount: amount,
            blockNumber: block.number,
            isETH: false
        });
    }

    /// @notice Function to withdraw the deposit
    /// @dev Requires the deposit to be unlocked (at least 5 blocks passed) and a valid deposit to exist
    function withdraw() public {
        Deposit memory deposit = deposits[msg.sender];  // Retrieve the user's deposit

        uint256 blocksPassed = block.number - deposit.blockNumber;  // Calculate blocks passed since deposit
        require(blocksPassed >= 5, "Deposit is still locked");  // Ensure deposit is unlocked (at least 5 blocks)

        require(deposit.amount > 0, "No deposit found");  // Ensure there is a deposit to withdraw

        reward = calculateReward(deposit.amount, blocksPassed);  // Calculate the reward
        uint256 totalAmount = deposit.amount;  // Initialize total amount to withdraw

        // Handle ETH withdrawal
        if (deposit.isETH == true && deposit.amount != 0) {
            address payable to = payable(msg.sender);

            ethPrice = ethPrice * 999 / 1000;  // Decrease ETH price by 0.1%
            uint128 price = uint128(ethPrice);  // Cast ethPrice to uint128

            // Calculate the maximum amount of ETH that can be sent
            uint256 maxAmount = address(this).balance;

            // Ensure that totalAmount doesn't exceed maxAmount
            totalAmount = totalAmount * price / 1e6;
            if (totalAmount > maxAmount) {
                totalAmount = maxAmount;
            }

            // Use call instead of transfer
            (bool success, ) = to.call{value: totalAmount}("");
            require(success, "Failed to send ETH");

            usdc.transfer(msg.sender, reward);  // Transfer USDC reward to the user

            delete deposits[msg.sender];
        }
        // Handle USDT withdrawal
        else if (deposit.isETH == false && deposit.amount != 0) {
            usdtPrice = usdtPrice * 1001 / 1000;  // Increase USDT price by 0.1%
            totalAmount = (totalAmount * usdtPrice) / 1e6;  // Adjust the withdrawal amount based on USDT price

            usdt.transfer(msg.sender, totalAmount);  // Transfer USDT to the user
            usdc.transfer(msg.sender, reward);  // Transfer USDC reward to the user

            delete deposits[msg.sender];
        } 
    }

    /// @notice Internal function to calculate the reward based on the amount and blocks passed
    /// @param amount The amount deposited
    /// @param blocksPassed The number of blocks passed since the deposit
    /// @return The calculated reward
    function calculateReward(uint256 amount, uint256 blocksPassed) internal pure returns (uint256) {
        uint256 rewardBlocks = blocksPassed - 5;  // Calculate the number of blocks eligible for reward
        return (amount * rewardBlocks * 1) / 1000;  // Calculate reward (0.1% per block)
    }
}