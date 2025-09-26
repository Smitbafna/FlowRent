// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/IOFT.sol";
import "../../lib/v2-core/src/interfaces/ISablierLockup.sol";
import "../../lib/v2-core/src/types/DataTypes.sol";
import "@prb/math/src/UD60x18.sol";

/**
 * @title FlowRentPYUSDSablier
 * @notice Cross-chain PYUSD handler using Sablier for streaming payments
 * @dev Uses LayerZero, PYUSD OFT, and Sablier v2 for cross-chain rental payments with token streaming
 */
contract FlowRentPYUSDSablier is Ownable {

    // PYUSD token contract
    IERC20 public immutable pyusdToken;
    
    // OFT implementation for PYUSD
    IOFT public immutable oftImplementation;
    
    // LayerZero endpoint for cross-chain messaging
    ILayerZeroEndpoint public immutable lzEndpoint;

    // Sablier V2 Lockup contract
    ISablierLockup public immutable sablier;
    
    // Chain configuration data
    mapping(uint16 => string) public chainIdToName;       // LayerZero chain ID => Chain name
    mapping(uint16 => address) public pyusdOnChain;       // LayerZero chain ID => PYUSD address
    mapping(uint16 => bool) public isNativePYUSD;         // LayerZero chain ID => Is PYUSD native on that chain
    mapping(uint16 => uint256) public gasLimits;          // LayerZero chain ID => Gas limit for LZ messages
    
    // Mapping to track Sablier streams
    mapping(bytes32 => uint256) public rentalToStreamId;  // rentalId => Sablier stream ID
    
    // Events
    event ChainConfigured(uint16 indexed chainId, string name, address pyusdAddress, bool isNative);
    event RentalPaymentSent(address indexed sender, uint16 indexed dstChainId, address indexed recipient, uint256 amount, uint256 vehicleId, address renter);
    event RentalPaymentReceived(uint16 indexed srcChainId, address indexed sender, uint256 amount, uint256 vehicleId, address renter);
    event StreamCreated(bytes32 indexed rentalId, uint256 indexed streamId, address recipient, uint256 amount, uint256 startTime, uint256 endTime);
    
    constructor(
        address _pyusdToken,
        address _oftImplementation,
        address _lzEndpoint,
        address _sablier,
        address _owner
    ) Ownable(_owner) {
        require(_pyusdToken != address(0), "Invalid PYUSD token address");
        require(_oftImplementation != address(0), "Invalid OFT address");
        require(_lzEndpoint != address(0), "Invalid LZ endpoint address");
        require(_sablier != address(0), "Invalid Sablier address");
        
        pyusdToken = IERC20(_pyusdToken);
        oftImplementation = IOFT(_oftImplementation);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        sablier = ISablierLockup(_sablier);
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
     * @notice Send tokens for cross-chain rental payment and create Sablier stream
     * @param dstChainId Destination LayerZero chain ID
     * @param recipient Recipient address on destination chain (Escrow)
     * @param amount Amount of PYUSD to send
     * @param refundAddress Address to refund excess fees
     * @param renter Renter address
     * @param vehicleId Vehicle/asset ID
     * @param streamDuration Duration of the Sablier stream in seconds
     */
    function sendTokens(
        uint16 dstChainId,
        bytes memory recipient,
        uint256 amount,
        address payable refundAddress,
        address renter,
        uint256 vehicleId,
        uint256 streamDuration
    ) external payable {
        // Basic validations
        require(pyusdOnChain[dstChainId] != address(0), "Destination chain not configured");
        require(amount > 0, "Amount must be positive");
        
        // Transfer tokens to this contract
        require(
            pyusdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer to contract failed"
        );
        
        // Extract recipient address for the event and stream creation
        address recipientAddr;
        assembly {
            recipientAddr := mload(add(recipient, 20))
        }
        
        // Create rental ID
        bytes32 rentalId = keccak256(abi.encodePacked(vehicleId, renter, block.timestamp));

        // Create a Sablier stream
        // First, approve Sablier to spend tokens
        pyusdToken.approve(address(sablier), amount);
        
        // Then create the stream
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp + streamDuration;

        // Create linear stream parameters
        Lockup.CreateWithDurations memory streamParams = Lockup.CreateWithDurations({
            sender: address(this),
            recipient: recipientAddr,
            totalAmount: uint128(amount),
            token: pyusdToken,
            cancelable: true,
            transferable: true,
            shape: "",
            broker: Broker({
                account: address(0),
                fee: UD60x18.wrap(0) // 0%
            })
        });
        
        LockupLinear.Durations memory durations = LockupLinear.Durations({
            cliff: 0, // No cliff
            total: uint40(streamDuration)
        });
        
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({
            start: 0, // No initial unlock
            cliff: 0  // No cliff unlock
        });
            
        // Create the stream
        uint256 streamId = sablier.createWithDurationsLL(streamParams, unlockAmounts, durations);
        
        // Store the stream ID
        rentalToStreamId[rentalId] = streamId;
        
        emit StreamCreated(rentalId, streamId, recipientAddr, amount, startTime, endTime);
        
        // Simple adapter params for LayerZero
        bytes memory adapterParams = abi.encodePacked(uint16(1), gasLimits[dstChainId]);
        
        // Send LayerZero message with rental info
        bytes memory payload = abi.encode(renter, amount, vehicleId, streamId);
            
        lzEndpoint.send{value: msg.value}(
            dstChainId,
            recipient,
            payload,
            refundAddress,
            address(0),
            adapterParams
        );
        
        emit RentalPaymentSent(
            msg.sender,
            dstChainId,
            recipientAddr,
            amount,
            vehicleId,
            renter
        );
    }

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
        
        // Decode payload
        (address renter, uint256 amount, uint256 vehicleId, uint256 streamId) = abi.decode(
            payload,
            (address, uint256, uint256, uint256)
        );
        
        // Extract source address
        address srcAddr;
        assembly {
            srcAddr := mload(add(srcAddress, 20))
        }
        
        emit RentalPaymentReceived(
            srcChainId,
            srcAddr,
            amount,
            vehicleId,
            renter
        );
    }
    
    /**
     * @notice Get stream details for a rental
     * @param rentalId The rental identifier
     * @return streamId The Sablier stream ID
     */
    function getStreamId(bytes32 rentalId) external view returns (uint256 streamId) {
        return rentalToStreamId[rentalId];
    }
    
    /**
     * @notice Cancel an active stream
     * @param rentalId The rental identifier
     */
    function cancelStream(bytes32 rentalId) external onlyOwner {
        uint256 streamId = rentalToStreamId[rentalId];
        require(streamId > 0, "Stream does not exist");
        
        // Cancel the stream - using cancel method from the ISablierLockupBase interface
        // which is inherited by ISablierLockup
        sablier.cancel(streamId);
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
    
    // Allow contract to receive native tokens for gas
    receive() external payable {}
}
