# FlowRent - Split Contract Architecture

## The Problem: Contract Size Limit Exceeded

The original `FlowRentFactory.sol` contract was exceeding the Ethereum/EVM contract size limit of 24,576 bytes. The contract was approximately 43,332 bytes, which is almost double the allowed size.

```
Error: Contract code size is 43,332 bytes and exceeds 24,576 bytes (a limit introduced in Spurious Dragon)
```

## The Solution: Contract Splitting Pattern

To address this issue, we've implemented a contract splitting pattern, where we:

1. Created a core contract (`FlowRentFactoryCore.sol`) that handles essential functionality:
   - Basic deployment of FlowRent ecosystem contracts
   - Managing deployment records
   - Registration of vehicles and assets

2. Created an extension contract (`FlowRentFactoryExtension.sol`) that handles specialized functionality:
   - LayerZero cross-chain operations
   - OFT token wrapper deployments
   - Cross-chain rental management

3. Updated the deployment script to work with the split contract architecture.

## Contract Structure

### FlowRentFactoryCore.sol

The core contract contains the essential functionality needed for deploying and managing FlowRent contracts:

- Deployment of Escrow, Oracle, and other contracts
- Storage of deployment details by network
- Vehicle registration and pricing management
- Contract validation

### FlowRentFactoryExtension.sol

The extension contract handles all cross-chain functionality:

- LayerZero network configuration
- Cross-chain deployment and communication
- OFT token wrapper deployment and management
- Cross-chain rental initiation and payment processing

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
                            │ LayerZero/        │
                            │ Cross-chain logic │
                            │                   │
                            └───────────────────┘
```

## Deployment

A new deployment script (`DeployFlowRentSplit.s.sol`) has been created to deploy both contracts and set up their relationship. The script:

1. Deploys the `FlowRentFactoryCore` contract
2. Deploys the `FlowRentFactoryExtension` contract, passing in the core contract address
3. Uses the core contract to deploy FlowRent components
4. Sets up the LayerZero configuration via the extension contract

## How to Use

Deploy the contracts using the new deployment script:

```shell
forge script script/DeployFlowRentSplit.s.sol:DeployFlowRentEscrow --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

## Advantages of This Approach

1. **Maintainability**: Separates cross-chain concerns from core deployment functionality
2. **Upgradability**: Each contract can be upgraded independently
3. **Reduced Gas Costs**: Smaller contracts mean lower deployment costs
4. **Focused Functionality**: Each contract has a clear, focused responsibility

## Further Optimizations

If needed, the contracts could be further split to reduce size even more:
- Separate vehicle management into its own contract
- Create a dedicated cross-chain payment processor
- Move rental management to a specialized contract
