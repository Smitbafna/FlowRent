// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentRegistryExtension.sol";
import "../src/flowrent/FlowRentRegistryDeployer.sol";

/**
 * @title Deploy01Registry
 * @notice Deploys only the registry components
 * @dev This is step 1 of the deployment process
 */
contract Deploy01Registry is Script {
    // Private key helper function
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying FlowRent Registry Components");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy registry deployer
        FlowRentRegistryDeployer registryDeployer = new FlowRentRegistryDeployer(deployer);
        console.log("FlowRentRegistryDeployer deployed at:", address(registryDeployer));
        
        // Deploy registry using the registry deployer
        FlowRentRegistry registry = registryDeployer.deployRegistry();
        console.log("FlowRentRegistry deployed at:", address(registry));
        
        // Deploy registry extension using the registry deployer
        FlowRentRegistryExtension registryExtension = registryDeployer.deployRegistryExtension(address(registry));
        console.log("FlowRentRegistryExtension deployed at:", address(registryExtension));
        
        vm.stopBroadcast();
        
        // Print deployment information
        string memory deploymentInfo = string(abi.encodePacked(
            "# FlowRent Registry Components Deployment\n",
            "FLOWRENT_REGISTRY_DEPLOYER=", vm.toString(address(registryDeployer)), "\n",
            "FLOWRENT_REGISTRY_ADDRESS=", vm.toString(address(registry)), "\n",
            "FLOWRENT_REGISTRY_EXTENSION_ADDRESS=", vm.toString(address(registryExtension)), "\n"
        ));
        
        console.log("\n=== REGISTRY DEPLOYMENT INFORMATION ===");
        console.log(deploymentInfo);
        console.log("=== END REGISTRY DEPLOYMENT INFORMATION ===");
        console.log("Save this information to a .env.registry file");
    }
}
