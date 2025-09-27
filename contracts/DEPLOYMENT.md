# FlowRent Contract Architecture & Deployment Process

This document details the technical architecture and deployment process for the FlowRent system, focusing on the contract splitting pattern we implemented to overcome the EVM contract size limitations.

## The Problem: Contract Size Limit Exceeded

Our initial implementation of the FlowRent factory contract exceeded the Ethereum Virtual Machine (EVM) contract bytecode size limit of 24,576 bytes. The original contract was approximately 43,000 bytes, making deployment impossible on any EVM-compatible network.

```
Error: Contract code size is 43,332 bytes and exceeds 24,576 bytes (a limit introduced in Spurious Dragon)
```

## The Solution: Contract Splitting Architecture

To address this challenge, we implemented a modular contract architecture that separates concerns while maintaining functional integrity:

- **Registry Layer**: Stores deployment information across networks
- **Factory Layer**: Split into core and extension contracts to stay under size limits
- **Component Layer**: Specialized contracts for specific functionality
- **Cross-chain Layer**: Handles LayerZero integration and cross-network operations

## Contract Architecture

Our solution employs a carefully designed split-contract architecture to overcome EVM size limitations while maintaining system integrity:

### 1. Registry Layer

The Registry forms the foundation of the system and serves as the canonical source of truth for all deployments:

- **FlowRentRegistry**: Core contract that stores all deployment information and tracks contract validity
- **FlowRentRegistryExtension**: Handles advanced registry operations and deployment logic that would otherwise increase the core registry size
- **FlowRentRegistryDeployer**: Dedicated deployer contract that initializes the registry system with proper ownership

### 2. Factory Layer

The Factory layer manages deployments and was the primary focus of our contract splitting solution:

- **FlowRentFactoryCore**: Streamlined core factory with essential functionality, reduced to under 24kb
- **FlowRentFactoryExtension**: Houses complex deployment logic and cross-chain functionality
- **FlowRentDeployHelper**: Offloads utility functions and batch operations to further reduce core contract size
- **FlowRentFactoryDeployer**: Manages the deployment process with proper ownership and permission settings

### 3. Component Layer

The functional components provide the actual rental system capabilities:

- **FlowRentEscrow**: Manages the rental lifecycle, deposits, and payment streaming
- **FlowRentOracle**: Handles verification and price feed integration
- **FlowRentEscrowSimple**: Optimized version for high-volume use cases with reduced functionality

### 4. Cross-Network Layer

Enables seamless operation across multiple networks:

- **FlowRentPYUSDOFT**: Manages token operations across networks
- **FlowRentPYUSDSablier**: Integrates streaming payment functionality across networks
- **ProofOfHumanOApp/Receiver**: Provides identity verification across networks

### Architecture Diagram

```
                   ┌──────────────────────────┐
                   │                          │
                   │   FlowRentFactoryCore    │
                   │                          │
                   └──────────────┬───────────┘
                                  │
                                  │ references
                                  │
                   ┌──────────────▼───────────┐
                   │                          │
                   │ FlowRentFactoryExtension │
                   │                          │
                   └──────────────────────────┘
                   
                   
┌────────────────┐   deploys   ┌───────────────┐   deploys   ┌────────────────┐
│                │◄────────────┤               │────────────►│                │
│ FlowRentEscrow │             │ FactoryCore   │             │ FlowRentOracle │
│                │             │               │             │                │
└────────────────┘             └───────────────┘             └────────────────┘
                                      ▲
                                      │
                                      │
                               ┌──────┴──────┐
                               │             │
                               │ Extension   │
                               │             │
                               └──────┬──────┘
                                      │
                                      ▼
                            ┌───────────────────┐
                            │                   │
                            │ Cross-network     │
                            │ Integration       │
                            │                   │
                            └───────────────────┘
```

## Evolution of Deployment Scripts

Our deployment scripts evolved with our contract architecture to address the bytecode size limitations:

### Initial Approach: Single Deployment Script

Our first implementation used a monolithic deployment script (`DeployFlowRentSystem.s.sol`) that failed when attempting to deploy the oversized factory contract.

### Split Contract Deployment

We then created specialized deployment scripts for the split contract architecture:

- `DeployFlowRentSplit.s.sol`: Our first attempt at split contract deployment
- `DeployFlowRentSplitFurther.s.sol`: Further optimized the splitting pattern
- `DeployFlowRentUltraSplit.s.sol`: The final ultra-modular split pattern

### Current Modular Deployment Process

Our current approach uses a series of deployment scripts, each handling a specific layer of the architecture:

### Step 1: Deploy Registry Layer

```bash
forge script script/Deploy01Registry.s.sol --rpc-url <RPC_URL> --broadcast
```

This script:
- Deploys the Registry Deployer
- Uses the deployer to create the Registry
- Deploys the Registry Extension
- Sets proper ownership and permissions

### Step 2: Deploy Factory Layer

```bash
forge script script/Deploy02Factory.s.sol --rpc-url <RPC_URL> --broadcast
```

This script:
- Deploys the Factory Deployer
- Uses the deployer to create the Factory Core under the size limit
- Deploys the Factory Extension and Deploy Helper
- Links the Factory to the Registry

### Step 3: Deploy Component Layer

```bash
forge script script/Deploy03Components.s.sol --rpc-url <RPC_URL> --broadcast
```

This script:
- Uses the Factory to deploy the Escrow and Oracle
- Registers the components with the Registry
- Sets up component permissions

### Step 4: Configure System Integration

```bash
forge script script/Deploy04Setup.s.sol --rpc-url <RPC_URL> --broadcast
```

