// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./FlowRentEscrow.sol";
import "./FlowRentOracle.sol";
import "./FlowRentPYUSDOFT.sol";
import "./interfaces/IOFT.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

/**
 * @title FlowRentFactory
 * @notice Factory contract for deploying and managing FlowRent ecosystem contracts
 * @dev Centralizes deployment and configuration of all FlowRent contracts
 */
contract FlowRentFactory is Ownable {
    
    // Contract addresses
    struct FlowRentDeployment {
        address escrowContract;
        address oracleContract;
        address pyusdToken;
        address verificationContract;
        uint256 deploymentBlock;
        string version;
        address pyusdOFTWrapper;    // LayerZero OFT wrapper for cross-chain PYUSD
        uint16 layerZeroChainId;    // LayerZero chain ID for this deployment
        bool isNativePYUSD;         // Whether PYUSD is native on this chain
    }

    // Deployment tracking
    mapping(string => FlowRentDeployment) public deployments;  // network => deployment
    mapping(address => bool) public isFlowRentContract;        // contract => isValid
    
    string[] public deployedNetworks;
    uint256 public totalDeployments;

    // Default configuration
    uint256 public constant DEFAULT_REVIEWER_STAKE = 1000e18;  // 1000 PYUSD
    
    // LayerZero integration
    address public layerZeroEndpoint;
    address public oftImplementation;
    
    // Cross-chain deployment mappings
    mapping(uint16 => string) public layerZeroChainIdToNetwork;  // LZ chain ID to network name
    mapping(string => uint16) public networkToLayerZeroChainId;  // network name to LZ chain ID
    
    // Events
    event FlowRentDeployed(
        string indexed network,
        address escrowContract,
        address oracleContract
    );
    event ContractUpgraded(string indexed network, string contractType, address oldAddress, address newAddress);
    event LayerZeroConfigured(address endpoint, address oftImplementation);
    event CrossChainNetworkConfigured(string network, uint16 layerZeroChainId, bool isNativePYUSD);
    event CrossChainDeploymentInitiated(string sourceNetwork, string targetNetwork, uint16 targetChainId);
    event CrossChainDeploymentReceived(uint16 indexed srcChainId, bytes payload);
    event PYUSDOFTDeployed(uint16 indexed chainId, address indexed oftAddress);
    event CrossChainRentalInitiated(uint16 indexed dstChainId, uint256 vehicleId, address renter);
    event CrossChainPaymentProcessed(uint16 indexed srcChainId, uint256 vehicleId, uint256 amount);

    constructor(
        address _owner,
        address _layerZeroEndpoint,
        address _oftImplementation
    ) Ownable(_owner) {
        require(_layerZeroEndpoint != address(0), "Invalid LZ endpoint");
        require(_oftImplementation != address(0), "Invalid OFT implementation");
        
        layerZeroEndpoint = _layerZeroEndpoint;
        oftImplementation = _oftImplementation;
        
        emit LayerZeroConfigured(_layerZeroEndpoint, _oftImplementation);
    }

    /**
     * @notice Deploy complete FlowRent ecosystem for a network
     * @param network Network identifier (e.g., "arbitrum-sepolia")
     * @param pyusdToken PYUSD token contract address on target network
     * @param verificationContract ProofOfHumanReceiver contract address
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
        require(bytes(network).length > 0, "Network name required");
        require(pyusdToken != address(0), "Invalid PYUSD token address");
        require(verificationContract != address(0), "Invalid verification contract");
        require(sablierLockupContract != address(0), "Invalid Sablier contract address");
        require(deployments[network].escrowContract == address(0), "Network already deployed");

        // Deploy FlowRentEscrow
        FlowRentEscrow escrow = new FlowRentEscrow(
            pyusdToken,
            verificationContract,
            sablierLockupContract,
            owner()
        );
        escrowContract = address(escrow);

        // Deploy FlowRentOracle
        FlowRentOracle oracle = new FlowRentOracle(
            escrowContract,
            owner()
        );
        oracleContract = address(oracle);

        // Store deployment
        deployments[network] = FlowRentDeployment({
            escrowContract: escrowContract,
            oracleContract: oracleContract,
            pyusdToken: pyusdToken,
            verificationContract: verificationContract,
            deploymentBlock: block.number,
            version: version,
            pyusdOFTWrapper: address(0),  // No OFT wrapper by default
            layerZeroChainId: 0,          // No LZ chain ID by default
            isNativePYUSD: true           // Assume PYUSD is native by default
        });

        // Mark contracts as valid
        isFlowRentContract[escrowContract] = true;
        isFlowRentContract[oracleContract] = true;

        // Update tracking
        deployedNetworks.push(network);
        totalDeployments++;

        emit FlowRentDeployed(network, escrowContract, oracleContract);

        return (escrowContract, oracleContract);
    }

    /**
     * @notice Get deployment details for a network
     * @param network Network to query
     * @return deployment Complete deployment information
     */
    function getDeployment(string memory network) external view returns (FlowRentDeployment memory deployment) {
        return deployments[network];
    }

    /**
     * @notice Get all deployed networks
     * @return networks Array of network names
     */
    function getDeployedNetworks() external view returns (string[] memory networks) {
        return deployedNetworks;
    }

    /**
     * @notice Check if an address is a valid FlowRent contract
     * @param contractAddress Address to check
     * @return isValid Whether the address is a valid FlowRent contract
     */
    function isValidFlowRentContract(address contractAddress) external view returns (bool isValid) {
        return isFlowRentContract[contractAddress];
    }

    /**
     * @notice Upgrade a contract in a deployment
     * @param network Network to upgrade
     * @param contractType Type of contract ("escrow", "oracle", "insurance")
     * @param newContract New contract address
     */
    function upgradeContract(
        string memory network,
        string memory contractType,
        address newContract
    ) external onlyOwner {
        require(deployments[network].escrowContract != address(0), "Network not deployed");
        require(newContract != address(0), "Invalid new contract address");

        FlowRentDeployment storage deployment = deployments[network];
        address oldContract;

        if (keccak256(bytes(contractType)) == keccak256(bytes("escrow"))) {
            oldContract = deployment.escrowContract;
            deployment.escrowContract = newContract;
        } else if (keccak256(bytes(contractType)) == keccak256(bytes("oracle"))) {
            oldContract = deployment.oracleContract;
            deployment.oracleContract = newContract;
        } else {
            revert("Invalid contract type");
        }

        // Update contract validity
        isFlowRentContract[oldContract] = false;
        isFlowRentContract[newContract] = true;

        emit ContractUpgraded(network, contractType, oldContract, newContract);
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
        
        FlowRentDeployment memory deployment = deployments[network];
        require(deployment.escrowContract != address(0), "Network not deployed");

        FlowRentOracle oracle = FlowRentOracle(deployment.oracleContract);

        // Register initial vehicles
        for (uint256 i = 0; i < vehicleIds.length; i++) {
            oracle.registerVehicle(
                vehicleIds[i],
                carTypes[i],
                trims[i],
                baseRates[i]
            );
        }
    }

    /**
     * @notice Emergency pause for a network deployment
     * @param network Network to pause
     */
    function pauseNetwork(string memory network) external onlyOwner {
        FlowRentDeployment memory deployment = deployments[network];
        require(deployment.escrowContract != address(0), "Network not deployed");

        // Note: This would require pause functionality in the contracts
        // For now, we mark contracts as invalid
        isFlowRentContract[deployment.escrowContract] = false;
        isFlowRentContract[deployment.oracleContract] = false;
    }

    /**
     * @notice Resume a paused network
     * @param network Network to resume
     */
    function resumeNetwork(string memory network) external onlyOwner {
        FlowRentDeployment memory deployment = deployments[network];
        require(deployment.escrowContract != address(0), "Network not deployed");

        // Restore contract validity
        isFlowRentContract[deployment.escrowContract] = true;
        isFlowRentContract[deployment.oracleContract] = true;
    }

    /**
     * @notice Get deployment statistics
     * @return totalNetworks Number of networks deployed
     * @return totalContracts Total contracts deployed
     * @return networks Array of all network names
     */
    function getDeploymentStats() external view returns (
        uint256 totalNetworks,
        uint256 totalContracts,
        string[] memory networks
    ) {
        totalNetworks = deployedNetworks.length;
        totalContracts = totalNetworks * 2; // Each deployment has 2 contracts
        networks = deployedNetworks;
    }

    /**
     * @notice Check deployment health for a network
     * @param network Network to check
     * @return isHealthy Whether all contracts are deployed and valid
     * @return escrowValid Escrow contract validity
     * @return oracleValid Oracle contract validity
     */
    function checkDeploymentHealth(string memory network) external view returns (
        bool isHealthy,
        bool escrowValid,
        bool oracleValid
    ) {
        FlowRentDeployment memory deployment = deployments[network];
        
        escrowValid = deployment.escrowContract != address(0) && isFlowRentContract[deployment.escrowContract];
        oracleValid = deployment.oracleContract != address(0) && isFlowRentContract[deployment.oracleContract];
        
        isHealthy = escrowValid && oracleValid;
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
        
        FlowRentDeployment memory deployment = deployments[network];
        require(deployment.escrowContract != address(0), "Network not deployed");

        FlowRentOracle oracle = FlowRentOracle(deployment.oracleContract);

        // Create pricing data array
        FlowRentOracle.PricingData[] memory pricingData = new FlowRentOracle.PricingData[](vehicleIds.length);
        
        // Populate pricing data array
        for (uint256 i = 0; i < vehicleIds.length; i++) {
            pricingData[i] = FlowRentOracle.PricingData({
                odometer: odometers[i],
                timestamp: timestamps[i],
                lastUpdated: block.timestamp
            });
        }
        
        // Update pricing data in batch
        oracle.batchUpdatePricingData(vehicleIds, pricingData);
    }

    /**
     * Risk telemetry functions removed to simplify the contract
     */

    /**
     * Health telemetry functions removed to simplify the contract
     */

    /**
     * @notice Configure network for LayerZero cross-chain functionality
     * @param network Network identifier
     * @param layerZeroChainId LayerZero chain ID for this network
     * @param isNativePYUSD Whether PYUSD is native on this network
     */
    function configureLayerZeroNetwork(
        string memory network,
        uint16 layerZeroChainId,
        bool isNativePYUSD
    ) external onlyOwner {
        require(bytes(network).length > 0, "Network name required");
        require(layerZeroChainId > 0, "Invalid LayerZero chain ID");
        require(deployments[network].escrowContract != address(0), "Network not deployed");
        
        // Update deployment with LayerZero information
        deployments[network].layerZeroChainId = layerZeroChainId;
        deployments[network].isNativePYUSD = isNativePYUSD;
        
        // Update mappings
        layerZeroChainIdToNetwork[layerZeroChainId] = network;
        networkToLayerZeroChainId[network] = layerZeroChainId;
        
        emit CrossChainNetworkConfigured(network, layerZeroChainId, isNativePYUSD);
    }
    
    /**
     * @notice Deploy PYUSD OFT wrapper for a network that doesn't have native PYUSD
     * @param network Network identifier
     * @param pyusdAddress PYUSD address on the network (if it exists)
     */
    function deployPYUSDOFT(
        string memory network,
        address pyusdAddress
    ) external onlyOwner returns (address oftAddress) {
        require(bytes(network).length > 0, "Network name required");
        require(deployments[network].escrowContract != address(0), "Network not deployed");
        require(deployments[network].layerZeroChainId > 0, "Network not configured for LayerZero");
        require(deployments[network].pyusdOFTWrapper == address(0), "OFT already deployed");
        
        // Deploy OFT wrapper
        FlowRentPYUSDOFT oft = new FlowRentPYUSDOFT(
            layerZeroEndpoint,
            pyusdAddress,
            oftImplementation,
            owner()
        );
        
        oftAddress = address(oft);
        
        // Update deployment
        deployments[network].pyusdOFTWrapper = oftAddress;
        
        emit PYUSDOFTDeployed(deployments[network].layerZeroChainId, oftAddress);
        
        return oftAddress;
    }
    
    /**
     * @notice Initiate cross-chain deployment of FlowRent ecosystem
     * @param sourceNetwork Source network identifier
     * @param targetNetwork Target network identifier
     * @param targetChainId LayerZero chain ID for target network
     * @param pyusdToken PYUSD token address on target chain
     * @param verificationContract ProofOfHumanity contract address on target chain
     * @param version Version identifier for deployment
     * @param gasLimit Gas limit for cross-chain transaction
     */
    // Struct to hold cross-chain deployment data
    struct CrossChainDeployData {
        string sourceNetwork;
        string targetNetwork;
        uint16 targetChainId;
        address pyusdToken;
        address verificationContract;
        address sablierLockupContract;
        string version;
        uint256 gasLimit;
    }
    
    function deployFlowRentCrossChain(
        string memory sourceNetwork,
        string memory targetNetwork,
        uint16 targetChainId,
        address pyusdToken,
        address verificationContract,
        address sablierLockupContract,
        string memory version,
        uint256 gasLimit
    ) external payable onlyOwner {
        CrossChainDeployData memory data = CrossChainDeployData({
            sourceNetwork: sourceNetwork,
            targetNetwork: targetNetwork,
            targetChainId: targetChainId,
            pyusdToken: pyusdToken,
            verificationContract: verificationContract,
            sablierLockupContract: sablierLockupContract,
            version: version,
            gasLimit: gasLimit
        });
        
        _deployFlowRentCrossChain(data);
    }
    
    function _deployFlowRentCrossChain(CrossChainDeployData memory data) internal {
        require(bytes(data.sourceNetwork).length > 0, "Source network name required");
        require(bytes(data.targetNetwork).length > 0, "Target network name required");
        require(deployments[data.sourceNetwork].escrowContract != address(0), "Source network not deployed");
        require(deployments[data.targetNetwork].escrowContract == address(0), "Target network already deployed");
        require(deployments[data.sourceNetwork].layerZeroChainId > 0, "Source network not configured for LayerZero");
        require(data.targetChainId > 0, "Invalid target chain ID");
        require(data.pyusdToken != address(0), "Invalid PYUSD token address");
        require(data.verificationContract != address(0), "Invalid verification contract address");
        
        // Encode deployment parameters
        bytes memory payload = abi.encode(
            data.targetNetwork,
            data.pyusdToken,
            data.verificationContract,
            data.sablierLockupContract,
            data.version
        );
        
        // Process cross-chain deployment
        _processCrossChainDeployment(data, payload);
    }
    
    function _processCrossChainDeployment(
        CrossChainDeployData memory data,
        bytes memory payload
    ) internal {
        // Get LayerZero endpoint
        ILayerZeroEndpoint endpoint = ILayerZeroEndpoint(layerZeroEndpoint);
        
        // Calculate fees
        (uint256 nativeFee, ) = endpoint.estimateFees(
            data.targetChainId,
            address(this),
            payload,
            false,
            bytes("")
        );
        require(msg.value >= nativeFee, "Insufficient fee");
        
        // Send cross-chain message
        endpoint.send{value: msg.value}(
            data.targetChainId,
            abi.encodePacked(address(this)),
            payload,
            payable(msg.sender),
            address(0),
            bytes("")
        );
        
        emit CrossChainDeploymentInitiated(data.sourceNetwork, data.targetNetwork, data.targetChainId);
    }
    
    /**
     * @notice Struct to hold LayerZero received deployment data
     * @dev Used to avoid stack too deep errors
     */
    struct LzReceiveData {
        uint16 srcChainId;
        bytes srcAddress;
        uint64 nonce;
        bytes payload;
        address srcAddr;
    }

    /**
     * @notice Process cross-chain message from LayerZero
     * @param srcChainId Source chain ID
     * @param srcAddress Source address
     * @param nonce Message nonce
     * @param payload Message payload
     */
    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external {
        require(msg.sender == layerZeroEndpoint, "Only LayerZero endpoint can call");
        require(srcAddress.length == 20, "Invalid source address");
        
        // Extract source address
        address srcAddr;
        assembly {
            srcAddr := mload(add(srcAddress, 20))
        }
        
        // Create data struct and process the message
        LzReceiveData memory data = LzReceiveData({
            srcChainId: srcChainId,
            srcAddress: srcAddress,
            nonce: nonce,
            payload: payload,
            srcAddr: srcAddr
        });
        
        _processLzMessage(data);
    }
    
    /**
     * @notice Process received LayerZero message
     * @param data The LayerZero message data
     */
    function _processLzMessage(LzReceiveData memory data) internal {
        // Check if source address is a valid FlowRent factory
        // (In a real deployment, you would check if this is a trusted factory address)
        
        // Decode deployment parameters
        (string memory network, 
         address pyusdToken, 
         address verificationContract,
         address sablierLockupContract,
         string memory version) = abi.decode(data.payload, (string, address, address, address, string));
        
        // Deploy FlowRent on this chain
        this.deployFlowRent(network, pyusdToken, verificationContract, sablierLockupContract, version);
        
        emit CrossChainDeploymentReceived(data.srcChainId, data.payload);
    }
    
    /**
     * @notice Struct for cross-chain rental parameters
     * @dev Used to avoid stack too deep errors in initiateRentalCrossChain
     */
    struct CrossChainRentalParams {
        string sourceNetwork;
        string targetNetwork;
        uint256 vehicleId;
        address renter;
        uint256 amount;
    }
    
    /**
     * @notice Initiate cross-chain rental
     * @param sourceNetwork Source network identifier
     * @param targetNetwork Target network identifier
     * @param vehicleId Vehicle ID
     * @param renter Renter address
     * @param amount Amount of PYUSD to send
     * @param gasLimit Gas limit for cross-chain transaction (unused but kept for API compatibility)
     */
    function initiateRentalCrossChain(
        string memory sourceNetwork,
        string memory targetNetwork,
        uint256 vehicleId,
        address renter,
        uint256 amount,
        uint256 gasLimit
    ) external payable {
        // Create a params struct to avoid stack too deep errors
        CrossChainRentalParams memory params = CrossChainRentalParams({
            sourceNetwork: sourceNetwork,
            targetNetwork: targetNetwork,
            vehicleId: vehicleId,
            renter: renter,
            amount: amount
        });
        
        // Process the cross-chain rental
        _processCrossChainRental(params);
    }
    
    /**
     * @notice Process cross-chain rental
     * @param params Cross-chain rental parameters
     */
    function _processCrossChainRental(CrossChainRentalParams memory params) internal {
        require(bytes(params.sourceNetwork).length > 0, "Source network name required");
        require(bytes(params.targetNetwork).length > 0, "Target network name required");
        require(deployments[params.sourceNetwork].escrowContract != address(0), "Source network not deployed");
        require(deployments[params.targetNetwork].escrowContract != address(0), "Target network not deployed");
        
        uint16 targetChainId = networkToLayerZeroChainId[params.targetNetwork];
        require(targetChainId > 0, "Target network not configured for LayerZero");
        
        // Transfer PYUSD to OFT wrapper first (approval required before calling this function)
        address oftWrapper = deployments[params.sourceNetwork].pyusdOFTWrapper;
        require(oftWrapper != address(0), "OFT wrapper not deployed");
        
        // Send tokens cross-chain
        FlowRentPYUSDOFT(payable(oftWrapper)).sendTokens{value: msg.value}(
            targetChainId,
            abi.encodePacked(deployments[params.targetNetwork].escrowContract),
            params.amount,
            payable(msg.sender),
            params.renter,
            params.vehicleId
        );
        
        emit CrossChainRentalInitiated(targetChainId, params.vehicleId, params.renter);
    }
}
