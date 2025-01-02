// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import the ERC20 interface from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepositWithdraw {
    // State variables for USDT and USDC token contracts
    IERC20 public usdt;
    IERC20 public usdc;

    // Struct to store deposit details
    struct Deposit {
        uint256 amount;       // Amount deposited
        uint256 blockNumber;  // Block number when the deposit was made
        bool isETH;           // Flag to indicate if the deposit is in ETH
    }

    // Mapping to store deposits for each user
    mapping(address => Deposit) public deposits;

    // Prices for ETH and USDT (scaled by 1e6 for precision)
    uint256 public ethPrice = 2000 * 1e6;  // Initial ETH price: $2000
    uint256 public usdtPrice = 1 * 1e6;    // Initial USDT price: $1

    // Constructor to initialize the contract with USDT and USDC token addresses
    constructor(address _usdt, address _usdc) {
        usdt = IERC20(_usdt);  // Initialize USDT token contract
        usdc = IERC20(_usdc);  // Initialize USDC token contract
    }

    // Function to deposit ETH
    function depositETH() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");  // Ensure deposit amount is positive
        require(deposits[msg.sender].amount == 0, "Existing deposit found");  // Ensure no existing deposit

        ethPrice = ethPrice * 1001 / 1000;  // Increase ETH price by 0.1%

        // Store the deposit details in the mapping
        deposits[msg.sender] = Deposit({
            amount: msg.value,       // Amount of ETH deposited
            blockNumber: block.number,  // Current block number
            isETH: true              // Flag indicating ETH deposit
        });
    }

    // Function to deposit USDT
    function depositUSDT(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");  // Ensure deposit amount is positive
        require(deposits[msg.sender].amount == 0, "Existing deposit found");  // Ensure no existing deposit

        usdtPrice = usdtPrice * 999 / 1000;  // Decrease USDT price by 0.1%

        // Transfer USDT from the user to the contract
        usdt.transferFrom(msg.sender, address(this), amount);

        // Store the deposit details in the mapping
        deposits[msg.sender] = Deposit({
            amount: amount,          // Amount of USDT deposited
            blockNumber: block.number,  // Current block number
            isETH: false             // Flag indicating USDT deposit
        });
    }

    // Function to withdraw the deposit
    function withdraw() public {
        Deposit memory deposit = deposits[msg.sender];  // Retrieve the user's deposit

        uint256 blocksPassed = block.number - deposit.blockNumber;  // Calculate blocks passed since deposit
        require(blocksPassed >= 5, "Deposit is still locked");  // Ensure deposit is unlocked (at least 5 blocks)

        require(deposit.amount > 0, "No deposit found");  // Ensure there is a deposit to withdraw

        uint256 reward = calculateReward(deposit.amount, blocksPassed);  // Calculate the reward
        uint256 totalAmount = deposit.amount;  // Initialize total amount to withdraw

        // Handle ETH withdrawal
        if (deposit.isETH == true && deposit.amount != 0) {
            address payable to = payable(msg.sender);

            ethPrice = ethPrice * 999 / 1000;  // Decrease ETH price by 0.1%
            totalAmount = (totalAmount * ethPrice) / 1e6;  // Adjust the withdrawal amount based on ETH price

            to.transfer(totalAmount);  // Transfer ETH to the user
            usdc.transfer(msg.sender, reward);  // Transfer USDC reward to the user

            deposit.amount = 0;  // Reset the deposit amount
            deposit.isETH = false;  // Reset the ETH flag
        }
        // Handle USDT withdrawal
        else if (deposit.isETH == false && deposit.amount != 0) {
            usdtPrice = usdtPrice * 1001 / 1000;  // Increase USDT price by 0.1%
            totalAmount = (totalAmount * usdtPrice) / 1e6;  // Adjust the withdrawal amount based on USDT price

            usdt.transfer(msg.sender, totalAmount);  // Transfer USDT to the user
            usdc.transfer(msg.sender, reward);  // Transfer USDC reward to the user

            deposit.amount = 0;  // Reset the deposit amount
            deposit.isETH = false;  // Reset the ETH flag
        } 
    }

    // Internal function to calculate the reward based on the amount and blocks passed
    function calculateReward(uint256 amount, uint256 blocksPassed) internal pure returns (uint256) {
        uint256 rewardBlocks = blocksPassed - 5;  // Calculate the number of blocks eligible for reward
        return (amount * rewardBlocks * 1) / 1000;  // Calculate reward (0.1% per block)
    }
}