// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./FlowRentOracle.sol";
import "../../lib/v2-core/src/interfaces/ISablierLockup.sol";
import "../../lib/v2-core/src/types/DataTypes.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

interface IProofOfHumanReceiver {
    function isUserVerified(address userAddress) external view returns (bool verified, uint32 sourceChain, uint256 timestamp);
    function isVerificationValid(address userAddress, uint256 maxAge) external view returns (bool valid);
}

/**
 * @title FlowRentEscrow
 * @notice Secure escrow contract for FlowRent micropayment streaming and rental management
 * @dev Handles PYUSD deposits, real-time streaming, insurance, and rental lifecycle
 */
contract FlowRentEscrow is Ownable, ReentrancyGuard {
    // PYUSD token contract address (Arbitrum)
    IERC20 public immutable pyusdToken;
    
    // Self Protocol verification contract
    IProofOfHumanReceiver public immutable verificationContract;
    
    // Sablier V2 Lockup contract for streaming payments
    ISablierLockup public immutable sablierContract;
    
    // Verification validity period (24 hours)
    uint256 public constant VERIFICATION_MAX_AGE = 24 hours;
    
    // Basis points constant for calculations
    uint256 public constant BASIS_POINTS = 10000;

    // Minimum payout interval (settle in whole minutes to avoid per-second triggers)
    uint256 public constant MIN_PAYOUT_INTERVAL = 1 minutes;

    // Rental status enumeration
    enum RentalStatus { 
        None,           // 0 - No rental exists
        Active,         // 1 - Rental is ongoing
        Completed,      // 2 - Rental completed successfully
        Cancelled,      // 3 - Rental cancelled
        Disputed        // 4 - Rental in dispute
    }

    // Core rental data structure
    struct Rental {
        address renter;                 // User who rented the asset
        address owner;                  // Asset owner
        uint256 assetId;               // Unique asset identifier
        uint256 depositAmount;         // Total PYUSD deposited
        uint256 baseRate;              // Base payment rate per second
        uint256 currentRate;           // Current adjusted rate
        uint256 startTime;             // Rental start timestamp
        uint256 endTime;               // Rental end timestamp (0 if ongoing)
        uint256 totalStreamed;         // Total PYUSD streamed to owner
        uint256 lastStreamTime;        // Last micropayment timestamp
        RentalStatus status;           // Current rental status
        string metadataURI;            // IPFS/metadata URI for rental details
        bytes32 vehicleId;             // Telemetry vehicle ID for Oracle
        uint256 startOdometer;         // Starting odometer reading
        uint256 endOdometer;           // Ending odometer reading
    }

    // Asset information structure
    struct Asset {
        address owner;                 // Asset owner address
        uint256 baseRate;              // Default rate per second
        bool isActive;                 // Asset availability
        string name;                   // Asset name/description
        uint256 minDeposit;            // Minimum required deposit
        uint256 maxRentalDuration;     // Maximum rental duration in seconds
        bytes32 vehicleId;             // Telemetry vehicle ID for Oracle
    }

    // Core mappings
    mapping(bytes32 => Rental) public rentals;           // rentalId => Rental
    mapping(uint256 => Asset) public assets;             // assetId => Asset
    mapping(address => uint256[]) public userRentals;    // user => rentalIds array
    mapping(address => uint256[]) public ownerAssets;    // owner => assetIds array
    mapping(bytes32 => bool) public activeRentals;       // rentalId => isActive
    mapping(bytes32 => uint256) public rentalToStreamId; // rentalId => Sablier stream ID

    // Statistics
    uint256 public totalRentals;
    uint256 public totalAssets;
    uint256 public totalValueLocked;  // Total PYUSD in escrow
    
    // Events
    event AssetRegistered(uint256 indexed assetId, address indexed owner, uint256 baseRate);
    event RentalStarted(bytes32 indexed rentalId, address indexed renter, uint256 indexed assetId, uint256 depositAmount);
    event MicropaymentStreamed(bytes32 indexed rentalId, uint256 amount, uint256 timestamp);
    event RateAdjusted(bytes32 indexed rentalId, uint256 oldRate, uint256 newRate, string reason);
    event RentalCompleted(bytes32 indexed rentalId, uint256 totalPaid, uint256 refundAmount);
    event RentalCancelled(bytes32 indexed rentalId, address indexed cancelledBy, string reason);
    event DepositRefunded(bytes32 indexed rentalId, address indexed renter, uint256 refundAmount);
    event CrossChainPaymentReceived(bytes32 indexed rentalId, address indexed renter, uint256 amount, uint16 srcChainId);
    event CrossChainRefundInitiated(bytes32 indexed rentalId, address indexed renter, uint256 amount, uint16 dstChainId);
    event SablierStreamCreated(bytes32 indexed rentalId, uint256 indexed streamId, uint256 amount, uint256 duration);

    constructor(
        address _pyusdToken,
        address _verificationContract,
        address _sablierContract,
        address _owner
    ) Ownable(_owner) {
        require(_pyusdToken != address(0), "Invalid PYUSD token address");
        require(_verificationContract != address(0), "Invalid verification contract");
        require(_sablierContract != address(0), "Invalid Sablier contract address");
        
        pyusdToken = IERC20(_pyusdToken);
        verificationContract = IProofOfHumanReceiver(_verificationContract);
        sablierContract = ISablierLockup(_sablierContract);
    }

    /**
     * @notice Register a new asset for rental
     * @param assetId Unique identifier for the asset
     * @param baseRate Base payment rate per second in PYUSD
     * @param name Asset name/description
     * @param minDeposit Minimum deposit required
     * @param maxDuration Maximum rental duration
     * @param vehicleId Telemetry vehicle ID for Oracle
     */
    function registerAsset(
        uint256 assetId,
        uint256 baseRate,
        string memory name,
        uint256 minDeposit,
        uint256 maxDuration,
        bytes32 vehicleId
    ) external {
        require(assets[assetId].owner == address(0), "Asset already registered");
        require(baseRate > 0, "Base rate must be positive");
        require(minDeposit > 0, "Minimum deposit must be positive");

        assets[assetId] = Asset({
            owner: msg.sender,
            baseRate: baseRate,
            isActive: true,
            name: name,
            minDeposit: minDeposit,
            maxRentalDuration: maxDuration,
            vehicleId: vehicleId
        });

        ownerAssets[msg.sender].push(assetId);
        totalAssets++;

        emit AssetRegistered(assetId, msg.sender, baseRate);
    }

    /**
     * @notice Start a rental with PYUSD deposit
     * @param assetId Asset to rent
     * @param depositAmount PYUSD amount to deposit
     * @param expectedDuration Expected rental duration in seconds
     */
    function startRental(
        uint256 assetId,
        uint256 depositAmount,
        uint256 expectedDuration
    ) external nonReentrant {
        // Verify user is authenticated via Self Protocol
        require(
            verificationContract.isVerificationValid(msg.sender, VERIFICATION_MAX_AGE),
            "User verification required or expired"
        );

        Asset storage asset = assets[assetId];
        require(asset.owner != address(0), "Asset does not exist");
        require(asset.isActive, "Asset not available");
        require(asset.owner != msg.sender, "Cannot rent own asset");
        require(depositAmount >= asset.minDeposit, "Insufficient deposit");
        
        if (asset.maxRentalDuration > 0) {
            require(expectedDuration <= asset.maxRentalDuration, "Duration exceeds maximum");
        }

        // Generate unique rental ID
        bytes32 rentalId = keccak256(abi.encodePacked(
            msg.sender,
            assetId,
            block.timestamp,
            totalRentals
        ));

        require(!activeRentals[rentalId], "Rental ID collision");

        // Transfer PYUSD deposit to contract
         require(
             pyusdToken.transferFrom(msg.sender, address(this), depositAmount),
             "PYUSD transfer failed"
         );

        // Create rental record
         rentals[rentalId] = Rental({
             renter: msg.sender,
             owner: asset.owner,
             assetId: assetId,
             depositAmount: depositAmount,
             baseRate: asset.baseRate,
             currentRate: asset.baseRate,
             startTime: block.timestamp,
             endTime: 0,
             totalStreamed: 0,
             lastStreamTime: block.timestamp,
             status: RentalStatus.Active,
             metadataURI: "",
             vehicleId: asset.vehicleId,
             startOdometer: 0, // Will be updated separately
             endOdometer: 0    // Will be updated at end of rental
         });

         // Update tracking
         activeRentals[rentalId] = true;
         userRentals[msg.sender].push(totalRentals);
         totalRentals++;
        totalValueLocked = totalValueLocked + depositAmount;

         emit RentalStarted(rentalId, msg.sender, assetId, depositAmount);
    }

    /**
     * @notice Get the Sablier stream status for a rental
     * @param rentalId The rental ID to query
     * @return streamId The Sablier stream ID
     * @return streamed Amount streamed so far
     * @return remaining Amount remaining in the stream
     * @return isActive Whether the stream is active
     */
    function getStreamStatus(bytes32 rentalId) external view returns (
        uint256 streamId,
        uint256 streamed,
        uint256 remaining,
        bool isActive
    ) {
        streamId = rentalToStreamId[rentalId];
        
        if (streamId > 0) {
            // Use sablier's methods to get the stream information
            streamed = sablierContract.getWithdrawnAmount(streamId);
            uint128 depositedAmount = sablierContract.getDepositedAmount(streamId);
            remaining = depositedAmount - streamed;
            
            bool isDepleted = sablierContract.isDepleted(streamId);
            bool wasCanceled = sablierContract.wasCanceled(streamId);
            isActive = !isDepleted && !wasCanceled;
        }
        
        return (streamId, streamed, remaining, isActive);
    }
    
    /**
     * @notice Process micropayment streaming for active rental using Sablier
     * @param rentalId The rental to process payment for
     */
    function streamMicropayment(bytes32 rentalId) public {
        Rental storage rental = rentals[rentalId];
        require(rental.status == RentalStatus.Active, "Rental not active");

        // Check if a Sablier stream already exists for this rental
        uint256 streamId = rentalToStreamId[rentalId];
        
        if (streamId == 0) {
            // No stream exists yet, create one
            uint256 availableAmount = rental.depositAmount - rental.totalStreamed;
            require(availableAmount > 0, "No funds available for streaming");
            
            // Calculate duration based on rate
            uint256 remainingDuration = 0;
            if (rental.currentRate > 0) {
                remainingDuration = availableAmount / rental.currentRate;
            }
            
            require(remainingDuration > 0, "Duration too short for streaming");
            
            // Approve Sablier to use PYUSD
            require(
                pyusdToken.approve(address(sablierContract), availableAmount),
                "Approval for Sablier failed"
            );
            
            // Create a linear stream with Sablier
            Lockup.CreateWithDurations memory streamParams = Lockup.CreateWithDurations({
                sender: address(this),
                recipient: rental.owner,
                totalAmount: uint128(availableAmount),
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
                total: uint40(remainingDuration)
            });
            
            LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({
                start: 0, // No initial unlock
                cliff: 0  // No cliff unlock
            });
                
            // Create the stream
            streamId = sablierContract.createWithDurationsLL(streamParams, unlockAmounts, durations);
            
            // Store the stream ID
            rentalToStreamId[rentalId] = streamId;
            
            // Update rental details
            rental.totalStreamed = availableAmount;
            rental.lastStreamTime = block.timestamp;
            
            emit SablierStreamCreated(rentalId, streamId, availableAmount, remainingDuration);
            emit MicropaymentStreamed(rentalId, availableAmount, block.timestamp);
            
            // Auto-complete if deposit exhausted
            _completeRental(rentalId);
        } else {
            // Stream already exists, check if it's completed
            bool isDepleted = sablierContract.isDepleted(streamId);
            
            // If stream is complete, update rental status
            if (isDepleted) {
                _completeRental(rentalId);
            }
        }
    }

    /**
     * @notice Adjust rental rate based on usage metrics
     * @param rentalId The rental to adjust
     * @param newRate New payment rate per second
     * @param reason Reason for rate adjustment
     */
    function adjustRate(
        bytes32 rentalId,
        uint256 newRate,
        string memory reason
    ) external {
        Rental storage rental = rentals[rentalId];
        require(rental.status == RentalStatus.Active, "Rental not active");
        require(msg.sender == rental.owner || msg.sender == owner(), "Unauthorized");
        require(newRate > 0, "Rate must be positive");

        // Process any pending payments at old rate first
        streamMicropayment(rentalId);

        uint256 oldRate = rental.currentRate;
        rental.currentRate = newRate;

        emit RateAdjusted(rentalId, oldRate, newRate, reason);
    }

    /**
     * @notice End rental and finalize payments
     * @param rentalId The rental to complete
     * @param finalOdometerReading Final odometer reading (0 if not available)
     * @param oracleAddress Oracle contract address (address(0) if not using telemetry)
     */
    function endRental(
        bytes32 rentalId,
        uint256 finalOdometerReading,
        address oracleAddress
    ) external nonReentrant {
        Rental storage rental = rentals[rentalId];
        require(rental.status == RentalStatus.Active, "Rental not active");
        require(
            msg.sender == rental.renter || 
            msg.sender == rental.owner || 
            msg.sender == owner(),
            "Unauthorized"
        );

        // Update final odometer reading if provided
        if (finalOdometerReading > 0 && rental.vehicleId != bytes32(0)) {
            require(finalOdometerReading >= rental.startOdometer, "Invalid odometer reading");
            rental.endOdometer = finalOdometerReading;
            
            // Update data in Oracle if provided
            if (oracleAddress != address(0)) {
                FlowRentOracle oracle = FlowRentOracle(oracleAddress);
                oracle.updatePricingData(
                    rental.vehicleId,
                    finalOdometerReading,
                    block.timestamp
                );
            }
        }

        // Process final micropayment
        streamMicropayment(rentalId);
        
        _completeRental(rentalId);
    }
    
    /**
     * @notice End rental with telemetry data
     * @param rentalId The rental to complete
     * @param oracleAddress Oracle contract address
     * @param finalOdometerReading Final odometer reading
     */
    function endRentalWithTelemetry(
        bytes32 rentalId,
        address oracleAddress,
        uint256 finalOdometerReading
    ) external nonReentrant {
        Rental storage rental = rentals[rentalId];
        require(rental.status == RentalStatus.Active, "Rental not active");
        require(
            msg.sender == rental.renter || 
            msg.sender == rental.owner || 
            msg.sender == owner(),
            "Unauthorized"
        );
        require(oracleAddress != address(0), "Oracle address required");
        require(rental.vehicleId != bytes32(0), "No vehicle ID assigned");

        // Update final odometer reading
        require(finalOdometerReading >= rental.startOdometer, "Invalid odometer reading");
        rental.endOdometer = finalOdometerReading;

        // Update data in Oracle
        FlowRentOracle oracle = FlowRentOracle(oracleAddress);
        
        // Update pricing data
        oracle.updatePricingData(
            rental.vehicleId,
            finalOdometerReading,
            block.timestamp
        );

        // Process final micropayment
        streamMicropayment(rentalId);
        
        _completeRental(rentalId);
    }

    /**
     * @notice Internal function to complete rental
     * @param rentalId The rental to complete
     */
    function _completeRental(bytes32 rentalId) internal {
        Rental storage rental = rentals[rentalId];
        
        rental.endTime = block.timestamp;
        rental.status = RentalStatus.Completed;
        activeRentals[rentalId] = false;
        
        // Check if there's an active Sablier stream
        uint256 streamId = rentalToStreamId[rentalId];
        
        if (streamId > 0) {
            // Check if the stream is cancelable
            if (sablierContract.isCancelable(streamId)) {
                // Cancel the stream and reclaim unstreamed tokens
                sablierContract.cancel(streamId);
            }
        }

        // Calculate refund (deposit - streamed)
        uint256 refundAmount = rental.depositAmount - rental.totalStreamed;
        
        // Refund remaining deposit to renter
        if (refundAmount > 0) {
            require(
                pyusdToken.transfer(rental.renter, refundAmount),
                "Refund transfer failed"
            );
        }

        totalValueLocked = totalValueLocked - rental.depositAmount;

        emit RentalCompleted(rentalId, rental.totalStreamed, refundAmount);
        emit DepositRefunded(rentalId, rental.renter, refundAmount);
    }

    // Insurance claim functions removed as part of simplification

    /**
     * @notice Get rental details
     * @param rentalId The rental ID to query
     * @return rental The complete rental information
     */
    function getRental(bytes32 rentalId) external view returns (Rental memory rental) {
        return rentals[rentalId];
    }

    /**
     * @notice Get asset details
     * @param assetId The asset ID to query
     * @return asset The complete asset information
     */
    function getAsset(uint256 assetId) external view returns (Asset memory asset) {
        return assets[assetId];
    }

    /**
     * @notice Get user's rental history
     * @param user The user address
     * @return rentalIds Array of rental IDs for the user
     */
    function getUserRentals(address user) external view returns (uint256[] memory rentalIds) {
        return userRentals[user];
    }

    /**
     * @notice Get owner's assets
     * @param ownerAddr The owner address
     * @return assetIds Array of asset IDs owned by the address
     */
    function getOwnerAssets(address ownerAddr) external view returns (uint256[] memory assetIds) {
        return ownerAssets[ownerAddr];
    }

    /**
     * @notice Calculate current rental cost
     * @param rentalId The rental ID
     * @return currentCost Total cost based on time elapsed
     */
    function calculateCurrentCost(bytes32 rentalId) external view returns (uint256 currentCost) {
        Rental storage rental = rentals[rentalId];
        if (rental.status != RentalStatus.Active) return rental.totalStreamed;

        uint256 timeElapsed = block.timestamp - rental.lastStreamTime;
        uint256 additionalCost = timeElapsed * rental.currentRate;
        
        return rental.totalStreamed + additionalCost;
    }

    /**
     * @notice Emergency function to toggle asset availability
     * @param assetId The asset to toggle
     */
    function toggleAssetAvailability(uint256 assetId) external {
        Asset storage asset = assets[assetId];
        require(msg.sender == asset.owner, "Only asset owner");
        
        asset.isActive = !asset.isActive;
    }

    /**
     * @notice Owner emergency withdrawal (only for unclaimed funds)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        uint256 contractBalance = pyusdToken.balanceOf(address(this));
        require(amount <= (contractBalance - totalValueLocked), "Insufficient free balance");
        
        require(pyusdToken.transfer(owner(), amount), "Withdrawal failed");
    }

    /**
     * @notice Update odometer readings for telemetry tracking
     * @param rentalId The rental ID to update
     * @param odometerReading Current odometer reading
     * @param isStartReading Whether this is the starting reading
     * @param oracleAddress Address of the Oracle contract
     */
    function updateOdometerReading(
        bytes32 rentalId,
        uint256 odometerReading,
        bool isStartReading,
        address oracleAddress
    ) external {
        Rental storage rental = rentals[rentalId];
        require(msg.sender == rental.owner || msg.sender == owner(), "Unauthorized");
        
        if (isStartReading) {
            require(rental.status == RentalStatus.Active, "Rental not active");
            require(rental.startOdometer == 0, "Start odometer already set");
            rental.startOdometer = odometerReading;
        } else {
            require(rental.status == RentalStatus.Active || rental.status == RentalStatus.Completed, "Invalid rental status");
            require(rental.startOdometer > 0, "Start odometer not set");
            require(odometerReading >= rental.startOdometer, "Invalid odometer reading");
            rental.endOdometer = odometerReading;
        }
        
        // Update telemetry data in Oracle if provided
        if (oracleAddress != address(0) && rental.vehicleId != bytes32(0)) {
            FlowRentOracle oracle = FlowRentOracle(oracleAddress);
            
            // Update pricing data
            oracle.updatePricingData(
                rental.vehicleId,
                odometerReading,
                block.timestamp
            );
        }
    }
    
    /**
     * @notice Calculate rental fee based on vehicle usage data
     * @param rentalId The rental ID to calculate fee for
     * @param oracleAddress Address of the Oracle contract
     * @return baseFee Base fee before adjustments
     * @return distanceFee Fee component based on distance
     * @return totalFee Total calculated fee
     */
    function calculateTelemetryFee(
        bytes32 rentalId,
        address oracleAddress
    ) external view returns (
        uint256 baseFee,
        uint256 distanceFee,
        uint256 totalFee
    ) {
        require(oracleAddress != address(0), "Invalid oracle address");
        
        Rental storage rental = rentals[rentalId];
        require(rental.status != RentalStatus.None, "Rental does not exist");
        require(rental.vehicleId != bytes32(0), "No vehicle ID assigned");
        
        FlowRentOracle oracle = FlowRentOracle(oracleAddress);
        
        // Use start/end odometer and timestamps for calculation
        uint256 endOdometer = rental.endOdometer > 0 ? rental.endOdometer : rental.startOdometer;
        uint256 endTime = rental.endTime > 0 ? rental.endTime : block.timestamp;
        
        return oracle.calculateRentalFee(
            rental.vehicleId,
            rental.startOdometer,
            endOdometer,
            rental.startTime,
            endTime
        );
    }
    
    /**
     * @notice Process a cross-chain payment from LayerZero
     * @param srcChainId Source chain ID
     * @param srcAddress Source address (OFT wrapper)
     * @param renter Renter address
     * @param amount Amount of PYUSD sent
     * @param vehicleId Vehicle/asset ID
     */
    function processCrossChainPayment(
        uint16 srcChainId,
        bytes memory srcAddress,
        address renter,
        uint256 amount,
        uint256 vehicleId
    ) external {
        // Ensure caller is trusted (in production, this would be a specific address like OFT wrapper)
        // In this example, we're allowing the owner to test this functionality
        require(msg.sender == owner() || isFlowRentContract(msg.sender), "Unauthorized");
        
        // Generate rental ID
        bytes32 rentalId = keccak256(abi.encodePacked(renter, vehicleId, block.timestamp));
        
        // Create a new rental
        Asset memory asset = assets[vehicleId];
        require(asset.owner != address(0), "Asset not registered");
        require(asset.isActive, "Asset not available");
        require(amount >= asset.minDeposit, "Insufficient deposit");
        
        // Create rental entry
        rentals[rentalId] = Rental({
            renter: renter,
            owner: asset.owner,
            assetId: vehicleId,
            depositAmount: amount,
            baseRate: asset.baseRate,
            currentRate: asset.baseRate,
            startTime: block.timestamp,
            endTime: 0,
            totalStreamed: 0,
            lastStreamTime: block.timestamp,
            status: RentalStatus.Active,
            metadataURI: "",
            vehicleId: asset.vehicleId,
            startOdometer: 0,
            endOdometer: 0
        });
        
        // Update tracking
        userRentals[renter].push(vehicleId);
        activeRentals[rentalId] = true;
        totalRentals++;
        totalValueLocked += amount;
        
        emit RentalStarted(rentalId, renter, vehicleId, amount);
        emit CrossChainPaymentReceived(rentalId, renter, amount, srcChainId);
    }
    
    /**
     * @notice Initiate a refund across chains
     * @param rentalId Rental ID
     * @param dstChainId Destination chain ID
     * @param dstAddress Destination address (OFT wrapper)
     * @param gasLimit Gas limit for cross-chain transaction
     */
    function refundCrossChain(
        bytes32 rentalId,
        uint16 dstChainId,
        bytes memory dstAddress,
        uint256 gasLimit
    ) external payable {
        // Only owner or trusted contract can initiate cross-chain refunds
        require(msg.sender == owner() || isFlowRentContract(msg.sender), "Unauthorized");
        
        Rental storage rental = rentals[rentalId];
        require(rental.status == RentalStatus.Completed || rental.status == RentalStatus.Cancelled, "Rental not completed");
        
        // Calculate refund amount
        uint256 totalUsed = rental.totalStreamed;
        uint256 refundAmount = rental.depositAmount > totalUsed ? rental.depositAmount - totalUsed : 0;
        
        require(refundAmount > 0, "No refund available");
        
        // Clear refund to prevent double-spending
        rental.depositAmount = totalUsed;
        totalValueLocked -= refundAmount;
        
        // Transfer PYUSD to OFT wrapper (in production, this would call the OFT contract)
        // For demo purposes, we'll just emit the event
        
        emit CrossChainRefundInitiated(rentalId, rental.renter, refundAmount, dstChainId);
        emit DepositRefunded(rentalId, rental.renter, refundAmount);
    }
    
    /**
     * @notice Check if an address is a registered FlowRent contract
     * @param contractAddress Address to check
     * @return bool True if registered FlowRent contract
     */
    function isFlowRentContract(address contractAddress) public view returns (bool) {
        // In a real implementation, this would check with FlowRentFactory
        // For demo purposes, we'll just return true for the owner
        return contractAddress == owner();
    }
    
    /**
     * @notice Create a Sablier stream for a rental
     * @param rentalId The rental to stream payment for
     * @param duration The duration of the stream in seconds
     */
    function createStream(bytes32 rentalId, uint256 duration) external {
        Rental storage rental = rentals[rentalId];
        require(rental.status == RentalStatus.Active, "Rental not active");
        require(msg.sender == rental.renter || msg.sender == rental.owner || msg.sender == owner(), 
                "Not authorized");
        
        // Check if a stream already exists
        require(rentalToStreamId[rentalId] == 0, "Stream already exists");
        
        // Calculate amount available for streaming
        uint256 availableAmount = rental.depositAmount - rental.totalStreamed;
        require(availableAmount > 0, "No funds available for streaming");
        
        // Approve Sablier to use PYUSD
        require(
            pyusdToken.approve(address(sablierContract), availableAmount),
            "Approval for Sablier failed"
        );
        
        // Create a linear stream with Sablier
        Lockup.CreateWithDurations memory streamParams = Lockup.CreateWithDurations({
            sender: address(this),
            recipient: rental.owner,
            totalAmount: uint128(availableAmount),
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
            total: uint40(duration)
        });
        
        LockupLinear.UnlockAmounts memory unlockAmounts = LockupLinear.UnlockAmounts({
            start: 0, // No initial unlock
            cliff: 0  // No cliff unlock
        });
            
        // Create the stream
        uint256 streamId = sablierContract.createWithDurationsLL(streamParams, unlockAmounts, durations);
        
        // Store the stream ID
        rentalToStreamId[rentalId] = streamId;
        
        // Update rental details
        rental.totalStreamed = availableAmount;
        rental.lastStreamTime = block.timestamp;
        
        emit SablierStreamCreated(rentalId, streamId, availableAmount, duration);
        emit MicropaymentStreamed(rentalId, availableAmount, block.timestamp);
    }
}
