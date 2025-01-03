// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DepositWithdraw} from "../src/DepositWithdraw.sol";



contract DepositWithdrawTest is Test {

    DepositWithdraw public depositWithdraw;
 

    address public usdt = address(0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141);
    address public usdc = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    address public owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public user = address(0x123);

    function setUp() public {
    
        depositWithdraw = new DepositWithdraw(address(usdt), address(usdc));
    }
     
    
}
 