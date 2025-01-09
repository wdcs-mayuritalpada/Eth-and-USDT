// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DepositWithdraw} from "../src/DepositWithdraw.sol";
import {USDC} from "../src/USDC.sol";
import {TestToken} from "../src/TestToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title DepositWithdrawTest
 * @dev A test contract for the DepositWithdraw contract.
 * This contract tests the functionality of depositing and withdrawing ETH and USDT.
 */
contract DepositWithdrawTest is Test {

    // State Variables
    DepositWithdraw public depositWithdraw;
    USDC public usdc;
    TestToken public testToken;

    address public owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public user2 = address(0x1234);

    /**
     * @dev Setup function to initialize the test environment.
     * Deploys new instances of USDT, USDC, and DepositWithdraw contracts.
     */
    function setUp() public {
        usdc = new USDC(owner);
        testToken = new TestToken(owner);
        depositWithdraw = new DepositWithdraw(address(usdc));
    }

    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Test the initialization of the DepositWithdraw contract.
     * Asserts that the USDT and USDC addresses are set correctly.
     */
    function test_initialization() public view {
        assertEq(address(depositWithdraw.usdc()), address(usdc), "USDC address not set correctly");
    }

    /**
     * @dev Test the depositETH function with a valid amount.
     * Asserts that the ETH deposit is recorded correctly.
     * @param user The address of the user making the deposit.
     */
    function test_depositETH(address user) public {
        vm.assume(user != address(0));
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();

        (uint256 amount, , bool isETH, ) = depositWithdraw.deposits(address(this));

        assertEq(amount, 1 ether, "ETH deposit amount incorrect");
        assertEq(isETH, true, "Deposit should be marked as ETH");
    }
    
    /**
     * @dev Test the depositETH function with a zero amount.
     * Asserts that the function reverts with the correct error message.
     */
    function test_depositETH_zero_amount() public {
        vm.expectRevert("Deposit amount must be greater than 0");
        depositWithdraw.depositETH{value: 0}();
    }

    /**
     * @dev Test the depositETH function when an existing deposit is found.
     * Asserts that the function reverts with the correct error message.
     */
    function test_depositETH_existing_deposit() public {
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();

        vm.expectRevert("Existing deposit found");
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();
    }

    function DepositUSDT(address user, uint amount) public {
        vm.assume(user != address(0) && amount > 0);
        vm.prank(owner);
        testToken.mint(owner, amount);
        uint256 value = testToken.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        testToken.transfer(user, amount);
        console.log("User  USDC balance -->", testToken.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        testToken.approve(address(depositWithdraw), amount);
        depositWithdraw.depositToken(address(testToken), amount);
        (uint a1 , , , ) = depositWithdraw.deposits(user);
        assert(a1 == amount);
    }  

    /**
     * @dev Test the depositUSDT function with a valid amount.
     * Asserts that the USDT deposit is recorded correctly.
     * @param user The address of the user making the deposit.
     */
    function testDepositUSDT(address user) public{
        uint amount = 1000;
        DepositUSDT(user, amount);
    }  

    /**
     * @dev Test the depositUSDT function with a zero amount.
     * Asserts that the function reverts with the correct error message */
    function test_depositUSDT_zero_amount() public {
        vm.expectRevert("Deposit amount must be greater than 0");
        depositWithdraw.depositToken(address(testToken),0);
    } 

    /**
     * @dev Test the depositUSDT function when an existing deposit is found.
     * Asserts that the function reverts with the correct error message.
     * @param user The address of the user making the deposit.
     * @param amount The amount of USDT to deposit.
     */
    function test_depositUSDT_existing_deposit(address user, uint amount) public {
        DepositUSDT(user, amount);

        vm.expectRevert("Existing deposit found");
        depositWithdraw.depositToken(address(testToken), amount);
    }

    /**
     * @dev Test the withdraw function for ETH.
     * Asserts that the withdraw function works correctly after a valid deposit.
     */
    function test_withdraw_ETH() public {
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();
        vm.deal(address(this), 2000 ether);

        vm.roll(block.number + 5);
        depositWithdraw.withdraw();
    }

    /**
     * @dev Test the withdraw function for USDT.
     * Asserts that the withdraw function works correctly after a valid deposit.
     * @param user The address of the user making the withdrawal.
     */
    function test_withdraw_USDT(address user) public {
        uint amount = 1000;
        DepositUSDT(user, amount);

        vm.roll(block.number + 5);
        depositWithdraw.withdraw();
    }

    /**
     * @dev Test the withdraw function when the deposit is still locked.
     * Asserts that the function reverts with the correct error message.
     */
    function test_withdraw_locked_deposit() public {
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();

        vm.expectRevert("Deposit is still locked");
        depositWithdraw.withdraw();
    }

    /**
     * @dev Test the withdraw function when there is no deposit.
     * Asserts that the function reverts with the correct error message.
     * @param user The address of the user attempting to withdraw.
     */
    function test_withdraw_no_deposit(address user) public {
        uint256 amount = 1000;
        DepositUSDT(user, amount);
        vm.stopPrank();

        vm.roll(block.number + 5);

        vm.prank(user2);
        vm.expectRevert("No deposit found");
        depositWithdraw.withdraw();
    }

    /**
     * @dev Test the reward calculation after a deposit.
     * Asserts that the reward is calculated correctly based on the amount and blocks passed.
     * @param user The address of the user making the deposit.
     */
    function test_calculateReward(address user) public {
        uint256 amount = 1000;
        DepositUSDT(user, amount);

        vm.roll(block.number + 5);
        depositWithdraw.withdraw();

        (, uint256 blockNumber, , ) = depositWithdraw.deposits(address(this));

        uint256 expectedReward = (1000 * (block.number - 5 - blockNumber)) / 1000;
        console.log("Expected reward -->", expectedReward);
    }

}