// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowRentFactoryCore.sol";
import "./FlowRentOracle.sol";
import "./FlowRentPYUSDOFT.sol";
import "./FlowRentRegistry.sol"; // Add registry import
import "./interfaces/IOFT.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

/**
 * @title FlowRentFactoryExtension
 * @notice Extension for FlowRentFactory with cross-chain functionality
 * @dev Separates cross-chain logic to reduce contract size
 */
contract FlowRentFactoryExtension is Ownable {
    // Core factory reference
    FlowRentFactoryCore public immutable factoryCore;
    
    // Cross-chain deployment mappings
    mapping(uint16 => string) public layerZeroChainIdToNetwork;  // LZ chain ID to network name
    mapping(string => uint16) public networkToLayerZeroChainId;  // network name to LZ chain ID
    mapping(string => address) public networkToPYUSDOFT;         // network name to PYUSD OFT wrapper
    mapping(string => bool) public networkIsNativePYUSD;         // network has native PYUSD
    
    // Events
    event CrossChainNetworkConfigured(string network, uint16 layerZeroChainId, bool isNativePYUSD);
    event CrossChainDeploymentInitiated(string sourceNetwork, string targetNetwork, uint16 targetChainId);
    event CrossChainDeploymentReceived(uint16 indexed srcChainId, bytes payload);
    event PYUSDOFTDeployed(uint16 indexed chainId, address indexed oftAddress);
    event CrossChainRentalInitiated(uint16 indexed dstChainId, uint256 vehicleId, address renter);
    event CrossChainPaymentProcessed(uint16 indexed srcChainId, uint256 vehicleId, uint256 amount);

    constructor(
        address _factoryCore,
        address _owner
    ) Ownable(_owner) {
        require(_factoryCore != address(0), "Invalid factory core");
        factoryCore = FlowRentFactoryCore(_factoryCore);
    }

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
        
        // Get deployment from core factory to verify it exists
        (address escrow,,,,) = getDeploymentInfo(network);
        require(escrow != address(0), "Network not deployed");
        
        // Update mappings
        layerZeroChainIdToNetwork[layerZeroChainId] = network;
        networkToLayerZeroChainId[network] = layerZeroChainId;
        networkIsNativePYUSD[network] = isNativePYUSD;
        
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
        
        // Get deployment from core factory to verify it exists
        (address escrow,,,,) = getDeploymentInfo(network);
        require(escrow != address(0), "Network not deployed");
        
        require(networkToLayerZeroChainId[network] > 0, "Network not configured for LayerZero");
        require(networkToPYUSDOFT[network] == address(0), "OFT already deployed");
        
        // Get the LayerZero endpoint address from core factory
        address layerZeroEndpoint = factoryCore.layerZeroEndpoint();
        address oftImplementation = factoryCore.oftImplementation();
        
        // Deploy OFT wrapper
        FlowRentPYUSDOFT oft = new FlowRentPYUSDOFT(
            layerZeroEndpoint,
            pyusdAddress,
            oftImplementation,
            owner()
        );
        
        oftAddress = address(oft);
        
        // Update mappings
        networkToPYUSDOFT[network] = oftAddress;
        
        emit PYUSDOFTDeployed(networkToLayerZeroChainId[network], oftAddress);
        
        return oftAddress;
    }
    
    /**
     * @notice Struct to hold cross-chain deployment data
     * @dev Used to avoid stack too deep errors
     */
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
    
    /**
     * @notice Internal function to process cross-chain deployment
     */
    function _deployFlowRentCrossChain(CrossChainDeployData memory data) internal {
        require(bytes(data.sourceNetwork).length > 0, "Source network name required");
        require(bytes(data.targetNetwork).length > 0, "Target network name required");
        
        // Get deployment from core factory to verify source network exists
        (address sourceEscrow,,,,) = getDeploymentInfo(data.sourceNetwork);
        require(sourceEscrow != address(0), "Source network not deployed");
        
        // Get deployment from core factory to verify target network doesn't exist
        (address targetEscrow,,,,) = getDeploymentInfo(data.targetNetwork);
        require(targetEscrow == address(0), "Target network already deployed");
        
        // Verify source network is configured for LayerZero
        require(networkToLayerZeroChainId[data.sourceNetwork] > 0, "Source network not configured for LayerZero");
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
    
    /**
     * @notice Process the cross-chain deployment message
     */
    function _processCrossChainDeployment(
        CrossChainDeployData memory data,
        bytes memory payload
    ) internal {
        // Get LayerZero endpoint
        address lzEndpoint = factoryCore.layerZeroEndpoint();
        ILayerZeroEndpoint endpoint = ILayerZeroEndpoint(lzEndpoint);
        
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
        require(msg.sender == factoryCore.layerZeroEndpoint(), "Only LayerZero endpoint can call");
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
        
        // Deploy FlowRent on this chain using the core factory
        factoryCore.deployFlowRent(network, pyusdToken, verificationContract, sablierLockupContract, version);
        
        emit CrossChainDeploymentReceived(data.srcChainId, data.payload);
    }
    
    /**
     * @notice Struct for cross-chain rental parameters
     * @dev Used to avoid stack too deep errors
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
        
        // Get deployment from core factory to verify networks exist
        (address sourceEscrow,,,,) = getDeploymentInfo(params.sourceNetwork);
        (address targetEscrow,,,,) = getDeploymentInfo(params.targetNetwork);
        
        require(sourceEscrow != address(0), "Source network not deployed");
        require(targetEscrow != address(0), "Target network not deployed");
        
        uint16 targetChainId = networkToLayerZeroChainId[params.targetNetwork];
        require(targetChainId > 0, "Target network not configured for LayerZero");
        
        // Transfer PYUSD to OFT wrapper first (approval required before calling this function)
        address oftWrapper = networkToPYUSDOFT[params.sourceNetwork];
        require(oftWrapper != address(0), "OFT wrapper not deployed");
        
        // Send tokens cross-chain
        FlowRentPYUSDOFT(payable(oftWrapper)).sendTokens{value: msg.value}(
            targetChainId,
            abi.encodePacked(targetEscrow),
            params.amount,
            payable(msg.sender),
            params.renter,
            params.vehicleId
        );
        
        emit CrossChainRentalInitiated(targetChainId, params.vehicleId, params.renter);
    }
    
    /**
     * @notice Helper to get deployment info from core factory
     */
    function getDeploymentInfo(string memory network) public view returns (
        address escrow,
        address oracle,
        address pyusd,
        address verification,
        uint256 deploymentBlock
    ) {
        // The deployment struct is now in the registry, but accessed through the factoryCore
        (escrow, oracle, pyusd, verification, deploymentBlock, ) = factoryCore.getDeployment(network);
        return (escrow, oracle, pyusd, verification, deploymentBlock);
    }
}
