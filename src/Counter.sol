// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DepositWithdraw is ReentrancyGuard {
    IERC20 public usdt;
    IERC20 public usdc;

    struct Deposit {
        uint256 amount;
        uint256 blockNumber;
        bool isETH;
    }

    mapping(address => Deposit) public deposits;

    uint256 public ethPrice = 2000 * 1e6; // Initial ETH price in USDT (1 ETH = 2000 USDT)
    uint256 public usdtPrice = 1 * 1e6; // USDT price in USDC (1 USDT = 1 USDC)

    event Deposited(address indexed user, uint256 amount, bool isETH);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    constructor(address _usdt, address _usdc) {
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);
    }

    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        deposits[msg.sender] = Deposit({
            amount: msg.value,
            blockNumber: block.number,
            isETH: true
        });

        emit Deposited(msg.sender, msg.value, true);
    }

    function depositUSDT(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        usdt.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] = Deposit({
            amount: amount,
            blockNumber: block.number,
            isETH: false
        });

        emit Deposited(msg.sender, amount, false);
    }

    function withdraw() external nonReentrant {
        Deposit memory deposit = deposits[msg.sender];
        require(deposit.amount > 0, "No deposit found");

        uint256 blocksPassed = block.number - deposit.blockNumber;
        require(blocksPassed >= 5, "Deposit is still locked");

        uint256 reward = calculateReward(deposit.amount, blocksPassed);
        uint256 totalAmount = deposit.amount;

        if (deposit.isETH) {
            // Simulate price variation for ETH
            ethPrice = ethPrice * 1001 / 1000; // Increase ETH price by 0.1%
            totalAmount = (totalAmount * ethPrice) / 1e6; // Convert ETH to USDT equivalent
        } else {
            // Simulate price variation for USDT
            usdtPrice = usdtPrice * 999 / 1000; // Decrease USDT price by 0.1%
            totalAmount = (totalAmount * usdtPrice) / 1e6; // Convert USDT to USDC equivalent
        }

        // Transfer the original amount and reward in USDC
        usdc.transfer(msg.sender, totalAmount + reward);

        delete deposits[msg.sender];

        emit Withdrawn(msg.sender, totalAmount, reward);
    }

    function calculateReward(uint256 amount, uint256 blocksPassed) internal pure returns (uint256) {
        uint256 rewardBlocks = blocksPassed - 5;
        return (amount * rewardBlocks * 1) / 1000; // 0.1% reward per block
    }

    function getETHPrice() external view returns (uint256) {
        return ethPrice;
    }

    function getUSDTPrice() external view returns (uint256) {
        return usdtPrice;
    }
}