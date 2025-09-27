// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentFactoryCore.sol";

/**
 * @title RegisterDeployment
 * @notice Registers the already deployed Escrow and Oracle in the Registry
 */
contract RegisterDeployment is Script {
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read environment variables from previous deployments
        address REGISTRY_ADDRESS = vm.envAddress("FLOWRENT_REGISTRY_ADDRESS");
        address FACTORY_CORE_ADDRESS = vm.envAddress("FLOWRENT_FACTORY_CORE_ADDRESS");
        address ESCROW_ADDRESS = vm.envAddress("FLOWRENT_ESCROW_ADDRESS");
        address ORACLE_ADDRESS = vm.envAddress("FLOWRENT_ORACLE_ADDRESS");
        address PYUSD_TOKEN = vm.envAddress("PYUSD_TOKEN_ADDRESS");
        address VERIFICATION_CONTRACT = vm.envAddress("VERIFICATION_CONTRACT_ADDRESS");
        string memory NETWORK_NAME = vm.envString("NETWORK_NAME");
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Registering Deployment in Registry");
        console.log("Deployer:", deployer);
        console.log("Network Name:", NETWORK_NAME);
        console.log("Registry:", REGISTRY_ADDRESS);
        console.log("Factory Core:", FACTORY_CORE_ADDRESS);
        console.log("Escrow Contract:", ESCROW_ADDRESS);
        console.log("Oracle Contract:", ORACLE_ADDRESS);
        console.log("PYUSD Token:", PYUSD_TOKEN);
        console.log("Verification Contract:", VERIFICATION_CONTRACT);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use Factory Core (the current owner of Registry) to register
        FlowRentFactoryCore factoryCore = FlowRentFactoryCore(FACTORY_CORE_ADDRESS);
        FlowRentRegistry registry = FlowRentRegistry(REGISTRY_ADDRESS);

        // First check if already registered
        FlowRentRegistry.FlowRentDeployment memory existing = registry.getDeployment(NETWORK_NAME);
        if (existing.escrowContract != address(0)) {
            console.log("Network already registered in Registry.");
            vm.stopBroadcast();
            return;
        }
        
        // Register the deployment
        registry.registerDeployment(
            NETWORK_NAME,
            ESCROW_ADDRESS,
            ORACLE_ADDRESS,
            PYUSD_TOKEN,
            VERIFICATION_CONTRACT,
            "v1.0.0"
        );
        console.log("Deployment registered successfully in Registry");
        
        vm.stopBroadcast();
    }
}
