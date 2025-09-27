// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentEscrow.sol";
import "../src/flowrent/FlowRentOracle.sol";

/**
 * @title DirectComponentDeployer
 * @notice Deploys FlowRent components directly and registers them in the Registry
 */
contract DirectComponentDeployer is Script {
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read environment variables from previous deployments
        address REGISTRY_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_ADDRESS");
        string memory NETWORK_NAME = vm.envString("NETWORK_NAME");
        address PYUSD_TOKEN = vm.envAddress("PYUSD_TOKEN_ADDRESS");
        address PROOF_OF_HUMAN_RECEIVER = vm.envAddress("VERIFICATION_CONTRACT_ADDRESS");
        address SABLIER_LOCKUP = vm.envAddress("SABLIER_LOCKUP_ADDRESS");
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying FlowRent Components Directly");
        console.log("Deployer:", deployer);
        console.log("Network Name:", NETWORK_NAME);
        console.log("Registry:", REGISTRY_ADDRESS);
        console.log("PYUSD Token:", PYUSD_TOKEN);
        console.log("Verification Contract:", PROOF_OF_HUMAN_RECEIVER);
        console.log("Sablier Lockup Contract:", SABLIER_LOCKUP);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Escrow directly
        FlowRentEscrow escrow = new FlowRentEscrow(
            PYUSD_TOKEN,
            SABLIER_LOCKUP,
            PROOF_OF_HUMAN_RECEIVER,
            deployer // Initially owned by deployer
        );
        console.log("FlowRentEscrow deployed at:", address(escrow));
        
        // Deploy Oracle directly
        FlowRentOracle oracle = new FlowRentOracle(
            address(escrow),  // Pass the escrow address
            deployer          // Pass the owner
        );
        console.log("FlowRentOracle deployed at:", address(oracle));
        
        // Since we can't register directly, print addresses for manual update
        console.log("Components deployed successfully!");
        console.log("Please add these addresses to your .env file:");
        
        // Set up the Oracle permissions
        console.log("Authorizing deployer as a data feed for pricing updates...");
        oracle.setAuthorizedFeed(deployer, true);
        console.log("Deployer authorized as data feed");
        
        vm.stopBroadcast();
        
        // Print deployment information
        string memory deploymentInfo = string(abi.encodePacked(
            "# FlowRent Components Deployment\n",
            "FLOWRENT_ESCROW_ADDRESS=", vm.toString(address(escrow)), "\n",
            "FLOWRENT_ORACLE_ADDRESS=", vm.toString(address(oracle)), "\n"
        ));
        
        console.log("\n=== COMPONENTS DEPLOYMENT INFORMATION ===");
        console.log(deploymentInfo);
        console.log("=== END COMPONENTS DEPLOYMENT INFORMATION ===");
        console.log("Save this information to your .env file");
    }
}
