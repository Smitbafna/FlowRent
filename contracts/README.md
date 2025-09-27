# FlowRent Project

## Overview

FlowRent is a blockchain-based rental system that enables efficient, secure, and cross-chain rental agreements with real-time payment streaming.

## Key Technical Challenge: Contract Size Limitation

This project showcases an innovative solution to Ethereum's 24,576-byte smart contract size limitation. Our original monolithic contract design was approximately 43,332 bytes, exceeding the limit by 18,756 bytes.

Instead of using proxy patterns (which introduce security concerns), we implemented a contract splitting pattern that provides better security and maintainability.

## Project Documentation

Please refer to these documents for details about the system:

- [FlowRent Architecture](./FLOWRENT_ARCHITECTURE.md) - Technical explanation of the contract splitting pattern
- [Simple Contract Architecture](./SIMPLE_CONTRACT_ARCHITECTURE.md) - Non-technical explanation of the architecture
- [Deployment Process](./DEPLOYMENT.md) - Details on how the system is deployed and configured

## Contract Structure

The FlowRent system is organized into logical layers to solve the contract size limitation:

### Registry Layer

- **FlowRentRegistry**: Central registry for all components
- **FlowRentRegistryExtension**: Additional registry functionality

### Factory Layer

- **FlowRentFactoryCore**: Core factory functionality (under size limit)
- **FlowRentDeployHelper**: Helper contract for deployment logic

### Component Layer

- **FlowRentEscrow**: Escrow contract for rental management
- **FlowRentOracle**: Oracle for off-chain data integration

## Contract Size Optimization

Our approach to solving the contract size limitation included:

1. **Function Offloading**: Moving non-essential functions to extension contracts
2. **Storage Optimization**: Redesigning storage layouts to minimize slots
3. **Code Refactoring**: Eliminating redundancies and optimizing logic
4. **Library Utilization**: Moving common code to libraries where appropriate

## Contract Communication Pattern

Contracts communicate through:

1. **Direct Method Calls**: For same-transaction operations
2. **Event Emissions**: For asynchronous notifications
3. **Registry Lookups**: For finding contract addresses

## Deployment Process

The deployment follows this sequence:

1. Deploy Registry and Registry Extension
2. Deploy Factory Core and Deploy Helper
3. Register Factory Core with Registry
4. Deploy Components using Factory
5. Set up component relationships

For detailed deployment instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).

## Development Environment

This project uses Foundry for smart contract development:

```bash
# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test

# Deploy (example for Arbitrum Sepolia)
forge script script/Deploy01Registry.s.sol --broadcast --rpc-url arbitrum-sepolia
forge script script/Deploy02Factory.s.sol --broadcast --rpc-url arbitrum-sepolia
forge script script/Deploy03Components.s.sol --broadcast --rpc-url arbitrum-sepolia
```

## Technical Benefits of Contract Splitting

Our contract splitting architecture provides several advantages:

1. **Compliance with EVM Limits**: All contracts stay under the 24,576-byte limit
2. **Modularity**: Components can be upgraded independently
3. **Security**: Avoids proxy-related vulnerabilities
4. **Gas Efficiency**: Smaller contracts mean lower deployment costs
5. **Maintainability**: Each contract has a clear, focused responsibility

## Technical Architecture Benefits

This modular deployment architecture provides several benefits:

1. **Maintainability**: Each contract has a focused responsibility
2. **Size Compliance**: All contracts stay under EVM limits
3. **Scalability**: New components can be added without restructuring
4. **Testing Isolation**: Components can be tested independently
5. **Network Agnosticism**: Works on any EVM-compatible network

## Conclusion

Our contract splitting architecture successfully overcame the EVM contract size limitations while maintaining system integrity and functionality. The modular deployment approach provides flexibility, upgradability, and cost efficiency.

## License

FlowRent is released under the MIT License. See [LICENSE](LICENSE) for details.
