# RentalRide

A global pay-as-you-go vehicle rental app with passport-based KYC via SelfXYZ, eliminating traditional FX and enabling seamless cross-chain PYUSD payments through LayerZero.

Our app lets you rent vehicles anywhere in the world and pay only for what you use. Passport-based KYC via SelfXYZ ensures instant verification while giving you control over which details (name, country, age) are disclosed. Traditional foreign exchange hassles are eliminated with PYUSD, and payments are streamed via Sablier and settled across chains using LayerZero.


**Traveler Scenario: Business Trip from Mumbai to San Francisco**

1. **Pre-trip Preparation**
   * You download the FlowRent app and complete one-time verification using passport via SelfXYZ.
   * Only your name,country and age is disclosed.

2. **Arrival in San Francisco**
   * Upon landing, you select a Tesla Model 3 for going to the hotel.

3. **Seamless Rental Process**
   * Your passport verification is instantly recognized across chains via LayerZero.
   * You deposit an initial amount of PYUSD , which is held in the FlowRent escrow contract.
   * You unlock the Tesla and begin your rental.

4. **Pay as You Go**
   * As you drive, PYUSD payments stream from the deposit to the vehicle owner via Sablier.
   * When driving in congested areas, the rate automatically adjusts based on telemetry data using [Fleet API](https://developer.tesla.com/docs/fleet-api/fleet-telemetry/available-data?) from Tesla.
   * Your dashboard shows the remaining deposit in real time.

5. **Return and Settlement**
   * After completing the trip, you return the vehicle to the designated area.
   * The final odometer reading and conditions are recorded via the FlowRent Oracle.
   * The remaining deposit is immediately returned to the connected wallet.
   * You receive a dynamic NFT based receipt for corporate expense reporting.

**Benefits**
- No need for international credit cards or currency exchange
- No waiting for security deposit refunds
- Pay-per-minute pricing rather than full-day charges
- Transparent, immutable record of all transactions
- Streamlined expense reporting 

This cross-border rental experience demonstrates how FlowRent eliminates traditional friction points in international vehicle rentals while providing enhanced security and transparency for both renters and vehicle owners.

## Deployment Addresses

- [VERIFICATION_CONTRACT_ADDRESS](https://sepolia.arbiscan.io/address/0x401F7Fa7DCaE2E85c491f5EA13078d67fEA2C156): 0x401F7Fa7DCaE2E85c491f5EA13078d67fEA2C156
- [FLOWRENT_REGISTRY_DEPLOYER](https://sepolia.arbiscan.io/address/0x27Fd325E871D936A74eD6bD03271dec01bf0878B): 0x27Fd325E871D936A74eD6bD03271dec01bf0878B
- [FLOWRENT_REGISTRY_ADDRESS](https://sepolia.arbiscan.io/address/0x0d28c9ad837BCE050c7ce03620E43303898F4E9C): 0x0d28c9ad837BCE050c7ce03620E43303898F4E9C
- [FLOWRENT_REGISTRY_EXTENSION_ADDRESS](https://sepolia.arbiscan.io/address/0xD4470930415bEdf50C27adB3F66e3ba0E95a696a): 0xD4470930415bEdf50C27adB3F66e3ba0E95a696a
- [FLOWRENT_FACTORY_DEPLOYER](https://sepolia.arbiscan.io/address/0x9DFB057db24d8f90EF946C8C8D228715C9c42Aab): 0x9DFB057db24d8f90EF946C8C8D228715C9c42Aab
- [FLOWRENT_FACTORY_CORE_ADDRESS](https://sepolia.arbiscan.io/address/0xE07245a5C8C353d7Fb7340c51666747cA6E4c97d): 0xE07245a5C8C353d7Fb7340c51666747cA6E4c97d
- [FLOWRENT_DEPLOY_HELPER_ADDRESS](https://sepolia.arbiscan.io/address/0xC2A56703D8Dcc0A81d3cC8aC74a7D2555b440744): 0xC2A56703D8Dcc0A81d3cC8aC74a7D2555b440744
- [FLOWRENT_FACTORY_EXTENSION_ADDRESS](https://sepolia.arbiscan.io/address/0x27E14E0def858CBCD3a6231BBb74c76d37Cf6107): 0x27E14E0def858CBCD3a6231BBb74c76d37Cf6107

**Main Addresses**

- [FLOWRENT_ESCROW_ADDRESS](https://sepolia.arbiscan.io/address/0x1d95021415F785a8941B9791AaC99D3b745bE8eb): 0x1d95021415F785a8941B9791AaC99D3b745bE8eb 
- [FLOWRENT_ORACLE_ADDRESS](https://sepolia.arbiscan.io/address/0xD14770ea4c3EeD672F437090863D5BFf68AB9384): 0xD14770ea4c3EeD672F437090863D5BFf68AB9384


---

## Further Documentation

- [Architecture Guide](./ARCHITECTURE.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Scripts Reference](./SCRIPTS_GUIDE.md)



