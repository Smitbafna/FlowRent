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

# FlowRent Contracts: One-Line Explanations

## Cross-Chain Verification System
- `ProofOfHuman.sol`: Base contract for human verification functionality with Self Protocol.
- `ProofOfHumanOApp.sol`: Verifies users on Celo via Self Protocol and forwards verification data across chains via LayerZero.
- `ProofOfHumanReceiver.sol`: Receives and stores cross-chain verification data on Arbitrum from the Celo sender.

## Core FlowRent System
- `flowrent/FlowRentEscrow.sol`: Core rental management contract handling deposits, streaming payments, and the rental lifecycle.
- `flowrent/FlowRentOracle.sol`: Provides price data and usage-based rate adjustments for vehicle rentals.
- `flowrent/FlowRentRegistry.sol`: Central registry tracking all FlowRent contract deployments across networks.

## Deployment Infrastructure
- `flowrent/FlowRentDeployHelper.sol`: Utility contract with helper functions for complex deployment operations.
- `flowrent/FlowRentFactoryCore.sol`: Core factory responsible for deploying FlowRent components.
- `flowrent/FlowRentFactoryDeployer.sol`: Handles deployment of the factory contracts with proper permissions.
- `flowrent/FlowRentFactoryExtension.sol`: Extension of factory functionality to stay under contract size limits.
- `flowrent/FlowRentRegistryDeployer.sol`: Manages registry deployment with correct ownership configuration.
- `flowrent/FlowRentRegistryExtension.sol`: Additional registry functionality to avoid exceeding size limits.

## Cross-Chain Payment System
- `flowrent/FlowRentPYUSDOFT.sol`: Manages cross-chain PYUSD transfers via LayerZero OFT protocol.
- `flowrent/FlowRentPYUSDSablier.sol`: Handles cross-chain streaming payments using Sablier protocol.

## External Interfaces
- `flowrent/interfaces/ILayerZeroEndpoint.sol`: Interface for interacting with LayerZero endpoints.
- `flowrent/interfaces/IOFT.sol`: Interface for the Omnichain Fungible Token (OFT) standard.

