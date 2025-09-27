#!/bin/bash

# This script sets the required environment variables and runs the component deployment

# Load environment variables from .env
source .env

# Set environment variables for Deploy03Components.s.sol
export NETWORK_NAME="arbitrum-sepolia"
export PYUSD_TOKEN_ADDRESS="$PYUSD_ARB_SEPOLIA"
export LZ_CHAIN_ID=10143
export IS_NATIVE_PYUSD=true

# Display configuration
echo "===== Component Deployment Configuration ====="
echo "Network: $NETWORK_NAME"
echo "PYUSD Token: $PYUSD_TOKEN_ADDRESS"
echo "LayerZero Chain ID: $LZ_CHAIN_ID"
echo "Is Native PYUSD: $IS_NATIVE_PYUSD"
echo "RPC URL: $ARBITRUM_SEPOLIA_RPC_URL"
echo "Factory Core: $FLOWRENT_FACTORY_CORE_ADDRESS"
echo "Registry: $FLOWRENT_REGISTRY_ADDRESS" 
echo "Registry Extension: $FLOWRENT_REGISTRY_EXTENSION_ADDRESS"
echo "============================================"

# Run the deployment script
forge script script/Deploy03Components.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