This script:
- Configures cross-network connections
- Sets up initial assets and parameters
- Performs final permission configurations

## Deployment Options

We maintain several deployment options to accommodate different needs:

### Option 1: Sequential Modular Deployment

Run each script in sequence, saving environment variables between steps. This is the most reliable method for production deployments.

### Option 2: All-in-One Deployment

```bash
forge script script/DeployFlowRentSystem.s.sol --rpc-url <RPC_URL> --broadcast
```

This orchestrates the deployment of all components using the ultra-split architecture in a single script execution.

### Option 3: Guided Deployment (Information Only)

```bash
forge script script/DeployFlowRentOrchestrator.s.sol --rpc-url <RPC_URL>
```

This provides detailed guidance on the deployment process without performing actual deployments, useful for planning and preparation.

## Size Optimization Techniques

To keep our contracts under the 24kb limit, we implemented several optimization techniques:

1. **Function Offloading**: Moved non-essential functions to extension contracts
2. **Storage Optimization**: Redesigned storage layouts to minimize slots
3. **Code Refactoring**: Eliminated redundancies and optimized logic
4. **Proxy Pattern Avoidance**: Used contract splitting instead of proxy patterns to maintain security
5. **Library Utilization**: Moved common code to libraries where appropriate

## Deployment Environment Configuration

Our deployment process requires specific environment setup:

### Environment Variables

Deployment scripts rely on environment variables in `.env` files that are created and maintained through the deployment process:

```
# Core deployment variables
PRIVATE_KEY=your_private_key
NETWORK_NAME=arbitrum-sepolia
ARBITRUM_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc

# External dependencies
LAYERZERO_ENDPOINT_ADDRESS=0x...
PYUSD_TOKEN_ADDRESS=0x...
VERIFICATION_CONTRACT_ADDRESS=0x...
SABLIER_LOCKUP_ADDRESS=0x...

# Sequentially populated during deployment
FLOWRENT_REGISTRY_ADDRESS=0x...         # Step 1
FLOWRENT_REGISTRY_EXTENSION_ADDRESS=0x... # Step 1
FLOWRENT_FACTORY_CORE_ADDRESS=0x...     # Step 2
FLOWRENT_DEPLOY_HELPER_ADDRESS=0x...    # Step 2
FLOWRENT_ESCROW_ADDRESS=0x...           # Step 3
FLOWRENT_ORACLE_ADDRESS=0x...           # Step 3
```

### Shell Script Helpers

We've created shell script helpers to simplify the deployment process:

- `deploy-modular-flowrent.sh`: Orchestrates the full deployment sequence
- `deploy-components.sh`: Handles specific component deployment
- `verify-contracts.sh`: Handles contract verification on explorers

## Contract Interaction Flow

The contract interaction pattern follows this flow:

```
                    ┌───────────────┐
                    │               │
                    │   Deployer    │
                    │               │
                    └───────┬───────┘
                            │
                            ▼
┌────────────────┐    ┌─────────────┐    ┌────────────────┐
│                │◄───┤             │───►│                │
│   Registry     │    │   Factory   │    │  Registry      │
│   Deployer     │    │   Deployer  │    │  Extension     │
│                │    │             │    │  Deployer      │
└────────┬───────┘    └──────┬──────┘    └────────┬───────┘
         │                   │                    │
         ▼                   ▼                    ▼
┌────────────────┐    ┌─────────────┐    ┌────────────────┐
│                │◄───┤             │───►│                │
│   Registry     │    │  Factory    │    │   Registry     │
│                │    │  Core       │    │   Extension    │
│                │    │             │    │                │
└────────┬───────┘    └──────┬──────┘    └────────┬───────┘
         │                   │                    │
         │                   │                    │
         │                   ▼                    │
         │            ┌─────────────┐             │
         │            │             │             │
         └───────────►│ Components  │◄────────────┘
                      │ (Escrow,    │
                      │  Oracle)    │
                      └─────────────┘
```

## Key Technical Challenges Solved

Our deployment architecture solves several key challenges:

1. **Contract Size Limitation**: By splitting contracts, we stay under the 24kb EVM limit
2. **Ownership Management**: Proper ownership chain from deployer to components
3. **Cross-Network Consistency**: Registry ensures consistent deployments across networks
4. **Upgradability**: Components can be upgraded independently
5. **Gas Optimization**: Smaller contracts mean lower deployment gas costs

## Post-Deployment Verification

After deployment is complete, verify the system with these checks:

1. Ensure the Registry contains correct deployment information:
   ```bash
   cast call $FLOWRENT_REGISTRY_ADDRESS "getDeployment(string)" "$NETWORK_NAME"
   ```

2. Verify Factory Core has ownership of the Registry:
   ```bash
   cast call $FLOWRENT_REGISTRY_ADDRESS "owner()" | grep $FLOWRENT_FACTORY_CORE_ADDRESS
   ```

3. Check that components are properly registered:
   ```bash
   cast call $FLOWRENT_REGISTRY_ADDRESS "isValidFlowRentContract(address)" $FLOWRENT_ESCROW_ADDRESS
   ```

## Technical Architecture Benefits

This modular deployment architecture provides several benefits:

1. **Maintainability**: Each contract has a focused responsibility
2. **Size Compliance**: All contracts stay under EVM limits
3. **Scalability**: New components can be added without restructuring
4. **Testing Isolation**: Components can be tested independently
5. **Network Agnosticism**: Works on any EVM-compatible network

## Conclusion

Our contract splitting architecture successfully overcame the EVM contract size limitations while maintaining system integrity and functionality. The modular deployment approach provides flexibility, upgradability, and cost efficiency while ensuring consistent behavior across multiple networks.
