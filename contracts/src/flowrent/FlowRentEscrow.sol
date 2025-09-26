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

}