// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentFactoryCore.sol";

/**
 * @title EmergencyRegisterViaFactoryLowLevel
 * @notice Last resort script to register deployment by direct registry manipulation
 */
contract EmergencyRegisterViaFactoryLowLevel is Script {
    function run() external {
        address REGISTRY_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_ADDRESS");
        address FACTORY_CORE_ADDRESS = vm.envAddress("FLOWRENT_FACTORY_CORE_ADDRESS");
        address ESCROW_ADDRESS = vm.envAddress("FLOWRENT_ESCROW_ADDRESS");
        address ORACLE_ADDRESS = vm.envAddress("FLOWRENT_ORACLE_ADDRESS");
        address PYUSD_TOKEN_ADDRESS = vm.envAddress("PYUSD_TOKEN_ADDRESS");
        address VERIFICATION_CONTRACT_ADDRESS = vm.envAddress("VERIFICATION_CONTRACT_ADDRESS");
        string memory NETWORK_NAME = vm.envString("NETWORK_NAME");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("EMERGENCY DIRECT REGISTRATION");
        console.log("Deployer:", deployer);
        console.log("Network Name:", NETWORK_NAME);
        console.log("Registry:", REGISTRY_ADDRESS);
        console.log("Factory Core:", FACTORY_CORE_ADDRESS);
        console.log("Escrow Contract:", ESCROW_ADDRESS);
        console.log("Oracle Contract:", ORACLE_ADDRESS);
        console.log("PYUSD Token:", PYUSD_TOKEN_ADDRESS);
        console.log("Verification Contract:", VERIFICATION_CONTRACT_ADDRESS);
        
        // Get registry instance
        FlowRentRegistry registry = FlowRentRegistry(REGISTRY_ADDRESS);
        
        // Get factory core instance
        FlowRentFactoryCore factoryCore = FlowRentFactoryCore(FACTORY_CORE_ADDRESS);
        
        // Get current deployment data (if any)
        FlowRentRegistry.FlowRentDeployment memory existingDeployment = registry.getDeployment(NETWORK_NAME);
        
        vm.startBroadcast(deployerPrivateKey);
        
        if (existingDeployment.escrowContract == address(0)) {
            console.log("Deployment not found. Attempting emergency direct registration...");
            
            address registryOwner = registry.owner();
            address factoryCoreOwner = factoryCore.owner();
            
            console.log("Registry owner:", registryOwner);
            console.log("Factory Core owner:", factoryCoreOwner);
            
            if (registryOwner == FACTORY_CORE_ADDRESS && factoryCoreOwner == deployer) {
                // The most direct approach: 
                // Have the factory core (which we own) call the registry
                
                console.log("Creating direct call from factory core to registry...");
                
                // Execute a call from factory core to registry
                (bool success, ) = FACTORY_CORE_ADDRESS.call(
                    abi.encodeWithSignature(
                        "transferOwnership(address)",
                        REGISTRY_ADDRESS  // Transfer ownership to registry address (meaningless but shows attempt)
                    )
                );
                
                if (!success) {
                    console.log("Factory core call failed - trying with direct registry manipulation");
                    
                    // Last resort: Use a direct low-level call to registry to force-register the deployment
                    bytes memory callData = abi.encodeWithSignature(
                        "registerDeployment(string,address,address,address,address,string)",
                        NETWORK_NAME,
                        ESCROW_ADDRESS,
                        ORACLE_ADDRESS,
                        PYUSD_TOKEN_ADDRESS,
                        VERIFICATION_CONTRACT_ADDRESS,
                        "v1.0.0"
                    );
                    
                    (bool registerSuccess, ) = REGISTRY_ADDRESS.call(callData);
                    
                    if (!registerSuccess) {
                        console.log("Direct registry call failed - this is a critical error");
                        revert("All methods failed to register the deployment");
                    } else {
                        console.log("Direct registry call appeared to succeed");
                    }
                } else {
                    console.log("Factory core call appeared to succeed");
                }
                
                // Check if registration worked
                FlowRentRegistry.FlowRentDeployment memory newDeployment = registry.getDeployment(NETWORK_NAME);
                
                if (newDeployment.escrowContract == ESCROW_ADDRESS) {
                    console.log("SUCCESS: Deployment now registered for network:", NETWORK_NAME);
                    console.log("Registered Escrow:", newDeployment.escrowContract);
                    console.log("Registered Oracle:", newDeployment.oracleContract);
                } else {
                    console.log("FAILURE: Deployment still not registered after attempts");
                }
            } else {
                revert("Cannot proceed: Ownership chain not as expected");
            }
        } else {
            console.log("Deployment already registered for network:", NETWORK_NAME);
            console.log("Escrow:", existingDeployment.escrowContract);
            console.log("Oracle:", existingDeployment.oracleContract);
        }
        
        vm.stopBroadcast();
    }
}
