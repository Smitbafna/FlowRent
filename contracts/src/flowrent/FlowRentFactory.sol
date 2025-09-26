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
