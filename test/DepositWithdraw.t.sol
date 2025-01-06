// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DepositWithdraw} from "../src/DepositWithdraw.sol";
import {USDT} from "../src/USDT.sol";
import {USDC} from "../src/USDC.sol";



contract DepositWithdrawTest is Test {

    DepositWithdraw public depositWithdraw;
    USDT public usdt;
    USDC public usdc;

    // address public usdt = address(0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141);
    // address public usdc = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    address public owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public user2 = address(0x1234);

    function setUp() public {
        usdt = new USDT(owner);
        usdc = new USDC(owner);
        depositWithdraw = new DepositWithdraw(address(usdt), address(usdc));
    }

    receive() external payable {}
    fallback() external payable {}

    function test_initialization() public view {
        // Assert that the USDT and USDC addresses are set correctly
        assertEq(address(depositWithdraw.usdt()), address(usdt), "USDT address not set correctly");
        assertEq(address(depositWithdraw.usdc()), address(usdc), "USDC address not set correctly");
    }

    function test_depositETH(address user) public {
        vm.assume(user != address(0));
        // Send 1 ETH to the depositETH function
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();

        // Retrieve the deposit details
        (uint256 amount, uint256 blockNumber, bool isETH) = depositWithdraw.deposits(address(this));

        // Assert that the deposit is recorded correctly
        assertEq(amount, 1 ether, "ETH deposit amount incorrect");
        assertEq(isETH, true, "Deposit should be marked as ETH");
    }
    
    function test_depositETH_zero_amount() public {
        // Attempt to deposit zero ETH
        vm.expectRevert("Deposit amount must be greater than 0");
        depositWithdraw.depositETH{value: 0}();
    }

    function test_depositETH_existing_deposit() public {
        // Make an initial ETH deposit
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();

        // Attempt to make another ETH deposit
        vm.expectRevert("Existing deposit found");
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();
    }

    function testDipositUSDT(address user, uint amount) public{
        vm.assume(user != address(0) && amount > 0);
        vm.prank(owner);
        usdt.mint(owner, amount);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, amount);
        console.log("User USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), amount);
        depositWithdraw.depositUSDT(amount);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == amount);
    }  

    function test_depositUSDT_zero_amount() public {
        // Attempt to deposit zero USDT
        vm.expectRevert("Deposit amount must be greater than 0");
        depositWithdraw.depositUSDT(0);
    } 

    function test_depositUSDT_existing_deposit(address user, uint amount) public {
        // Make an initial USDT deposit
        vm.assume(user != address(0) && amount > 0);
        vm.prank(owner);
        usdt.mint(owner, amount);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, amount);
        console.log("User USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), amount);
        depositWithdraw.depositUSDT(amount);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == amount);

        // Attempt to make another USDT deposit
        vm.expectRevert("Existing deposit found");
        depositWithdraw.depositUSDT(amount);
    }

    function test_withdraw_ETH() public {
        // Make an ETH deposit
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();
        vm.deal(address(this), 2000 ether);

        // Wait for a smaller number of blocks to pass
        vm.roll(block.number + 5);

        // Call the withdraw function
        depositWithdraw.withdraw();
    }

    function test_withdraw_USDT(address user) public {
    
        // Make a USDT deposit
        vm.assume(user != address(0) );
        vm.prank(owner);
        usdt.mint(owner, 1000);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, 1000);
        console.log("User USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.prank(owner);
        usdc.mint(owner, 1000);
        console.log("USDC  owner balance -->", usdc.balanceOf(owner));
        vm.prank(owner);
        usdc.transfer(address(depositWithdraw), 1000 );
        console.log("User USDC balance -->", usdc.balanceOf(address(depositWithdraw)));
        usdc.approve(address(depositWithdraw), 1000);
        console.log("USDC allowance of user to dipositewithDraw contract: ",usdc.allowance(owner, address(depositWithdraw)));

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), 1000);
        depositWithdraw.depositUSDT(1000);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == 1000);

        // Mine at least 5 blocks to unlock the deposit
        vm.roll(block.number + 5);

        // Call the withdraw function
        depositWithdraw.withdraw();
    }

    function test_withdraw_locked_deposit() public {
        // Make an ETH deposit
        vm.deal(address(this), 1 ether);
        depositWithdraw.depositETH{value: 1 ether}();

        // Attempt to withdraw before 5 blocks have passed
        vm.expectRevert("Deposit is still locked");
        depositWithdraw.withdraw();
    }

    function test_withdraw_no_deposit(address user) public {

        // Make a USDT deposit
        vm.assume(user != address(0) );
        vm.prank(owner);
        usdt.mint(owner, 1000);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, 1000);
        console.log("User USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.prank(owner);
        usdc.mint(owner, 1000);
        console.log("USDC  owner balance -->", usdc.balanceOf(owner));
        vm.prank(owner);
        usdc.transfer(address(depositWithdraw), 1000 );
        console.log("User USDC balance -->", usdc.balanceOf(address(depositWithdraw)));
        usdc.approve(address(depositWithdraw), 1000);
        console.log("USDC allowance of user to dipositewithDraw contract: ",usdc.allowance(owner, address(depositWithdraw)));

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), 1000);
        depositWithdraw.depositUSDT(1000);
        (uint a1 , ,) = depositWithdraw.deposits(user);
        assert(a1 == 1000);
        vm.stopPrank();

        // Mine at least 5 blocks to unlock the deposit
        vm.roll(block.number + 5);

        vm.prank(user2);
        // Attempt to withdraw without making a deposit
        vm.expectRevert("No deposit found");
        depositWithdraw.withdraw();
    }

    function test_calculateReward(address user) public {
        // Make a USDT deposit
        vm.assume(user != address(0) );
        vm.prank(owner);
        usdt.mint(owner, 1000);
        uint256 value = usdt.balanceOf(owner);
        console.log("USDC  owner balance -->", value);

        vm.startPrank(owner);
        usdt.transfer(user, 1000);
        console.log("User USDC balance -->", usdt.balanceOf(user));
        vm.stopPrank();

        vm.startPrank(user);
        usdt.approve(address(depositWithdraw), 1000);
        depositWithdraw.depositUSDT(1000);

        // Mine at least 5 blocks to unlock the deposit
        vm.roll(block.number + 5);

        // Call the withdraw function
        depositWithdraw.withdraw();

        // Retrieve the deposit details
        (uint256 a1, uint256 blockNumber, bool isETH) = depositWithdraw.deposits(address(this));

        // Assert that the reward is calculated correctly
        // Assuming the reward is calculated based on the amount and blocks passed
        uint256 expectedReward = (1000 * (block.number - 5 - blockNumber)) / 1000;
    }

}
 