#!/bin/bash

# Load environment variables
source .env

echo "===== Direct Ownership Transfer Script ====="
echo "Registry: $FLOWRENT_REGISTRY_ADDRESS"
echo "Registry Extension: $FLOWRENT_REGISTRY_EXTENSION_ADDRESS"
echo "Factory Core: $FLOWRENT_FACTORY_CORE_ADDRESS"
echo "RPC URL: $ARBITRUM_SEPOLIA_RPC_URL"

# Run the transfer script
forge script script/TransferRegistryOwnership.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
