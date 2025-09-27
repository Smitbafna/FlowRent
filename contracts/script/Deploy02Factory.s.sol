// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentFactoryCore.sol";
import "../src/flowrent/FlowRentFactoryExtension.sol";
import "../src/flowrent/FlowRentDeployHelper.sol";
import "../src/flowrent/FlowRentFactoryDeployer.sol";

/**
 * @title Deploy02Factory
 * @notice Deploys only the factory components
 * @dev This is step 2 of the deployment process and depends on registry components
 */
contract Deploy02Factory is Script {
    // Private key helper function
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read registry addresses from environment variables
        address REGISTRY_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_ADDRESS");
        address REGISTRY_EXTENSION_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_EXTENSION_ADDRESS");
        address LAYERZERO_ENDPOINT = vm.envAddress("LAYERZERO_ENDPOINT_ADDRESS");
        address PYUSD_TOKEN = vm.envAddress("PYUSD_TOKEN_ADDRESS");
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying FlowRent Factory Components");
        console.log("Deployer:", deployer);
        console.log("Registry:", REGISTRY_ADDRESS);
        console.log("Registry Extension:", REGISTRY_EXTENSION_ADDRESS);
        console.log("LayerZero Endpoint:", LAYERZERO_ENDPOINT);
        console.log("PYUSD Token (OFT Implementation):", PYUSD_TOKEN);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy factory deployer
        FlowRentFactoryDeployer factoryDeployer = new FlowRentFactoryDeployer(deployer);
        console.log("FlowRentFactoryDeployer deployed at:", address(factoryDeployer));
        
        // Deploy FlowRentFactoryCore using the factory deployer
        FlowRentFactoryCore factoryCore = factoryDeployer.deployFactoryCore(
            REGISTRY_ADDRESS,
            REGISTRY_EXTENSION_ADDRESS,
            LAYERZERO_ENDPOINT,
            PYUSD_TOKEN
        );
        console.log("FlowRentFactoryCore deployed at:", address(factoryCore));
        
        // Deploy helper using the factory deployer
        FlowRentDeployHelper deployHelper = factoryDeployer.deployHelper(address(factoryCore));
        console.log("FlowRentDeployHelper deployed at:", address(deployHelper));

        // Deploy FlowRentFactoryExtension using the factory deployer
        FlowRentFactoryExtension factoryExtension = factoryDeployer.deployFactoryExtension(address(factoryCore));
        console.log("FlowRentFactoryExtension deployed at:", address(factoryExtension));
        
        vm.stopBroadcast();
        
        // Print deployment information
        string memory deploymentInfo = string(abi.encodePacked(
            "# FlowRent Factory Components Deployment\n",
            "FLOWRENT_FACTORY_DEPLOYER=", vm.toString(address(factoryDeployer)), "\n",
            "FLOWRENT_FACTORY_CORE_ADDRESS=", vm.toString(address(factoryCore)), "\n",
            "FLOWRENT_DEPLOY_HELPER_ADDRESS=", vm.toString(address(deployHelper)), "\n",
            "FLOWRENT_FACTORY_EXTENSION_ADDRESS=", vm.toString(address(factoryExtension)), "\n"
        ));
        
        console.log("\n=== FACTORY DEPLOYMENT INFORMATION ===");
        console.log(deploymentInfo);
        console.log("=== END FACTORY DEPLOYMENT INFORMATION ===");
        console.log("Save this information to a .env.factory file");
    }
}
