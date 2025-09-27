// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentFactoryCore.sol";
import "./FlowRentOracle.sol";
import "./FlowRentRegistry.sol"; // Add registry import

/**
 * @title FlowRentDeployHelper
 * @notice Additional helper contract to further reduce the size of FlowRentFactoryCore
 * @dev Contains batch setup functionality and utility methods
 */
contract FlowRentDeployHelper is Ownable {
    // Core factory reference
    FlowRentFactoryCore public immutable factoryCore;
    
    // Events
    event BatchSetupCompleted(string network, uint256 vehicleCount);
    event PricingDataUpdated(string network, bytes32 vehicleId);

    constructor(
        address _factoryCore,
        address _owner
    ) Ownable(_owner) {
        require(_factoryCore != address(0), "Invalid factory core");
        factoryCore = FlowRentFactoryCore(_factoryCore);
    }
    
    /**
     * @notice Batch setup for a new deployment with vehicle registration
     * @param network Network identifier  
     * @param vehicleIds Array of initial vehicle IDs
     * @param carTypes Array of vehicle types
     * @param trims Array of vehicle trim levels
     * @param baseRates Array of base rates for vehicles
     */
    function batchSetupDeployment(
        string memory network,
        bytes32[] memory vehicleIds,
        string[] memory carTypes,
        string[] memory trims,
        uint256[] memory baseRates
    ) external onlyOwner {
        require(vehicleIds.length == carTypes.length, "Array length mismatch");
        require(carTypes.length == trims.length, "Array length mismatch");
        require(trims.length == baseRates.length, "Array length mismatch");
        
        // Get deployment from core factory using destructuring
        (address escrowContract, address oracleContract, , , , ) = factoryCore.getDeployment(network);
        require(escrowContract != address(0), "Network not deployed");

        FlowRentOracle oracle = FlowRentOracle(oracleContract);

        // Register initial vehicles
        for (uint256 i = 0; i < vehicleIds.length; i++) {
            oracle.registerVehicle(
                vehicleIds[i],
                carTypes[i],
                trims[i],
                baseRates[i]
            );
        }
        
        emit BatchSetupCompleted(network, vehicleIds.length);
    }
    
    /**
     * @notice Batch update pricing data for multiple vehicles
     * @param network Network identifier
     * @param vehicleIds Array of vehicle IDs
     * @param odometers Array of odometer readings
     * @param timestamps Array of data timestamps
     */
    function batchUpdatePricingData(
        string memory network,
        bytes32[] memory vehicleIds,
        uint256[] memory odometers,
        uint256[] memory timestamps
    ) external onlyOwner {
        require(vehicleIds.length == odometers.length, "Array length mismatch");
        require(odometers.length == timestamps.length, "Array length mismatch");
        
        // Get deployment from core factory using destructuring
        (address escrowContract, address oracleContract, , , , ) = factoryCore.getDeployment(network);
        require(escrowContract != address(0), "Network not deployed");

        FlowRentOracle oracle = FlowRentOracle(oracleContract);

        // Update pricing data in batch
        for (uint256 i = 0; i < vehicleIds.length; i++) {
            oracle.updatePricingData(
                vehicleIds[i],
                odometers[i],
                timestamps[i]
            );
            
            emit PricingDataUpdated(network, vehicleIds[i]);
        }
    }

    /**
     * @notice Get deployment info from core factory
     */
    function getDeploymentInfo(string memory network) public view returns (
        address escrow,
        address oracle,
        address pyusd,
        address verification
    ) {
        // The deployment struct is now in the registry, but accessed through the factoryCore
        (escrow, oracle, pyusd, verification, , ) = factoryCore.getDeployment(network);
        return (escrow, oracle, pyusd, verification);
    }
}
