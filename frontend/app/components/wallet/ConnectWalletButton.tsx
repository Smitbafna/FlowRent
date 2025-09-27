"use client";

import React from 'react';
import { useWallet } from '../../context/WalletProvider';
import { SOURCE_NETWORK, DESTINATION_NETWORK } from '../../utils/contracts';

interface ConnectWalletButtonProps {
  className?: string;
  variant?: 'primary' | 'secondary' | 'outline';
  size?: 'sm' | 'md' | 'lg';
}

const ConnectWalletButton: React.FC<ConnectWalletButtonProps> = ({
  className = '',
  variant = 'primary',
  size = 'md'
}) => {
  const { 
    isConnected, 
    account, 
    chainId, 
    isCorrectChain, 
    connect, 
    switchToSource,
    switchToDestination,
    isLoading 
  } = useWallet();

  // Determine button style based on variant
  const baseStyle = "font-semibold rounded-lg transition-all duration-200 flex items-center justify-center";
  const sizeStyle = {
    sm: "px-4 py-2 text-sm",
    md: "px-6 py-3 text-base",
    lg: "px-8 py-4 text-lg"
  };

  const variantStyle = {
    primary: "bg-teal-600 hover:bg-teal-700 text-white",
    secondary: "bg-purple-600 hover:bg-purple-700 text-white",
    outline: "border-2 border-teal-600 text-teal-600 hover:bg-teal-600 hover:text-white"
  };

  const buttonStyle = `${baseStyle} ${sizeStyle[size]} ${variantStyle[variant]} ${className}`;

  // Format account address for display
  const formatAddress = (address: string) => {
    return `${address.substring(0, 6)}...${address.substring(address.length - 4)}`;
  };

  // Handle wallet actions
  const handleWalletAction = async () => {
    if (isLoading) return;
    
    if (!isConnected) {
      await connect();
      return;
    }
    
    if (!isCorrectChain) {
      // Try to switch to source network first, then destination if that fails
      const sourceSuccess = await switchToSource();
      if (!sourceSuccess) {
        await switchToDestination();
      }
    }
  };

  // Get network name based on chainId
  const getNetworkName = (id: number | null) => {
    if (id === SOURCE_NETWORK.chainId) return SOURCE_NETWORK.name;
    if (id === DESTINATION_NETWORK.chainId) return DESTINATION_NETWORK.name;
    return 'Unknown Network';
  };

  return (
    <button 
      onClick={handleWalletAction}
      className={buttonStyle}
      disabled={isLoading}
    >
      {isLoading ? (
        <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
      ) : null}
      
      {isLoading ? 'Processing...' : 
        !isConnected ? 'Connect Wallet' : 
        !isCorrectChain ? 'Switch Network' : 
        formatAddress(account || '')
      }
      
      {isConnected && isCorrectChain && (
        <span className="ml-2 text-xs bg-green-500 rounded-full w-2 h-2"></span>
      )}
    </button>
  );
};

export default ConnectWalletButton;
