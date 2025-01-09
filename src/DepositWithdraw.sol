// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Import the ERC20 interface from OpenZeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title DepositWithdraw Contract
/// @notice A contract that allows users to deposit ETH or any ERC20 token and withdraw them after a lock period with rewards.
contract DepositWithdraw {

    IERC20 public usdc;
    /// @notice Struct to store deposit details
    /// @param amount The amount deposited
    /// @param blockNumber The block number when the deposit was made
    /// @param isETH Flag to indicate if the deposit is in ETH
    /// @param tokenAddress Address of the ERC20 token (if not ETH)
    struct Deposit {
        uint256 amount;
        uint256 blockNumber;
        bool isETH;
        address tokenAddress;
    }

    /// @notice Mapping to store deposits for each user
    mapping(address => Deposit) public deposits;

    /// @notice Prices for ETH and tokens (scaled by 1e6 for precision)
    uint256 public ethPrice = 2000 * 1e6;  // Initial ETH price: $2000
    mapping(address => uint256) public tokenPrices;  // Mapping to store token prices

    uint256 public reward;

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
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
            isETH: true,
            tokenAddress: address(0)  // ETH has no token address
        });
    }

    /// @notice Function to deposit any ERC20 token
    /// @dev Requires the deposit amount to be greater than 0 and no existing deposit for the user
    /// @param tokenAddress Address of the ERC20 token to deposit
    /// @param amount The amount of the token to deposit
    function depositToken(address tokenAddress, uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        // Initialize token price if not already set
        if (tokenPrices[tokenAddress] == 0) {
            tokenPrices[tokenAddress] = 1 * 1e6;  // Default price: $1
        }

        tokenPrices[tokenAddress] = tokenPrices[tokenAddress] * 999 / 1000;  // Decrease token price by 0.1%

        // Transfer tokens from the user to the contract
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        // Store the deposit details in the mapping
        deposits[msg.sender] = Deposit({
            amount: amount,
            blockNumber: block.number,
            isETH: false,
            tokenAddress: tokenAddress
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
        if (deposit.isETH) {
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

            // Transfer USDC reward to the user
            IERC20(usdc).transfer(msg.sender, reward);  

            delete deposits[msg.sender];
        } 
        // Handle ERC20 token withdrawal
        else {
            uint256 tokenPrice = tokenPrices[deposit.tokenAddress];  // Get the token price
            totalAmount = (totalAmount * tokenPrice) / 1e6;  // Adjust the withdrawal amount based on token price

            IERC20(deposit.tokenAddress).transfer(msg.sender, totalAmount);  // Transfer the token to the user
            IERC20(usdc).transfer(msg.sender, reward);  // Transfer USDC reward to the user

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