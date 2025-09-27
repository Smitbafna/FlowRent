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
