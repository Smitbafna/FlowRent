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

    /**
     * @notice Update pricing data for a vehicle
     * @param vehicleId Vehicle to update
     * @param odometer Current odometer reading
     * @param timestamp Timestamp of data
     */
    function updatePricingData(
        bytes32 vehicleId,
        uint256 odometer,
        uint256 timestamp
    ) external onlyAuthorizedFeed {
        require(vehicleData[vehicleId].metadata.isActive, "Vehicle not active");
        require(odometer > 0, "Invalid odometer reading");
        require(timestamp > 0, "Invalid timestamp");

        PricingData memory pricing = PricingData({
            odometer: odometer,
            timestamp: timestamp,
            lastUpdated: block.timestamp
        });

        vehicleData[vehicleId].pricing = pricing;

        emit PricingDataUpdated(vehicleId, pricing);
    }

    /**
     * @notice Calculate adjusted rate based on vehicle usage data
     * @param vehicleId Vehicle to calculate rate for
     * @param previousOdometer Previous odometer reading for distance calculation
     * @param previousTimestamp Previous timestamp for time calculation
     * @return adjustedRate The calculated rate per minute
     * @return distanceFactor Distance-based adjustment
     */
    function calculateRate(
        bytes32 vehicleId,
        uint256 previousOdometer,
        uint256 previousTimestamp
    ) public view returns (
        uint256 adjustedRate,
        uint256 distanceFactor
    ) {
        require(vehicleData[vehicleId].metadata.isActive, "Vehicle not active");
        
        VehicleData storage data = vehicleData[vehicleId];
        uint256 baseRate = baseRates[vehicleId];
        
        // Calculate distance factor (miles driven)
        uint256 milesDriven = 0;
        if (data.pricing.odometer > previousOdometer) {
            milesDriven = data.pricing.odometer - previousOdometer;
        }
        distanceFactor = 10000 + (milesDriven * 100); // 1.0x + 0.01x per mile
        
        // Calculate final rate with distance factor
        uint256 rate = baseRate;
        rate = (rate * distanceFactor) / 10000;
        
        return (rate, distanceFactor);
    }

    /**
     * @notice Apply usage-based rate adjustment to active rental
     * @param rentalId Rental to adjust
     * @param vehicleId Vehicle ID
     * @param previousOdometer Previous odometer reading for calculation
     * @param previousTimestamp Previous timestamp for calculation
     */
    function applyRateAdjustment(
        bytes32 rentalId,
        bytes32 vehicleId,
        uint256 previousOdometer,
        uint256 previousTimestamp
    ) external onlyAuthorizedFeed {
        require(vehicleData[vehicleId].metadata.isActive, "Vehicle not active");
        
        (uint256 newRate, uint256 distanceFactor) = 
            calculateRate(vehicleId, previousOdometer, previousTimestamp);
        
        // Get current rental rate from escrow contract
        FlowRentEscrow.Rental memory rental = escrowContract.getRental(rentalId);
        uint256 currentRate = rental.currentRate;
        
        if (newRate != currentRate) {
            // Apply adjustment via escrow contract
            string memory reason = string(abi.encodePacked(
                "Usage adjustment for vehicle: ", 
                vehicleData[vehicleId].metadata.carType
            ));
            escrowContract.adjustRate(rentalId, newRate, reason);
            
            emit RateAdjustmentApplied(rentalId, currentRate, newRate);
            emit RateCalculated(rentalId, newRate, distanceFactor);
        }
    }

   
}
