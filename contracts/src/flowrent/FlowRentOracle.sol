// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./FlowRentEscrow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FlowRentOracle
 * @notice Simplified oracle contract for basic rate adjustments using vehicle usage data
 * @dev Provides pricing based on vehicle usage without geofencing, insurance, or health monitoring
 */
contract FlowRentOracle is Ownable {

    // Pricing data
    struct PricingData {
        uint256 odometer;              // Total miles driven
        uint256 timestamp;             // Time of data snapshot
        uint256 lastUpdated;           // Last update timestamp
    }

    // Vehicle metadata
    struct VehicleMetadata {
        string carType;                // Vehicle model/type
        string trim;                   // Vehicle trim level
        uint256 baseRate;              // Base rate per minute
        bool isActive;                 // Vehicle status
    }

    // Combined vehicle data
    struct VehicleData {
        PricingData pricing;
        VehicleMetadata metadata;
    }

    // Oracle data feeds
    mapping(bytes32 => VehicleData) public vehicleData;          // vehicleId => Vehicle data
    mapping(address => bool) public authorizedFeeds;             // Authorized data feed addresses
    mapping(bytes32 => uint256) public baseRates;                // vehicleId => base rate per minute

    FlowRentEscrow public immutable escrowContract;

    // Events
    event PricingDataUpdated(bytes32 indexed vehicleId, PricingData data);
    event VehicleRegistered(bytes32 indexed vehicleId, string carType, string trim);
    event DataFeedAuthorized(address indexed feedAddress, bool authorized);
    event RateAdjustmentApplied(bytes32 indexed rentalId, uint256 oldRate, uint256 newRate);
    event RateCalculated(bytes32 indexed rentalId, uint256 rate, uint256 distanceFactor);

    modifier onlyAuthorizedFeed() {
        require(authorizedFeeds[msg.sender] || msg.sender == owner(), "Unauthorized feed");
        _;
    }

    constructor(address _escrowContract, address _owner) Ownable(_owner) {
        require(_escrowContract != address(0), "Invalid escrow contract");
        escrowContract = FlowRentEscrow(_escrowContract);
    }

    /**
     * @notice Register a new vehicle with metadata
     * @param vehicleId Hash identifier for the vehicle
     * @param carType Vehicle model/type
     * @param trim Vehicle trim level
     * @param baseRate Base rate per minute for this vehicle
     */
    function registerVehicle(
        bytes32 vehicleId,
        string memory carType,
        string memory trim,
        uint256 baseRate
    ) external onlyOwner {
        require(bytes(vehicleData[vehicleId].metadata.carType).length == 0, "Vehicle already registered");
        require(bytes(carType).length > 0, "Car type required");
        require(baseRate > 0, "Base rate must be positive");

        VehicleMetadata memory metadata = VehicleMetadata({
            carType: carType,
            trim: trim,
            baseRate: baseRate,
            isActive: true
        });

        // Initialize empty data
        vehicleData[vehicleId].metadata = metadata;
        baseRates[vehicleId] = baseRate;

        emit VehicleRegistered(vehicleId, carType, trim);
    }

   