// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentRegistry.sol";

/**
 * @title FlowRentRegistryExtension
 * @notice Extension for FlowRentRegistry that handles deployment functionality
 * @dev Separated from main registry to reduce contract size
 */
contract FlowRentRegistryExtension is Ownable {
    // Reference to the main registry
    FlowRentRegistry public immutable registry;

    event DeploymentExecuted(
        string indexed network,
        address escrowContract,
        address oracleContract
    );

    constructor(
        address _registry,
        address _owner
    ) Ownable(_owner) {
        require(_registry != address(0), "Invalid registry address");
        registry = FlowRentRegistry(_registry);
    }

    /**
     * @notice Deploy complete FlowRent ecosystem for a network
     * @param network Network identifier (e.g., "arbitrum-sepolia")
     * @param pyusdToken PYUSD token contract address on target network
     * @param verificationContract ProofOfHuman contract address
     * @param sablierLockupContract Sablier lockup contract address
     * @param version Version identifier for this deployment
     * @param _owner Owner address for the deployed contracts
     */
    function deployFlowRent(
        string memory network,
        address pyusdToken,
        address verificationContract,
        address sablierLockupContract,
        string memory version,
        address _owner
    ) external onlyOwner returns (
        address escrowContract,
        address oracleContract
    ) {
        require(bytes(network).length > 0, "Network name required");
        require(pyusdToken != address(0), "Invalid PYUSD token address");
        require(verificationContract != address(0), "Invalid verification contract");
        require(sablierLockupContract != address(0), "Invalid Sablier contract address");
        
        // Check network not already deployed
        FlowRentRegistry.FlowRentDeployment memory existing = registry.getDeployment(network);
        require(existing.escrowContract == address(0), "Network already deployed");

        // We no longer deploy contracts here, we just register the deployment
        // The actual deployment will be done by the factory core
        escrowContract = address(0); // Placeholder values
        oracleContract = address(0); // These should be set by the factory after deployment

        // Register deployment in registry
        registry.registerDeployment(
            network,
            escrowContract,
            oracleContract,
            pyusdToken,
            verificationContract,
            version
        );

        emit DeploymentExecuted(network, escrowContract, oracleContract);
        return (escrowContract, oracleContract);
    }
}
