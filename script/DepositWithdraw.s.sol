// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DepositWithdraw} from "../src/DepositWithdraw.sol";
import {USDT} from "../src/USDT.sol";
import {USDC} from "../src/USDC.sol";

/**
 * @title DepositWithdrawScript
 * @dev A deployment script for the DepositWithdraw contract.
 * This script deploys the DepositWithdraw contract along with its dependencies (USDT and USDC).
 */
contract DepositWithdrawScript is Script {

    // State Variables
    DepositWithdraw public depositWithdraw;
    USDT public usdt;
    USDC public usdc;

    /**
     * @dev Run the deployment script.
     * Deploys the USDT, USDC, and DepositWithdraw contracts.
     * @return depositWithdraw The deployed DepositWithdraw contract instance.
     */
    function run() public returns (DepositWithdraw) {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy USDT and USDC contracts
        usdt = new USDT(msg.sender);
        usdc = new USDC(msg.sender);

        // Deploy the DepositWithdraw contract with USDT and USDC addresses
        depositWithdraw = new DepositWithdraw(address(usdt), address(usdc));

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log deployment details
        console.log("USDT deployed at:", address(usdt));
        console.log("USDC deployed at:", address(usdc));
        console.log("DepositWithdraw deployed at:", address(depositWithdraw));

        return depositWithdraw;
    }
}
