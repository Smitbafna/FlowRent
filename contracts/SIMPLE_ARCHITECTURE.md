# FlowRent: The Global Digital Passport for Asset Rentals


## Introduction

FlowRent revolutionizes the vehicle rental industry by introducing a global digital passport for asset rentals. By eliminating traditional intermediaries and removing foreign exchange complexities, FlowRent creates a borderless rental ecosystem where assets can be accessed anywhere in the world.

## The Problem We Solve

Traditional rental systems face significant challenges:
- Complex identity verification processes across borders
- Foreign exchange fees and currency conversion headaches
- Delayed settlements with high transaction costs
- Lack of trust between renters and owners in different countries

## Our Solution

FlowRent introduces a unified global rental passport that:

1. **Eliminates Identity Friction**: Verifies users once through Self Protocol's digital identity verification
2. **Removes FX Complexities**: Uses PYUSD (Paypal's stablecoin) for consistent pricing everywhere
3. **Enables Real-Time Payments**: Money flows from renter to owner as the asset is used through continuous payment streaming
4. **Works Across Networks**: Seamless operation across Arbitrum, Base, and other networks

## Key Technologies

### Self Protocol Integration
FlowRent leverages Self Protocol as the cornerstone of our identity verification system:

- **One-Time Verification**: Users verify their identity once through Self's mobile app
- **Cross-Network Recognition**: Your digital identity passport works across all supported networks
- **Privacy-Preserving**: Verification happens without exposing personal data
- **Fraud Prevention**: Ensures all renters are verified real humans

### PYUSD Integration
We've integrated PayPal's PYUSD stablecoin as our native currency:

- **Global Stable Value**: Consistent $1 USD value regardless of location
- **Mainstream Recognition**: Backed by PayPal for widespread trust
- **Low Volatility**: Protection against market fluctuations
- **Seamless Settlement**: Direct conversion to local currency

### Sablier Protocol for Streaming Payments
Our real-time payment system uses Sablier V2:

- **Pay-Per-Second**: Funds flow continuously as the asset is used
- **Auto-Adjusting**: Payment rates adapt to usage patterns
- **Fair for Both Parties**: Owners get paid instantly, renters only pay for what they use

## System Architecture

### 1. Registry Layer
The central coordination system that manages the FlowRent ecosystem:

* **FlowRentRegistry**: The global directory that maintains records of all FlowRent deployments across networks
* **FlowRentRegistryExtension**: Extends registry capabilities with advanced deployment tracking

### 2. Factory Layer
The deployment engine that powers FlowRent expansion:

* **FlowRentFactoryCore**: Generates consistent FlowRent instances across multiple networks
* **FlowRentFactoryExtension**: Provides specialized deployment features for different network environments
* **FlowRentDeployHelper**: Streamlines the deployment process with optimized utility functions

### 3. Core Components
The functional heart of the FlowRent system:

* **FlowRentEscrow**: Manages the rental lifecycle, handling deposits and orchestrating payment streams between parties
* **FlowRentOracle**: Provides verified pricing data and integration with Self Protocol's identity verification
* **FlowRentEscrowSimple**: Optimized implementation for specific high-volume use cases

### 4. Cross-Network Bridge Components
The infrastructure that enables the global rental passport:

* **FlowRentPYUSDOFT**: Manages PYUSD token operations across networks via LayerZero omnichain technology
* **FlowRentPYUSDSablier**: Connects PYUSD with Sablier streaming protocol across networks
* **ProofOfHumanOApp & ProofOfHumanReceiver**: Bridge Self Protocol's identity verification across networks

## Deployment Architecture

FlowRent's deployment system is designed for consistent expansion across global networks:

### Modular Deployment Pipeline

Our structured deployment process ensures reliability and consistency:

#### 1. Registry Deployment
Establishes the foundation of the global rental passport network:
```bash
forge script Deploy01Registry.s.sol --broadcast
```

#### 2. Factory Deployment
Deploys the component generation system:
```bash
forge script Deploy02Factory.s.sol --broadcast
```

#### 3. Core Components Deployment
Implements the rental and payment infrastructure:
```bash
forge script Deploy03Components.s.sol --broadcast
```

#### 4. Network Integration
Configures cross-network connectivity and permissions:
```bash
forge script Deploy04Setup.s.sol --broadcast
```

### Network Expansion

FlowRent is designed for multi-network deployment with current support for:

- **Arbitrum** - Our primary network with full feature implementation
- **Base** - Extended network support for growing user communities
- **Optimism** - Strategic expansion network for enhanced accessibility
- **Additional Networks** - Configurable deployment to any EVM-compatible network

## The User Experience

### For Asset Owners
1. **One-Time Registration**: Register your asset details and set your desired rental rate
2. **Instant Global Visibility**: Your asset becomes available to verified renters worldwide
3. **Real-Time Income**: Receive PYUSD payments continuously as your asset is being used
4. **Verified Renters Only**: Rest easy knowing all renters are verified through Self Protocol
5. **Automatic Settlement**: Funds are settled automatically with no collection or currency conversion hassles

### For Renters
1. **Digital Passport Creation**: Complete one-time verification through Self Protocol's mobile app
2. **Borderless Access**: Rent assets anywhere without country-specific registration
3. **Pay-As-You-Go**: Your PYUSD deposit converts to a streaming payment that flows only while you use the asset
4. **No FX Complications**: Pay in PYUSD regardless of which country you're renting in
5. **Instant Refunds**: Unused funds are automatically returned when your rental ends

## Cross-Network Integration

FlowRent uses LayerZero technology to create a unified rental ecosystem across networks:

1. **Identity Passport Bridging**: Your Self Protocol verification works seamlessly across all networks
2. **Unified Asset Registry**: Assets registered on any network are accessible from all other networks
3. **Omnichain PYUSD**: PYUSD tokens move effortlessly between networks for rental payments
4. **Consistent Experience**: The user experience remains identical regardless of which network you're on

Our `deploy-oapp-cross-chain.sh` script handles the complex deployment of cross-network verification bridges.

## Business Applications

FlowRent is designed for real-world business integration:

- **Rental Businesses**: Car rentals, equipment leasing, property rentals
- **Sharing Economy Platforms**: On-demand transportation, workspace sharing
- **Enterprise Asset Management**: Corporate equipment tracking and utilization
- **Global Mobility Solutions**: Seamless vehicle access across international borders
- **Tourism & Hospitality**: Streamlined tourist rentals without local payment complications

## Getting Started

```bash
# Clone the repository
git clone https://github.com/your-org/flowrent.git

# Install dependencies
cd flowrent/contracts
npm install
forge install

# Configure environment
cp .env.example .env
# Edit .env with your deployment keys and network configurations

# Deploy to your network of choice
make deploy NETWORK=arbitrum-sepolia
```

## Contributing

We welcome contributions to the FlowRent ecosystem. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

FlowRent is released under the MIT License. See [LICENSE](LICENSE) for details.
