// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentRegistryDeployer.sol";
import "../src/flowrent/FlowRentFactoryDeployer.sol";
import "../src/flowrent/FlowRentRegistry.sol";
import "../src/flowrent/FlowRentRegistryExtension.sol";
import "../src/flowrent/FlowRentFactoryCore.sol";
import "../src/flowrent/FlowRentFactoryExtension.sol";
import "../src/flowrent/FlowRentDeployHelper.sol";
import "../src/flowrent/FlowRentOracle.sol";
import "../src/flowrent/FlowRentEscrow.sol";

/**
 * @title DeployFlowRentSystem
 * @notice Main deployment script for FlowRent system on any network
 * @dev This script uses the FlowRentDeploymentManager to deploy all components
 */
contract DeployFlowRentSystem is Script {
    // Private key helper function
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read addresses from environment variables
        address PYUSD_TOKEN = vm.envAddress("PYUSD_TOKEN_ADDRESS");
        address PROOF_OF_HUMAN_RECEIVER = vm.envAddress("VERIFICATION_CONTRACT_ADDRESS");
        address SABLIER_LOCKUP = vm.envAddress("SABLIER_LOCKUP_ADDRESS");
        address LAYERZERO_ENDPOINT = vm.envAddress("LAYERZERO_ENDPOINT_ADDRESS");
        string memory NETWORK_NAME = vm.envString("NETWORK_NAME");
        uint256 LZ_CHAIN_ID = vm.envUint("LZ_CHAIN_ID");
        bool IS_NATIVE_PYUSD = vm.envBool("IS_NATIVE_PYUSD");
        
        // For OFT implementation, use PYUSD token address as the "implementation" for hackathon purposes
        address OFT_IMPLEMENTATION_ADDRESS = PYUSD_TOKEN;
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying FlowRent System on", NETWORK_NAME);
        console.log("Deployer:", deployer);
        console.log("PYUSD Token:", PYUSD_TOKEN);
        console.log("Verification Contract:", PROOF_OF_HUMAN_RECEIVER);
        console.log("Sablier Lockup Contract:", SABLIER_LOCKUP);
        console.log("LayerZero Endpoint:", LAYERZERO_ENDPOINT);
        console.log("LayerZero Chain ID:", LZ_CHAIN_ID);
        console.log("Is PYUSD Native:", IS_NATIVE_PYUSD);
        console.log("OFT Implementation:", OFT_IMPLEMENTATION_ADDRESS);

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
        
        // Deploy factory deployer
        FlowRentFactoryDeployer factoryDeployer = new FlowRentFactoryDeployer(deployer);
        console.log("FlowRentFactoryDeployer deployed at:", address(factoryDeployer));
        
        // Deploy FlowRentFactoryCore using the factory deployer
        FlowRentFactoryCore factoryCore = factoryDeployer.deployFactoryCore(
            address(registry),
            address(registryExtension),
            LAYERZERO_ENDPOINT,
            OFT_IMPLEMENTATION_ADDRESS
        );
        console.log("FlowRentFactoryCore deployed at:", address(factoryCore));
        
        // Transfer registry and extension ownership to factory core
        registry.transferOwnership(address(factoryCore));
        registryExtension.transferOwnership(address(factoryCore));
        console.log("Registry ownership transferred to factory core");
        
        // Deploy helper using the factory deployer
        FlowRentDeployHelper deployHelper = factoryDeployer.deployHelper(address(factoryCore));
        console.log("FlowRentDeployHelper deployed at:", address(deployHelper));

        // Deploy FlowRentFactoryExtension using the factory deployer
        FlowRentFactoryExtension factoryExtension = factoryDeployer.deployFactoryExtension(address(factoryCore));
        console.log("FlowRentFactoryExtension deployed at:", address(factoryExtension));

        // Deploy complete FlowRent ecosystem
        (
            address escrowContract,
            address oracleContract
        ) = factoryCore.deployFlowRent(
            NETWORK_NAME,
            PYUSD_TOKEN,
            PROOF_OF_HUMAN_RECEIVER,
            SABLIER_LOCKUP,
            "v1.0.0"
        );

        console.log("=== FlowRent Deployment Complete ===");
        console.log("Network:", NETWORK_NAME);
        console.log("FlowRentEscrow:", escrowContract);
        console.log("FlowRentOracle:", oracleContract);
        
        // Set up the Oracle permissions
        FlowRentOracle oracle = FlowRentOracle(oracleContract);
        
        // Add the deployer as an authorized data feed
        console.log("Authorizing deployer as a data feed for pricing updates...");
        oracle.setAuthorizedFeed(deployer, true);
        console.log("Deployer authorized as data feed");
        
        // Transfer Oracle ownership to factory core
        console.log("Transferring Oracle ownership to factory for vehicle registration...");
        oracle.transferOwnership(address(factoryCore));
        console.log("Oracle ownership transferred to factory:", address(factoryCore));

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
        FlowRentEscrow escrow = FlowRentEscrow(escrowContract);
        
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

        // Print deployment addresses for saving
        string memory deploymentInfo = string(abi.encodePacked(
            "# FlowRent ", NETWORK_NAME, " Deployment\n",
            "FLOWRENT_FACTORY_CORE_ADDRESS=", vm.toString(address(factoryCore)), "\n",
            "FLOWRENT_FACTORY_EXTENSION_ADDRESS=", vm.toString(address(factoryExtension)), "\n",
            "FLOWRENT_REGISTRY_ADDRESS=", vm.toString(address(registry)), "\n",
            "FLOWRENT_REGISTRY_EXTENSION_ADDRESS=", vm.toString(address(registryExtension)), "\n",
            "FLOWRENT_ESCROW_ADDRESS=", vm.toString(escrowContract), "\n",
            "FLOWRENT_ORACLE_ADDRESS=", vm.toString(oracleContract), "\n",
            "PYUSD_TOKEN_ADDRESS=", vm.toString(PYUSD_TOKEN), "\n",
            "VERIFICATION_CONTRACT_ADDRESS=", vm.toString(PROOF_OF_HUMAN_RECEIVER), "\n"
        ));

        console.log("\n=== DEPLOYMENT INFORMATION ===");
        console.log(deploymentInfo);
        console.log("=== END DEPLOYMENT INFORMATION ===");
        console.log("Copy this information to a .env.deployed file");
    }
}
