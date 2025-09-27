#!/bin/bash

# fix-registry-ownership.sh
# A script to fix ownership issues between Registry and Factory Core

set -e # Exit on error

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found! Please create one before running this script."
    exit 1
fi

# Load environment variables
source .env

# Check required environment variables
REQUIRED_VARS=(
    "PRIVATE_KEY"
    "ARBITRUM_SEPOLIA_RPC_URL"
    "FLOWRENT_REGISTRY_ADDRESS"
    "FLOWRENT_REGISTRY_EXTENSION_ADDRESS"
    "FLOWRENT_FACTORY_CORE_ADDRESS"
)

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "Error: Required environment variable $VAR is not set in .env file!"
        exit 1
    fi
done

# Display current addresses
echo "==== Registry Ownership Fix Tool ===="
echo "Network: $ARBITRUM_SEPOLIA_RPC_URL"
echo "Registry: $FLOWRENT_REGISTRY_ADDRESS"
echo "Registry Extension: $FLOWRENT_REGISTRY_EXTENSION_ADDRESS" 
echo "Factory Core: $FLOWRENT_FACTORY_CORE_ADDRESS"
echo "====================================="

# Confirm before proceeding
read -p "This will transfer ownership of Registry and Registry Extension to Factory Core. Continue? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Run the ownership transfer script
echo "Transferring ownership..."
forge script script/TransferRegistryOwnership.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast

# Check result
if [ $? -eq 0 ]; then
    echo "✅ Registry ownership successfully transferred to Factory Core!"
    echo "You can now proceed with component deployment"
else
    echo "❌ Error: Ownership transfer failed!"
    exit 1
fi

exit 0
