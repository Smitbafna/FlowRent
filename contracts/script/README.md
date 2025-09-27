# FlowRent Deployment Scripts

This directory contains scripts for deploying the FlowRent system to different blockchain networks.

## Script Architecture

The deployment scripts follow a modular approach, broken down into sequential steps:

### Main Deployment Scripts

1. `Deploy01Registry.s.sol` - Deploys Registry components
2. `Deploy02Factory.s.sol` - Deploys Factory components
3. `Deploy03Components.s.sol` - Deploys core system components (Escrow, Oracle)
4. `Deploy04Setup.s.sol` - Performs final configuration and setup

### Orchestration Scripts

- `DeployFlowRentSystem.s.sol` - Deploys the entire system in one script
- `DeployFlowRentOrchestrator.s.sol` - Provides guidance on the deployment process

### Cross-chain Scripts

- `DeployProofOfHumanOApp.s.sol` - Deploys the LayerZero OApp for verification
- `DeployProofOfHumanReceiver.s.sol` - Deploys the receiver for cross-chain verification

### Shell Script Helpers

- `deploy-modular-flowrent.sh` - Automates the full modular deployment flow
- `deploy-components.sh` - Deploys individual components
- `deploy-oapp-cross-chain.sh` - Specifically for cross-chain components
- `verify-contracts.sh` - Verifies deployed contracts on explorers

## Deployment Flow

The deployment flow is designed to be flexible and modular:

1. **Registry Deployment**: Establishes the central registry for tracking deployments
2. **Factory Deployment**: Creates factory contracts that can spawn new components
3. **Components Deployment**: Deploys the core system functionality
4. **Setup**: Configures permissions, links components, and initializes the system

## Environment Variables

The scripts rely on environment variables that should be set before running:

```
# Core addresses
PRIVATE_KEY=<deployer_private_key>
NETWORK_NAME=<network_name>  # e.g., arbitrum-sepolia

# RPC URLs
ARBITRUM_SEPOLIA_RPC_URL=<arbitrum_sepolia_rpc_url>
OPTIMISM_SEPOLIA_RPC_URL=<optimism_sepolia_rpc_url>
BASE_SEPOLIA_RPC_URL=<base_sepolia_rpc_url>

# Dependencies
LAYERZERO_ENDPOINT_ADDRESS=<layerzero_endpoint>
PYUSD_TOKEN_ADDRESS=<pyusd_address>
VERIFICATION_CONTRACT_ADDRESS=<self_verification_contract>
SABLIER_LOCKUP_ADDRESS=<sablier_address>
```

## Running the Deployment

To deploy the complete system:

```bash
source .env
forge script script/DeployFlowRentSystem.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
```

To deploy modularly:

```bash
source .env
forge script script/Deploy01Registry.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
# Save output addresses to .env.registry

source .env.registry
forge script script/Deploy02Factory.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
# Save output addresses to .env.factory

# Continue with remaining steps
```

## After Deployment

After deployment, each script outputs environment variables that should be saved for the next step in the process. These values can be saved to separate files like:

- `.env.registry` - Registry deployment addresses
- `.env.factory` - Factory deployment addresses
- `.env.components` - Component deployment addresses

## Cross-chain Deployment

For cross-chain deployments, additional steps are needed:

1. Deploy to the primary chain first
2. Set up cross-chain contracts on secondary chains
3. Configure LayerZero endpoints and trusted remotes
4. Register cross-chain deployments in the primary chain's registry

## Verification

After deployment, contracts can be verified using:

```bash
source .env.combined  # Combined addresses from all deployments
./script/verify-contracts.sh
```
