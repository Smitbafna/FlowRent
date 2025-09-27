// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentRegistry.sol";
import "./FlowRentRegistryExtension.sol";

/**
 * @title FlowRentFactoryCore
 * @notice Ultra-slim factory that delegates deployment to the registry (optimized for contract size)
 */
contract FlowRentFactoryCore is Ownable {
    
    // Deployment registry reference
    FlowRentRegistry public immutable registry;
    
    // Registry extension for deployments
    FlowRentRegistryExtension public immutable registryExtension;
    
    // LayerZero integration
    address public layerZeroEndpoint;
    address public oftImplementation;
    
    // Events
    event FlowRentDeployed(
        string indexed network,
        address escrowContract,
        address oracleContract
    );
    event LayerZeroConfigured(address endpoint, address oftImplementation);

    constructor(
        address _registry,
        address _registryExtension,
        address _layerZeroEndpoint,
        address _oftImplementation,
        address _owner
    ) Ownable(_owner) {
        require(_registry != address(0), "Invalid registry address");
        require(_registryExtension != address(0), "Invalid registry extension address");
        require(_layerZeroEndpoint != address(0), "Invalid LZ endpoint");
        require(_oftImplementation != address(0), "Invalid OFT implementation");
        
        registry = FlowRentRegistry(_registry);
        registryExtension = FlowRentRegistryExtension(_registryExtension);
        layerZeroEndpoint = _layerZeroEndpoint;
        oftImplementation = _oftImplementation;
        
        emit LayerZeroConfigured(_layerZeroEndpoint, _oftImplementation);
    }

    /**
     * @notice Deploy complete FlowRent ecosystem for a network
     * @param network Network identifier (e.g., "arbitrum-sepolia")
     * @param pyusdToken PYUSD token contract address on target network
     * @param verificationContract ProofOfHuman contract address
     * @param sablierLockupContract Sablier lockup contract address
     * @param version Version identifier for this deployment
     */
    function deployFlowRent(
        string memory network,
        address pyusdToken,
        address verificationContract,
        address sablierLockupContract,
        string memory version
    ) external onlyOwner returns (
        address escrowContract,
        address oracleContract
    ) {
        // Delegate deployment to the registry extension to save contract size
        (escrowContract, oracleContract) = registryExtension.deployFlowRent(
            network,
            pyusdToken,
            verificationContract,
            sablierLockupContract,
            version,
            owner()
        );

        emit FlowRentDeployed(network, escrowContract, oracleContract);
        return (escrowContract, oracleContract);
    }

    /**
     * @notice Get deployment details for a network from registry (pass-through)
     * @param network Network to query
     */
    function getDeployment(string memory network) external view returns (
        address escrowContract,
        address oracleContract,
        address pyusdToken,
        address verificationContract,
        uint256 deploymentBlock,
        string memory version
    ) {
        // Get deployment from registry
        FlowRentRegistry.FlowRentDeployment memory deployment = registry.getDeployment(network);
        
        // Return as tuple to make more gas efficient
        return (
            deployment.escrowContract,
            deployment.oracleContract,
            deployment.pyusdToken,
            deployment.verificationContract,
            deployment.deploymentBlock,
            deployment.version
        );
    }

   
    // All implementation moved to registry and deploy helper
}
