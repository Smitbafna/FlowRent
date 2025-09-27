# FlowRent Deployment Guide

This guide explains the deployment process for FlowRent's smart contract system, which includes both the core rental contracts and the cross-chain verification system.

## Overview of Deployment Architecture

FlowRent consists of multiple interconnected components deployed across two chains:

1. **Celo Mainnet** - Hosts the Self Protocol verification system and cross-chain sender
2. **Arbitrum One** - Hosts the FlowRent core contracts and verification receiver

## Deployment Scripts

Here are the deployment scripts in the order they should be used:

### 1. Cross-Chain Verification System

```bash
# Deploy verification system (ProofOfHumanOApp on Celo → ProofOfHumanReceiver on Arbitrum)
./script/deploy-oapp-cross-chain.sh
```

This script:
- Deploys `ProofOfHumanOApp.sol` on Celo Mainnet
- Deploys `ProofOfHumanReceiver.sol` on Arbitrum One
- Sets up LayerZero peers between the contracts
- Configures Self Protocol verification scope

### 2. FlowRent Core System

After verifying the cross-chain verification is working:

```bash
# Deploy FlowRent core contracts
forge script script/DeployFlowRent.s.sol --rpc-url arbitrum-one --broadcast --verify
```

This script:
- Deploys `FlowRentDeploymentManager.sol` on Arbitrum One
- Uses the manager to deploy `FlowRentEscrow.sol` and `FlowRentOracle.sol`
- Links the escrow to the previously deployed `ProofOfHumanReceiver`

## Manual Configuration Steps

After deployment, perform these configuration steps:

1. **Fund Verification Contracts**:
```bash
# Fund the Celo verification contract (required for auto-forward)
make fund-source AMOUNT=0.5
```

2. **Register Oracle Data Feeds**:
```bash
# Add authorized data feeds to the Oracle
cast send $ORACLE_ADDRESS "authorizeDataFeed(address,bool)" $FEED_ADDRESS true --private-key $PRIVATE_KEY
```

3. **Set Verification Scope**:
```bash
# Set the scope for Self Protocol verification if not done in initial deployment
make set-scope
```

## Verification

Verify all contracts were deployed correctly:

```bash
# Verify contracts on block explorers
./script/verify-contracts.sh
```

## Production Deployment Order

For a production deployment, follow these steps in order:

1. Deploy verification system on Celo and Arbitrum (deploy-oapp-cross-chain.sh)
2. Verify the cross-chain messaging works (check via contract interactions)
3. Deploy FlowRent core contracts on Arbitrum (DeployFlowRent.s.sol)
4. Configure and connect all components manually
5. Fund the source contract on Celo for cross-chain messaging

## Contract Dependencies

```
ProofOfHumanOApp (Celo) → LayerZero → ProofOfHumanReceiver (Arbitrum)
                                              ↓
                                      FlowRentEscrow ←→ FlowRentOracle
```

## Environment Setup

Ensure your `.env` file contains these variables:

```
# Private key (same for both chains)
PRIVATE_KEY=

# Chain RPC URLs (if not using defaults)
CELO_RPC_URL=
ARBITRUM_RPC_URL=

# Self Protocol configuration
VERIFICATION_CONFIG_ID=
SCOPE_SEED=

# LayerZero configuration
SOURCE_EID=30125
DESTINATION_EID=30110

# API keys for contract verification
CELOSCAN_API_KEY=
ARBISCAN_API_KEY=
```

## Troubleshooting

If you encounter issues during deployment:

1. **Cross-chain messaging fails**: Ensure both contracts have funds and LayerZero peers are correctly set
2. **Contract verification fails**: Make sure API keys are correct and contracts were deployed with correct parameters
3. **Out of gas errors**: Increase gas limit for complex deployments, especially for cross-chain transactions
