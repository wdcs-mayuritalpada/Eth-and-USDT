// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DepositWithdraw} from "../src/DepositWithdraw.sol";


contract DepositWithdrawScript is Script {
    address public usdt = address(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    address public usdc = address(0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141);
    address public owner = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    function setUp  () public {}

    function run() public {
        vm.broadcast();
       
        DepositWithdraw depositWithdraw = new DepositWithdraw(usdt, usdc);

        console.log("USDT address: ", usdt);
        console.log("USDC address: ", usdc);
        console.log("DepositWithdraw address: ", address(depositWithdraw));
    }
}
