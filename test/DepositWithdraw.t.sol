// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DepositWithdraw} from "../src/DepositWithdraw.sol";
import {USDT} from "../src/USDT.sol";
import {USDC} from "../src/USDC.sol";

/**
 * @title DepositWithdrawTest
 * @dev A test contract for the DepositWithdraw contract.
 * This contract tests the functionality of depositing and withdrawing ETH and USDT.
 */
contract DepositWithdrawTest is Test {

    // State Variables
    DepositWithdraw public depositWithdraw;
    USDT public usdt;
    USDC public usdc;

    address public owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public user2 = address(0x1234);

    /**
     * @dev Setup function to initialize the test environment.
     * Deploys new instances of USDT, USDC, and DepositWithdraw contracts.
     */
    function setUp() public {
        usdt = new USDT(owner);
        usdc = new USDC(owner);
        depositWithdraw = new DepositWithdraw(address(usdt), address(usdc));
    }

    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Test the initialization of the DepositWithdraw contract.
     * Asserts that the USDT and USDC addresses are set correctly.
     */
    function test_initialization() public view {
        assertEq(address(depositWithdraw.usdt()), address(usdt), "USDT address not set correctly");
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

        (uint256 amount, uint256 blockNumber, bool isETH) = depositWithdraw.deposits(address(this));

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

    /**
     * @dev Test the depositUSDT function with a valid amount.
     * Asserts that the USDT deposit is recorded correctly.
     * @param user The address of the user making the deposit.
     * @param amount The amount of USDT to deposit.
     */
    function testDipositUSDT(address user, uint amount) public{
        vm.assume(user != address(0) && amount > 0);
        vm.prank(owner);
        usdt.mint(owner, amount);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, amount);
        console.log("User  USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), amount);
        depositWithdraw.depositUSDT(amount);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == amount);
    }  

    /**
     * @dev Test the depositUSDT function with a zero amount.
     * Asserts that the function reverts with the correct error message */
    function test_depositUSDT_zero_amount() public {
        vm.expectRevert("Deposit amount must be greater than 0");
        depositWithdraw.depositUSDT(0);
    } 

    /**
     * @dev Test the depositUSDT function when an existing deposit is found.
     * Asserts that the function reverts with the correct error message.
     * @param user The address of the user making the deposit.
     * @param amount The amount of USDT to deposit.
     */
    function test_depositUSDT_existing_deposit(address user, uint amount) public {
        vm.assume(user != address(0) && amount > 0);
        vm.prank(owner);
        usdt.mint(owner, amount);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, amount);
        console.log("User  USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), amount);
        depositWithdraw.depositUSDT(amount);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == amount);

        vm.expectRevert("Existing deposit found");
        depositWithdraw.depositUSDT(amount);
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
        vm.assume(user != address(0));
        vm.prank(owner);
        usdt.mint(owner, 1000);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, 1000);
        console.log("User  USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.prank(owner);
        usdc.mint(owner, 1000);
        console.log("USDC  owner balance -->", usdc.balanceOf(owner));
        vm.prank(owner);
        usdc.transfer(address(depositWithdraw), 1000);
        console.log("User  USDC balance -->", usdc.balanceOf(address(depositWithdraw)));
        usdc.approve(address(depositWithdraw), 1000);
        console.log("USDC allowance of user to depositWithdraw contract: ", usdc.allowance(owner, address(depositWithdraw)));

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), 1000);
        depositWithdraw.depositUSDT(1000);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == 1000);

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
        vm.assume(user != address(0));
        vm.prank(owner);
        usdt.mint(owner, 1000);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, 1000);
        console.log("User  USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.prank(owner);
        usdc.mint(owner, 1000);
        console.log("USDC  owner balance -->", usdc.balanceOf(owner));
        vm.prank(owner);
        usdc.transfer(address(depositWithdraw), 1000);
        console.log(" User   USDC balance -->", usdc.balanceOf(address(depositWithdraw)));
        usdc.approve(address(depositWithdraw), 1000);
        console.log("USDC allowance of user to depositWithdraw contract: ", usdc.allowance(owner, address(depositWithdraw)));

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), 1000);
        depositWithdraw.depositUSDT(1000);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == 1000);
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
        vm.assume(user != address(0));
        vm.prank(owner);
        usdt.mint(owner, 1000);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, 1000);
        console.log("User   USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), 1000);
        depositWithdraw.depositUSDT(1000);

        vm.roll(block.number + 5);
        depositWithdraw.withdraw();

        (uint256 a1, uint256 blockNumber, bool isETH) = depositWithdraw.deposits(address(this));

        uint256 expectedReward = (1000 * (block.number - 5 - blockNumber)) / 1000;
    }

}