#!/bin/bash

# deploy-modular-flowrent.sh
# A script for deploying FlowRent system modularly

set -e # Exit on error

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found! Please create one before running this script."
    exit 1
fi

# Load environment variables
source .env

# Set environment variables for deployment
export PYUSD_TOKEN_ADDRESS=$PYUSD_ARB_SEPOLIA
export NETWORK_NAME=${NETWORK_NAME:-"arbitrum-sepolia"}
export LZ_CHAIN_ID=${LZ_CHAIN_ID:-10143}
export IS_NATIVE_PYUSD=${IS_NATIVE_PYUSD:-true}

# Display settings
echo "Network: $NETWORK_NAME"
echo "PYUSD Token: $PYUSD_TOKEN_ADDRESS"
echo "LayerZero Chain ID: $LZ_CHAIN_ID"
echo "Is Native PYUSD: $IS_NATIVE_PYUSD"
echo "RPC URL: $ARBITRUM_SEPOLIA_RPC_URL"

# Check required environment variables
REQUIRED_VARS=(
    "PRIVATE_KEY"
    "ARBITRUM_SEPOLIA_RPC_URL"
    "PYUSD_ARB_SEPOLIA"
    "VERIFICATION_CONTRACT_ADDRESS"
    "SABLIER_LOCKUP_ADDRESS"
    "LAYERZERO_ENDPOINT_ADDRESS"
)

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        echo "Error: Required environment variable $VAR is not set in .env file!"
        exit 1
    fi
done

# Function to display usage information
function show_usage() {
    echo "Usage: ./deploy-modular-flowrent.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  all         Deploy all components sequentially"
    echo "  registry    Deploy only the Registry components (step 1)"
    echo "  factory     Deploy only the Factory components (step 2)"
    echo "  ownership   Transfer Registry ownership to Factory Core (step 2.5)"
    echo "  components  Deploy only the Escrow and Oracle components (step 3)"
    echo "  setup       Perform initial setup and configuration (step 4)"
    echo "  help        Display this help message"
    echo ""
    echo "Example: ./deploy-modular-flowrent.sh all"
}

# Function to deploy registry components (step 1)
function deploy_registry() {
    echo "=== Deploying Registry Components ==="
    forge script script/Deploy01Registry.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
    
    # Check if the deployment was successful
    if [ $? -eq 0 ]; then
        echo "Registry components deployed successfully!"
        echo "Please check the output for addresses and save them to .env"
    else
        echo "Error: Registry deployment failed!"
        exit 1
    fi
}

# Function to deploy factory components (step 2)
function deploy_factory() {
    echo "=== Deploying Factory Components ==="
    # Check if registry addresses are set
    if [ -z "$FLOWRENT_REGISTRY_ADDRESS" ] || [ -z "$FLOWRENT_REGISTRY_EXTENSION_ADDRESS" ]; then
        echo "Error: Registry addresses not found in environment variables!"
        echo "Make sure to set FLOWRENT_REGISTRY_ADDRESS and FLOWRENT_REGISTRY_EXTENSION_ADDRESS after deploying the registry"
        exit 1
    fi
    
    forge script script/Deploy02Factory.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
    
    # Check if the deployment was successful
    if [ $? -eq 0 ]; then
        echo "Factory components deployed successfully!"
        echo "Please check the output for addresses and save them to .env"
    else
        echo "Error: Factory deployment failed!"
        exit 1
    fi
}

# Function to transfer registry ownership to factory core (between steps 2 and 3)
function transfer_registry_ownership() {
    echo "=== Transferring Registry Ownership to Factory Core ==="
    # Check if required addresses are set
    if [ -z "$FLOWRENT_REGISTRY_ADDRESS" ] || [ -z "$FLOWRENT_REGISTRY_EXTENSION_ADDRESS" ] || [ -z "$FLOWRENT_FACTORY_CORE_ADDRESS" ]; then
        echo "Error: Required addresses not found in environment variables!"
        echo "Make sure to set FLOWRENT_REGISTRY_ADDRESS, FLOWRENT_REGISTRY_EXTENSION_ADDRESS, and FLOWRENT_FACTORY_CORE_ADDRESS"
        exit 1
    fi
    
    forge script script/TransferRegistryOwnership.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast
    
    # Check if the ownership transfer was successful
    if [ $? -eq 0 ]; then
        echo "Registry ownership transferred successfully to Factory Core!"
    else
        echo "Error: Ownership transfer failed!"
        exit 1
    fi
}

# Function to deploy components (step 3)
function deploy_components() {
    echo "=== Deploying Escrow and Oracle Components ==="
    # Check if factory address is set
    if [ -z "$FLOWRENT_FACTORY_CORE_ADDRESS" ]; then
        echo "Error: Factory address not found in environment variables!"
        echo "Make sure to set FLOWRENT_FACTORY_CORE_ADDRESS after deploying the factory"
        exit 1
    fi
    
    forge script script/Deploy03Components.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
    
    # Check if the deployment was successful
    if [ $? -eq 0 ]; then
        echo "Escrow and Oracle components deployed successfully!"
        echo "Please check the output for addresses and save them to .env"
    else
        echo "Error: Components deployment failed!"
        exit 1
    fi
}

# Function to perform setup (step 4)
function perform_setup() {
    echo "=== Performing Initial Setup and Configuration ==="
    # Check if all required addresses are set
    if [ -z "$FLOWRENT_DEPLOY_HELPER_ADDRESS" ] || [ -z "$FLOWRENT_FACTORY_EXTENSION_ADDRESS" ] || [ -z "$FLOWRENT_ESCROW_ADDRESS" ] || [ -z "$FLOWRENT_ORACLE_ADDRESS" ]; then
        echo "Error: Required addresses not found in environment variables!"
        echo "Make sure to set all component addresses after previous deployment steps"
        exit 1
    fi
    
    forge script script/Deploy04Setup.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC_URL --broadcast --verify
    
    # Check if the setup was successful
    if [ $? -eq 0 ]; then
        echo "Initial setup completed successfully!"
        echo "The FlowRent system is now fully deployed and configured"
    else
        echo "Error: Setup failed!"
        exit 1
    fi
}

# Check command line arguments
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    "all")
        deploy_registry
        # Need to update .env with registry addresses here
        echo "Please update .env with the registry addresses before continuing"
        read -p "Press Enter after updating .env to continue with factory deployment..."
        source .env  # Reload environment variables
        
        deploy_factory
        # Need to update .env with factory addresses here
        echo "Please update .env with the factory addresses before continuing"
        read -p "Press Enter after updating .env to continue with ownership transfer..."
        source .env  # Reload environment variables
        
        transfer_registry_ownership
        echo "Registry ownership transferred to Factory Core"
        read -p "Press Enter to continue with components deployment..."
        
        deploy_components
        # Need to update .env with component addresses here
        echo "Please update .env with the component addresses before continuing"
        read -p "Press Enter after updating .env to continue with setup..."
        source .env  # Reload environment variables
        
        perform_setup
        ;;
    "registry")
        deploy_registry
        ;;
    "factory")
        deploy_factory
        ;;
    "ownership")
        transfer_registry_ownership
        ;;
    "components")
        deploy_components
        ;;
    "setup")
        perform_setup
        ;;
    "help")
        show_usage
        ;;
    *)
        echo "Error: Unknown option '$1'"
        show_usage
        exit 1
        ;;
esac

echo "Deployment process completed successfully!"
exit 0
