// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

/**
 * @title DeployFlowRentOrchestrator
 * @notice Orchestrates the modular deployment of FlowRent components
 * @dev This script provides guidance on the deployment process and sequence
 * 
 * The deployment architecture follows a modular approach:
 * 1. Registry - The central repository for tracking deployments across chains
 * 2. Factory - Components that handle creation of new system instances
 * 3. Core Components - The main functional contracts (Escrow, Oracle)
 * 4. Configuration - Final setup and permissions management
 * 
 * This orchestrator doesn't perform the actual deployments but guides users
 * through the process and proper sequence for deploying the system.
 * For actual deployments, use the numbered scripts or DeployFlowRentSystem.s.sol.
 */
contract DeployFlowRentOrchestrator is Script {
    function run() external {
        console.log("=== FlowRent Modular Deployment Orchestrator ===");
        console.log("This script runs the individual component deployments in sequence");
        console.log("1. Deploy01Registry - Registry components");
        console.log("2. Deploy02Factory - Factory components");
        console.log("3. Deploy03Components - System components (Escrow, Oracle)");
        console.log("4. Deploy04Setup - Initial setup and configuration");
        console.log("");
        console.log("Each step will generate its own .env file with component addresses");
        console.log("Follow the instructions after each step to set up for the next step");
        console.log("");
        console.log("To deploy the complete system at once, use DeployFlowRentSystem.s.sol");
        console.log("To deploy individual components, use the numbered deployment scripts");
        console.log("");
        console.log("For deployment:");
        console.log("1. forge script script/Deploy01Registry.s.sol --rpc-url <RPC_URL> --broadcast");
        console.log("2. forge script script/Deploy02Factory.s.sol --rpc-url <RPC_URL> --broadcast");
        console.log("... and so on for the remaining components");
    }
}
