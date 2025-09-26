// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOFT.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

/**
 * @title FlowRentPYUSDOFT
 * @notice Wrapper for PYUSD token with LayerZero OFT functionality for cross-chain operations
 * @dev Manages bridging PYUSD across different chains for the FlowRent ecosystem
 */
contract FlowRentPYUSDOFT is Ownable {
    // LayerZero endpoint interface
    ILayerZeroEndpoint public immutable lzEndpoint;
    
    // Source PYUSD token (might be wrapped on some chains)
    IERC20 public immutable pyusdToken;
    
    // OFT implementation (if the PYUSD is not an OFT itself)
    IOFT public immutable oftImplementation;
    
    // Chain ID mappings (LayerZero chain ID to name)
    mapping(uint16 => string) public chainIdToName;
    
    // PYUSD deployment addresses on different chains
    mapping(uint16 => address) public pyusdOnChain;
    
    // Whether a chain's PYUSD is native or bridged
    mapping(uint16 => bool) public isNativePYUSD;
    
    // Gas limit for cross-chain operations
    mapping(uint16 => uint256) public gasLimits;
    
    // Events
    event TokensBridged(
        address indexed sender,
        uint16 indexed dstChainId,
        address indexed recipient,
        uint256 amount,
        uint256 fee
    );
    event ChainConfigured(uint16 indexed chainId, string name, address pyusdAddress, bool isNative);
    event RentalPaymentSent(
        address indexed sender,
        uint16 indexed dstChainId,
        address indexed escrow,
        uint256 amount,
        uint256 vehicleId,
        address renter
    );
    event RentalPaymentReceived(
        uint16 indexed srcChainId,
        address indexed recipient,
        uint256 amount,
        uint256 vehicleId,
        address renter
    );
    
    constructor(
        address _lzEndpoint,
        address _pyusdToken,
        address _oftImplementation,
        address _owner
    ) Ownable(_owner) {
        require(_lzEndpoint != address(0), "Invalid LZ endpoint");
        require(_pyusdToken != address(0), "Invalid PYUSD token");
        require(_oftImplementation != address(0), "Invalid OFT implementation");
        
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        pyusdToken = IERC20(_pyusdToken);
        oftImplementation = IOFT(_oftImplementation);
        
        // Configure local chain
        uint16 localChainId = lzEndpoint.getChainId();
        isNativePYUSD[localChainId] = true;
        pyusdOnChain[localChainId] = _pyusdToken;
        gasLimits[localChainId] = 200000; // Default gas limit
    }
    
    /**
     * @notice Configure chain details for cross-chain operations
     * @param chainId LayerZero chain ID
     * @param name Chain name
     * @param pyusdAddress PYUSD address on that chain
     * @param isNative Whether PYUSD is native on that chain
     * @param gasLimit Gas limit for transactions to that chain
     */
    function configureChain(
        uint16 chainId,
        string memory name,
        address pyusdAddress,
        bool isNative,
        uint256 gasLimit
    ) external onlyOwner {
        require(bytes(name).length > 0, "Chain name required");
        require(pyusdAddress != address(0), "Invalid PYUSD address");
        require(gasLimit > 0, "Gas limit must be positive");
        
        chainIdToName[chainId] = name;
        pyusdOnChain[chainId] = pyusdAddress;
        isNativePYUSD[chainId] = isNative;
        gasLimits[chainId] = gasLimit;
        
        // Set trusted remote for OFT if this is an OFT implementation
        if (!isNative) {
            bytes memory remoteAddress = abi.encodePacked(pyusdAddress, address(this));
            oftImplementation.setTrustedRemoteAddress(chainId, remoteAddress);
        }
        
        emit ChainConfigured(chainId, name, pyusdAddress, isNative);
    }
    
    /**
     * @notice Bridge PYUSD from this chain to another chain
     * @param dstChainId Destination LayerZero chain ID
     * @param recipient Recipient address on destination chain
     * @param amount Amount of PYUSD to bridge
     */
    function bridgePYUSD(
        uint16 dstChainId,
        address recipient,
        uint256 amount
    ) external payable {
        require(pyusdOnChain[dstChainId] != address(0), "Destination chain not configured");
        require(amount > 0, "Amount must be positive");
        
        // Transfer tokens from sender to this contract
        require(
            pyusdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer to contract failed"
        );
        
        // If destination has native PYUSD, bridge via OFT
        bytes memory recipientBytes = abi.encodePacked(recipient);
        bytes memory adapterParams = abi.encodePacked(uint16(1), gasLimits[dstChainId]);
        
        // Estimate fee
        (uint256 nativeFee, ) = oftImplementation.estimateSendFee(
            dstChainId,
            recipientBytes,
            amount,
            false,
            adapterParams
        );
        
        require(msg.value >= nativeFee, "Insufficient fee");
        
        // Approve OFT to spend tokens
        pyusdToken.approve(address(oftImplementation), amount);
        
        // Bridge tokens
        oftImplementation.sendFrom{value: msg.value}(
            address(this),
            dstChainId,
            recipientBytes,
            amount,
            payable(msg.sender), // refund address
            address(0), // zro payment address (not using ZRO tokens)
            adapterParams
        );
        
        emit TokensBridged(msg.sender, dstChainId, recipient, amount, nativeFee);
    }
    
    /**
     * @notice Estimate fee for bridging PYUSD to another chain
     * @param dstChainId Destination LayerZero chain ID
     * @param amount Amount of PYUSD to bridge
     * @return fee Required fee in native gas token
     */
    function estimateBridgeFee(
        uint16 dstChainId,
        uint256 amount
    ) external view returns (uint256 fee) {
        require(pyusdOnChain[dstChainId] != address(0), "Destination chain not configured");
        
        bytes memory dummyAddress = abi.encodePacked(address(0x1));
        bytes memory adapterParams = abi.encodePacked(uint16(1), gasLimits[dstChainId]);
        
        (uint256 nativeFee, ) = oftImplementation.estimateSendFee(
            dstChainId,
            dummyAddress,
            amount,
            false,
            adapterParams
        );
        
        return nativeFee;
    }
    
    /**
     * @notice Update gas limit for a chain
     * @param chainId LayerZero chain ID
     * @param gasLimit New gas limit
     */
    function updateGasLimit(uint16 chainId, uint256 gasLimit) external onlyOwner {
        require(gasLimit > 0, "Gas limit must be positive");
        gasLimits[chainId] = gasLimit;
    }
    
    /**
     * @notice Emergency withdrawal of stuck funds
     * @param token Token address (address(0) for native tokens)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = owner().call{value: amount}("");
            require(success, "Native token withdrawal failed");
        } else {
            require(
                IERC20(token).transfer(owner(), amount),
                "Token withdrawal failed"
            );
        }
    }
    
    // Removed struct definition to flatten the call stack

    /**
     * @notice Send tokens for cross-chain rental payment (minimal version)
     * @param dstChainId Destination LayerZero chain ID
     * @param recipient Recipient address on destination chain (Escrow)
     * @param amount Amount of PYUSD to send
     * @param refundAddress Address to refund excess fees
     * @param renter Renter address
     * @param vehicleId Vehicle/asset ID
     */
    function sendTokens(
        uint16 dstChainId,
        bytes memory recipient,
        uint256 amount,
        address payable refundAddress,
        address renter,
        uint256 vehicleId
    ) external payable {
        // Basic validations
        require(pyusdOnChain[dstChainId] != address(0), "Destination chain not configured");
        require(amount > 0, "Amount must be positive");
        
        // Transfer tokens to this contract
        require(
            pyusdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer to contract failed"
        );
        
        // Simple adapter params
        bytes memory adapterParams = abi.encodePacked(uint16(1), gasLimits[dstChainId]);
        
        // Split implementation into two functions to reduce stack depth
        if (!isNativePYUSD[dstChainId]) {
            _sendViaOFT(dstChainId, recipient, amount, refundAddress, adapterParams);
        } else {
            _sendViaLZ(dstChainId, recipient, amount, refundAddress, renter, vehicleId, adapterParams);
        }
        
        // Emit event without extracting recipient address to reduce stack depth
        emit RentalPaymentSent(
            msg.sender,
            dstChainId,
            address(0), // Use placeholder address to avoid complex assembly
            amount,
            vehicleId,
            renter
        );
    }
    
    /**
     * @notice Helper function for OFT transfers
     */
    function _sendViaOFT(
        uint16 dstChainId,
        bytes memory recipient,
        uint256 amount,
        address payable refundAddress,
        bytes memory adapterParams
    ) internal {
        // Approve OFT for transfer
        pyusdToken.approve(address(oftImplementation), amount);
        
        // Use OFT to bridge
        oftImplementation.sendFrom{value: msg.value}(
            address(this),
            dstChainId,
            recipient,
            amount,
            refundAddress,
            address(0),
            adapterParams
        );
    }
    
    /**
     * @notice Helper function for LayerZero transfers
     */
    function _sendViaLZ(
        uint16 dstChainId,
        bytes memory recipient,
        uint256 amount,
        address payable refundAddress,
        address renter,
        uint256 vehicleId,
        bytes memory adapterParams
    ) internal {
        // Simple payload
        bytes memory payload = abi.encode(renter, amount, vehicleId);
        
        // Send LZ message
        lzEndpoint.send{value: msg.value}(
            dstChainId,
            recipient,
            payload,
            refundAddress,
            address(0),
            adapterParams
        );
    }
    
    // Removed helper function to reduce bytecode size
    
    /**
     * @notice Process received tokens from another chain
     * @param srcChainId Source chain ID
     * @param srcAddress Source address
     * @param nonce Message nonce
     * @param payload Message payload with rental info
     */
    function receiveTokens(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external {
        require(msg.sender == address(lzEndpoint), "Only LZ endpoint can call");
        
        // Decode payload directly
        (address renter, uint256 amount, uint256 vehicleId) = abi.decode(
            payload,
            (address, uint256, uint256)
        );
        
        // Extract source address
        address srcAddr;
        assembly {
            srcAddr := mload(add(srcAddress, 20))
        }
        
        // Process tokens on receiving chain - for demo purposes
        // If we're receiving tokens on a chain where PYUSD is native
        if (isNativePYUSD[srcChainId]) {
            // Mint or transfer PYUSD to the renter
            // This would require integration with the PYUSD contract
            // For demo purposes, we'll just emit an event
        }
        
        // Emit event directly
        emit RentalPaymentReceived(
            srcChainId,
            srcAddr,
            amount,
            vehicleId,
            renter
        );
    }
    
    // Allow contract to receive native tokens for gas
    receive() external payable {}
}
