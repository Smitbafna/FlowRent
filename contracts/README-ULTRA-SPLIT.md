# FlowRent - Ultra-Split Contract Architecture

## The Problem: Contract Size Limit Exceeded

The original `FlowRentFactory.sol` contract was exceeding the Ethereum/EVM contract size limit of 24,576 bytes. The contract was approximately 43,332 bytes, which is almost double the allowed size. Even after initial splitting, one of the contracts was still over the limit at 28,369 bytes.

```
Error: Contract code size is 43,332 bytes and exceeds 24,576 bytes (a limit introduced in Spurious Dragon)
Error: `Unknown0` is above the contract size limit (28369 > 24576).
```

## The Solution: Ultra-Split Contract Pattern

To address this issue, we've implemented an advanced contract splitting pattern with three contracts:

1. **Core Contract** (`FlowRentFactoryCore.sol`): Handles essential functionality:
   - Basic deployment of FlowRent ecosystem contracts
   - Managing deployment records
   - Contract validation logic

2. **Extension Contract** (`FlowRentFactoryExtension.sol`): Handles specialized functionality:
   - LayerZero cross-chain operations
   - OFT token wrapper deployments
   - Cross-chain rental management

3. **Helper Contract** (`FlowRentDeployHelper.sol`): Handles batch operations:
   - Vehicle registration in batches
   - Pricing data updates
   - Other utility functions

4. Updated the deployment script to work with the ultra-split contract architecture.

## Contract Structure

### FlowRentFactoryCore.sol

The minimal core contract contains only the absolutely essential functionality:
- Deployment of Escrow, Oracle, and other contracts
- Storage of deployment details by network
- Contract validation
- Configuration of core parameters

### FlowRentFactoryExtension.sol

The extension contract handles all cross-chain functionality:
- LayerZero network configuration
- Cross-chain deployment and communication
- OFT token wrapper deployment and management
- Cross-chain rental initiation and payment processing

### FlowRentDeployHelper.sol

The helper contract handles batch operations and utility functions:
- Batch vehicle registration
- Batch pricing data updates
- Helper methods for fetching deployment information

### Architecture Diagram

```
                           ┌──────────────────┐
                           │                  │
                           │ FlowRentFactory  │
                           │      Core        │
                           │                  │
                           └────┬───────┬─────┘
                                │       │
                 references     │       │     references
                 ┌──────────────┘       └───────────────┐
                 │                                      │
    ┌────────────▼─────────────┐          ┌─────────────▼────────────┐
    │                          │          │                          │
    │ FlowRentFactoryExtension │          │   FlowRentDeployHelper   │
    │                          │          │                          │
    └──────────────────────────┘          └──────────────────────────┘

          Cross-chain Logic                    Batch Operations
```

## Deployment

A new deployment script (`DeployFlowRentSplitFurther.s.sol`) has been created to deploy all three contracts and set up their relationships. The script:

1. Deploys the `FlowRentFactoryCore` contract
2. Deploys the `FlowRentDeployHelper` contract, passing in the core contract address
3. Deploys the `FlowRentFactoryExtension` contract, passing in the core contract address
4. Uses the core contract to deploy FlowRent components
5. Transfers Oracle ownership to the helper contract
6. Uses the helper contract for batch vehicle setup
7. Sets up the LayerZero configuration via the extension contract

> **Important Note**: The Oracle contract ownership must be transferred to the helper contract to allow vehicle registration. This was fixed in the latest deployment script.

## How to Use

Deploy the contracts using the updated deployment script:

```shell
forge script script/DeployFlowRentSplitFurther.s.sol:DeployFlowRentSplitFurther --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast -vvv
```

Or use the shell script:

```shell
./deployment/deploy-flowrent.sh
```

## Advantages of This Approach

1. **Size Optimization**: Each contract is well below the 24,576 byte limit
2. **Clear Separation of Concerns**: Core deployment, cross-chain, and batch operations are separated
3. **Reduced Gas Costs**: Smaller contracts mean lower deployment costs
4. **Focused Functionality**: Each contract has a clear, focused responsibility
5. **Independent Upgradability**: Each contract can be upgraded independently

## Further Optimizations

If needed, more optimizations could be applied:
- Use libraries for common functions
- Further simplify interfaces between contracts
- Use minimal proxy patterns for repeated contract deployments
