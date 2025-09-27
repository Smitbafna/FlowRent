// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentDeployHelper.sol";
import "../src/flowrent/FlowRentFactoryExtension.sol";
import "../src/flowrent/FlowRentOracle.sol";
import "../src/flowrent/FlowRentEscrow.sol";

/**
 * @title Deploy04Setup
 * @notice Sets up initial vehicle data and configures LayerZero
 * @dev This is step 4 of the deployment process and depends on components deployment
 */
contract Deploy04Setup is Script {
    // Private key helper function
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read environment variables from previous deployments
        address DEPLOY_HELPER = vm.envAddress("FLOWRENT_DEPLOY_HELPER_ADDRESS");
        address FACTORY_EXTENSION = vm.envAddress("FLOWRENT_FACTORY_EXTENSION_ADDRESS");
        address ESCROW_CONTRACT = vm.envAddress("FLOWRENT_ESCROW_ADDRESS");
        address ORACLE_CONTRACT = vm.envAddress("FLOWRENT_ORACLE_ADDRESS");
        string memory NETWORK_NAME = vm.envString("NETWORK_NAME");
        uint256 LZ_CHAIN_ID = vm.envUint("LZ_CHAIN_ID");
        bool IS_NATIVE_PYUSD = vm.envBool("IS_NATIVE_PYUSD");
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Setting up FlowRent Initial Configuration");
        console.log("Deployer:", deployer);
        console.log("Network Name:", NETWORK_NAME);
        console.log("Deploy Helper:", DEPLOY_HELPER);
        console.log("Factory Extension:", FACTORY_EXTENSION);
        console.log("Escrow Contract:", ESCROW_CONTRACT);
        console.log("Oracle Contract:", ORACLE_CONTRACT);
        console.log("LayerZero Chain ID:", LZ_CHAIN_ID);
        console.log("Is PYUSD Native:", IS_NATIVE_PYUSD);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get contract instances
        FlowRentDeployHelper deployHelper = FlowRentDeployHelper(DEPLOY_HELPER);
        FlowRentFactoryExtension factoryExtension = FlowRentFactoryExtension(FACTORY_EXTENSION);
        FlowRentOracle oracle = FlowRentOracle(ORACLE_CONTRACT);
        FlowRentEscrow escrow = FlowRentEscrow(ESCROW_CONTRACT);
        
        // Setup initial vehicles with example data
        bytes32[] memory vehicleIds = new bytes32[](3);
        string[] memory carTypes = new string[](3);
        string[] memory trims = new string[](3);
        uint256[] memory baseRates = new uint256[](3);

        // Tesla Model S
        vehicleIds[0] = keccak256("tesla-model-s-001");
        carTypes[0] = "Tesla Model S";
        trims[0] = "Plaid";
        baseRates[0] = 1e15; // 0.001 PYUSD per second (3.6 PYUSD per hour)

        // Tesla Model 3
        vehicleIds[1] = keccak256("tesla-model-3-001");
        carTypes[1] = "Tesla Model 3";
        trims[1] = "Performance";
        baseRates[1] = 8e14; // 0.0008 PYUSD per second (2.88 PYUSD per hour)

        // Tesla Model Y
        vehicleIds[2] = keccak256("tesla-model-y-001");
        carTypes[2] = "Tesla Model Y";
        trims[2] = "Long Range";
        baseRates[2] = 5e14; // 0.0005 PYUSD per second (1.8 PYUSD per hour)
        
        // Register vehicles in the oracle using deploy helper
        deployHelper.batchSetupDeployment(
            NETWORK_NAME,
            vehicleIds,
            carTypes,
            trims,
            baseRates
        );
        
        console.log("=== Initial Vehicles Created in Oracle ===");
        console.log("Tesla Model S:", vm.toString(vehicleIds[0]));
        console.log("Tesla Model 3:", vm.toString(vehicleIds[1]));
        console.log("Tesla Model Y:", vm.toString(vehicleIds[2]));
        
        // Register assets in the escrow
        for (uint i = 0; i < vehicleIds.length; i++) {
            uint256 assetId = uint256(vehicleIds[i]);
            escrow.registerAsset(
                assetId,
                baseRates[i],
                string.concat(carTypes[i], " ", trims[i]),
                baseRates[i] * 3600, // Minimum deposit is 1 hour of rental
                7 days, // Maximum rental duration
                vehicleIds[i]
            );
        }
        
        console.log("=== Assets Registered in Escrow ===");

        // Update initial pricing data for the vehicles
        uint256 currentTime = block.timestamp;
        
        // Set initial odometer readings in Oracle
        for (uint i = 0; i < vehicleIds.length; i++) {
            // Set initial odometer readings (1 mile instead of 0 since Oracle requires > 0)
            oracle.updatePricingData(
                vehicleIds[i],
                1, // Initial odometer (set to 1 mile since Oracle requires > 0)
                currentTime // Current timestamp
            );
            
            console.log("Set initial pricing data for", carTypes[i]);
        }
        
        console.log("=== Initial Pricing Data Set ===");
        
        // Configure LayerZero for cross-chain functionality
        factoryExtension.configureLayerZeroNetwork(
            NETWORK_NAME,
            uint16(LZ_CHAIN_ID),
            IS_NATIVE_PYUSD
        );
        
        console.log("=== LayerZero Configuration Set ===");
        console.log(NETWORK_NAME, "configured with LZ chain ID:", LZ_CHAIN_ID);
        
        vm.stopBroadcast();
        
        console.log("\n=== FLOWRENT SYSTEM SETUP COMPLETE ===");
        console.log("All components have been deployed and configured");
        console.log("The FlowRent system is now ready to use on", NETWORK_NAME);
    }
}
