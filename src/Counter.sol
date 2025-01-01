// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepositWithdraw  {
    IERC20 public usdt;
    IERC20 public usdc;

    struct Deposit {
        uint256 amount;
        uint256 blockNumber;
        bool isETH;
    }

    mapping(address => Deposit) public deposits;

    constructor(address _usdt, address _usdc) {
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);
    }

    function depositETH() public  payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");
        
        deposits[msg.sender] = Deposit({
            amount: msg.value,
            blockNumber: block.number,
            isETH: true
        });
    }

    function depositUSDT(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(deposits[msg.sender].amount == 0, "Existing deposit found");

        usdt.transferFrom(msg.sender, address(this), amount);

        deposits[msg.sender] = Deposit({
            amount: amount,
            blockNumber: block.number,
            isETH: false
        });
    }   

    function withdrawETH() public {
        uint256 blocksPassed = block.number - deposits[msg.sender].blockNumber;
        require(blocksPassed >= 5, "Deposit is still locked");

        require(deposits[msg.sender].amount > 0, "No deposit found");
        require(deposits[msg.sender].isETH == true , "No ETH deposit found");

        address payable to = payable(msg.sender);
        uint256 value = deposits[msg.sender].amount;

        to.transfer(value);

        deposits[msg.sender].amount = 0;
        deposits[msg.sender].isETH == false;
    }

    function withdrawUSDT() external {
        Deposit memory deposit = deposits[msg.sender];
        require(deposit.amount > 0, "No deposit found");

        uint256 blocksPassed = block.number - deposit.blockNumber;
        require(blocksPassed >= 5, "Deposit is still locked");

        uint256 totalAmount = deposit.amount;

        usdc.transfer(msg.sender, totalAmount);

    }

}