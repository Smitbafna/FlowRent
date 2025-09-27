// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentFactoryCore.sol";
import "./FlowRentFactoryExtension.sol";
import "./FlowRentDeployHelper.sol";

/**
 * @title FlowRentFactoryDeployer
 * @notice Handles deployment of factory components
 */
contract FlowRentFactoryDeployer is Ownable {
    
    constructor(address _owner) Ownable(_owner) {}
    
    /**
     * @notice Deploy factory core contract
     * @param registry The address of the registry contract
     * @param registryExtension The address of the registry extension
     * @param layerZeroEndpoint The address of the LayerZero endpoint
     * @param oftImplementation The address of the OFT implementation
     * @return factoryCore The deployed factory core contract
     */
    function deployFactoryCore(
        address registry,
        address registryExtension,
        address layerZeroEndpoint,
        address oftImplementation
    ) external onlyOwner returns (FlowRentFactoryCore) {
        return new FlowRentFactoryCore(
            registry,
            registryExtension,
            layerZeroEndpoint,
            oftImplementation,
            owner()
        );
    }
    
    /**
     * @notice Deploy helper contract
     * @param factoryCore The address of the factory core contract
     * @return helper The deployed helper contract
     */
    function deployHelper(address factoryCore) external onlyOwner returns (FlowRentDeployHelper) {
        return new FlowRentDeployHelper(factoryCore, owner());
    }
    
    /**
     * @notice Deploy factory extension contract
     * @param factoryCore The address of the factory core
     * @return factoryExtension The deployed factory extension
     */
    function deployFactoryExtension(address factoryCore) external onlyOwner returns (FlowRentFactoryExtension) {
        return new FlowRentFactoryExtension(factoryCore, owner());
    }
}
