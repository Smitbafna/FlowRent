// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentRegistryExtension.sol";

/**
 * @title TransferRegistryOwnership
 * @notice Transfers ownership of Registry components to Factory Core
 * @dev This should be run after Deploy02Factory and before Deploy03Components
 */
contract TransferRegistryOwnership is Script {
    // Private key helper function
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read addresses from environment variables
        address REGISTRY_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_ADDRESS");
        address REGISTRY_EXTENSION_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_EXTENSION_ADDRESS");
        address FACTORY_CORE_ADDRESS = vm.envAddress("FLOWRENT_FACTORY_CORE_ADDRESS");
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Transferring Registry Ownership to Factory Core");
        console.log("Deployer:", deployer);
        console.log("Registry:", REGISTRY_ADDRESS);
        console.log("Registry Extension:", REGISTRY_EXTENSION_ADDRESS);
        console.log("Factory Core:", FACTORY_CORE_ADDRESS);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Transfer ownership of Registry to Factory Core
        FlowRentRegistry registry = FlowRentRegistry(REGISTRY_ADDRESS);
        registry.transferOwnership(FACTORY_CORE_ADDRESS);
        console.log("Registry ownership transferred to Factory Core");
        
        // Transfer ownership of Registry Extension to Factory Core
        FlowRentRegistryExtension registryExtension = FlowRentRegistryExtension(REGISTRY_EXTENSION_ADDRESS);
        registryExtension.transferOwnership(FACTORY_CORE_ADDRESS);
        console.log("Registry Extension ownership transferred to Factory Core");
        
        vm.stopBroadcast();
        
        console.log("\n=== OWNERSHIP TRANSFER COMPLETE ===");
        console.log("You can now proceed with Deploy03Components");
    }
}
