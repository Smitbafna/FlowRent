// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentRegistry.sol";
import "./FlowRentRegistryExtension.sol";

/**
 * @title FlowRentRegistryDeployer
 * @notice Handles deployment of the registry and extension components
 */
contract FlowRentRegistryDeployer is Ownable {
    
    constructor(address _owner) Ownable(_owner) {}
    
    /**
     * @notice Deploy registry contract
     * @return registry The deployed registry contract
     */
    function deployRegistry() external onlyOwner returns (FlowRentRegistry) {
        return new FlowRentRegistry(owner());
    }
    
    /**
     * @notice Deploy registry extension contract
     * @param registry The address of the registry contract
     * @return extension The deployed registry extension contract
     */
    function deployRegistryExtension(
        address registry
    ) external onlyOwner returns (FlowRentRegistryExtension) {
        return new FlowRentRegistryExtension(registry, owner());
    }
}
