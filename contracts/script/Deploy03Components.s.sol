// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "../src/flowrent/FlowRentFactoryCore.sol";
import "../src/flowrent/FlowRentOracle.sol";
import "../src/flowrent/FlowRentEscrow.sol";

/**
 * @title Deploy03Components
 * @notice Deploys the Escrow and Oracle components
 * @dev This is step 3 of the deployment process and depends on factory components
 */
contract Deploy03Components is Script {
    // Private key helper function
    function getDeployerPrivateKey() internal view returns (uint256) {
        return vm.envUint("PRIVATE_KEY");
    }
    
    function run() external {
        // Read environment variables from previous deployments
        address FACTORY_CORE = vm.envAddress("FLOWRENT_FACTORY_CORE_ADDRESS");
        string memory NETWORK_NAME = vm.envString("NETWORK_NAME");
        address PYUSD_TOKEN = vm.envAddress("PYUSD_TOKEN_ADDRESS");
        address PROOF_OF_HUMAN_RECEIVER = vm.envAddress("VERIFICATION_CONTRACT_ADDRESS");
        address SABLIER_LOCKUP = vm.envAddress("SABLIER_LOCKUP_ADDRESS");
        
        uint256 deployerPrivateKey = getDeployerPrivateKey();
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying FlowRent Components (Escrow, Oracle)");
        console.log("Deployer:", deployer);
        console.log("Network Name:", NETWORK_NAME);
        console.log("Factory Core:", FACTORY_CORE);
        console.log("PYUSD Token:", PYUSD_TOKEN);
        console.log("Verification Contract:", PROOF_OF_HUMAN_RECEIVER);
        console.log("Sablier Lockup Contract:", SABLIER_LOCKUP);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get factory core instance
        FlowRentFactoryCore factoryCore = FlowRentFactoryCore(FACTORY_CORE);
        
        // Deploy Escrow and Oracle through the factory
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
        
        console.log("FlowRentEscrow deployed at:", escrowContract);
        console.log("FlowRentOracle deployed at:", oracleContract);
        
        // Set up the Oracle permissions
        FlowRentOracle oracle = FlowRentOracle(oracleContract);
        
        // Add the deployer as an authorized data feed
        console.log("Authorizing deployer as a data feed for pricing updates...");
        oracle.setAuthorizedFeed(deployer, true);
        console.log("Deployer authorized as data feed");
        
        // Transfer Oracle ownership to factory core
        console.log("Transferring Oracle ownership to factory for vehicle registration...");
        oracle.transferOwnership(FACTORY_CORE);
        console.log("Oracle ownership transferred to factory:", FACTORY_CORE);
        
        vm.stopBroadcast();
        
        // Print deployment information
        string memory deploymentInfo = string(abi.encodePacked(
            "# FlowRent Components Deployment\n",
            "FLOWRENT_ESCROW_ADDRESS=", vm.toString(escrowContract), "\n",
            "FLOWRENT_ORACLE_ADDRESS=", vm.toString(oracleContract), "\n"
        ));
        
        console.log("\n=== COMPONENTS DEPLOYMENT INFORMATION ===");
        console.log(deploymentInfo);
        console.log("=== END COMPONENTS DEPLOYMENT INFORMATION ===");
        console.log("Save this information to a .env.components file");
    }
}
