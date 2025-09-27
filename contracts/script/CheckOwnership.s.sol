// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentRegistryExtension.sol";

/**
 * @title CheckOwnership
 * @notice Checks the current ownership of Registry components
 */
contract CheckOwnership is Script {
    function run() external view {
        // Read addresses from environment variables
        address REGISTRY_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_ADDRESS");
        address REGISTRY_EXTENSION_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_EXTENSION_ADDRESS");
        address FACTORY_CORE_ADDRESS = vm.envAddress("FLOWRENT_FACTORY_CORE_ADDRESS");
        
        FlowRentRegistry registry = FlowRentRegistry(REGISTRY_ADDRESS);
        FlowRentRegistryExtension registryExtension = FlowRentRegistryExtension(REGISTRY_EXTENSION_ADDRESS);
        
        address registryOwner = registry.owner();
        address extensionOwner = registryExtension.owner();
        
        console.log("Current Ownership Status:");
        console.log("========================");
        console.log("Registry Address:", REGISTRY_ADDRESS);
        console.log("Registry Owner:", registryOwner);
        console.log("Registry Extension Address:", REGISTRY_EXTENSION_ADDRESS);
        console.log("Registry Extension Owner:", extensionOwner);
        console.log("Factory Core Address:", FACTORY_CORE_ADDRESS);
    }
}
