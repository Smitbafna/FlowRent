"use client";

import { useWallet } from '../context/WalletProvider';
import { switchToSourceNetwork, switchToDestinationNetwork, SOURCE_NETWORK, DESTINATION_NETWORK } from '../utils/contracts';
import React from 'react';

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
    account, 
    chainId, 
    isConnected, 
    isCorrectChain,
    connect, 
    disconnect, 
    isLoading 
  } = useWallet();
  
  // Format address for display
  const formatAddress = (address: string) => {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };
  
  // Get wallet context functions for network switching
  const { switchToSource, switchToDestination } = useWallet();

  // Handle switching networks
  const handleSwitchNetwork = async (networkType: 'source' | 'destination') => {
    const switchFunction = networkType === 'source' 
      ? switchToSource 
      : switchToDestination;
    
    const networkName = networkType === 'source'
      ? SOURCE_NETWORK.name
      : DESTINATION_NETWORK.name;
    
    try {
      await switchFunction();
    } catch (error) {
      console.error(`Failed to switch to ${networkName}:`, error);
    }
  };
  
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

  if (isLoading) {
    return (
      <button 
        disabled
        className={`${buttonStyle} opacity-70`}
      >
        Loading...
      </button>
    );
  }
  
  if (!isConnected) {
    return (
      <button 
        onClick={connect}
        className={buttonStyle}
      >
        Connect Wallet
      </button>
    );
  }
  
  return (
    <div className="flex flex-col items-center space-y-2">
      <div className="flex items-center space-x-2">
        <button 
          onClick={disconnect}
          className={`px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md ${className}`}
        >
          {account ? formatAddress(account) : 'Disconnect'}
        </button>
        
        {/* Network indicator and switcher */}
        <div className="relative inline-block group">
          <button className="flex items-center space-x-1 px-3 py-2 bg-gray-100 rounded-md hover:bg-gray-200">
            <span className={`w-3 h-3 rounded-full ${isCorrectChain ? 'bg-green-500' : 'bg-red-500'}`}></span>
            <span>{chainId 
              ? (chainId === SOURCE_NETWORK.chainId 
                ? SOURCE_NETWORK.name 
                : chainId === DESTINATION_NETWORK.chainId 
                  ? DESTINATION_NETWORK.name
                  : chainId === 11155111 
                    ? 'Sepolia' 
                    : 'Switch Network')
              : 'No Network'}
            </span>
          </button>
          
          {/* Dropdown for network switching */}
          <div className="absolute right-0 mt-2 py-2 w-48 bg-white rounded-md shadow-xl z-50 invisible group-hover:visible">
            <button 
              onClick={() => handleSwitchNetwork('source')}
              className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 w-full text-left"
            >
              Switch to {SOURCE_NETWORK.name}
            </button>
            <button 
              onClick={() => handleSwitchNetwork('destination')}
              className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 w-full text-left"
            >
              Switch to {DESTINATION_NETWORK.name}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ConnectWalletButton;
