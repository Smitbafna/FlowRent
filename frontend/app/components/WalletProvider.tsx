"use client";

import React, { createContext, useState, useContext, useEffect, ReactNode } from 'react';
import { connectWallet, WalletState, defaultWalletState, setupNetworkListeners } from '../utils/contracts';

// Create context for wallet state management
interface WalletContextType {
  walletState: WalletState;
  connect: () => Promise<void>;
  disconnect: () => void;
  isLoading: boolean;
}

const WalletContext = createContext<WalletContextType>({
  walletState: defaultWalletState,
  connect: async () => {},
  disconnect: () => {},
  isLoading: false,
});

// Hook for easy access to wallet state
export const useWallet = () => useContext(WalletContext);

interface WalletProviderProps {
  children: ReactNode;
}

export const WalletProvider: React.FC<WalletProviderProps> = ({ children }) => {
  const [walletState, setWalletState] = useState<WalletState>(defaultWalletState);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  
  // Auto-connect wallet on initial load if previously connected
  useEffect(() => {
    const autoConnect = async () => {
      // Check if we should auto-connect
      if (typeof window !== 'undefined' && 
          localStorage.getItem('walletConnected') === 'true' && 
          window.ethereum?.isConnected?.()) {
        try {
          setIsLoading(true);
          const state = await connectWallet();
          setWalletState(state);
        } catch (error) {
          console.error('Auto-connect failed:', error);
        } finally {
          setIsLoading(false);
        }
      }
    };
    
    autoConnect();
  }, []);
  
  // Setup network change listeners
  useEffect(() => {
    const cleanup = setupNetworkListeners(async (chainId) => {
      if (walletState.isConnected) {
        try {
          setIsLoading(true);
          // Reconnect to get fresh state with new chain info
          const state = await connectWallet();
          setWalletState(state);
        } catch (error) {
          console.error('Failed to update on chain change:', error);
        } finally {
          setIsLoading(false);
        }
      }
    });
    
    // Setup account change listener
    const handleAccountsChanged = async (accounts: string[]) => {
      if (accounts.length === 0) {
        // User disconnected their wallet
        disconnect();
      } else if (walletState.account !== accounts[0] && walletState.isConnected) {
        // Account changed, update state
        try {
          setIsLoading(true);
          const state = await connectWallet();
          setWalletState(state);
        } catch (error) {
          console.error('Failed to update on account change:', error);
        } finally {
          setIsLoading(false);
        }
      }
    };
    
    if (typeof window !== 'undefined' && window.ethereum) {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
    }
    
    return () => {
      cleanup();
      if (typeof window !== 'undefined' && window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      }
    };
  }, [walletState.isConnected, walletState.account]);
  
  // Connect wallet function
  const connect = async () => {
    try {
      setIsLoading(true);
      const state = await connectWallet();
      setWalletState(state);
      
      // Save connection state to localStorage
      if (state.isConnected) {
        localStorage.setItem('walletConnected', 'true');
      }
    } catch (error) {
      console.error('Failed to connect wallet:', error);
    } finally {
      setIsLoading(false);
    }
  };
  
  // Disconnect wallet function
  const disconnect = () => {
    setWalletState(defaultWalletState);
    localStorage.removeItem('walletConnected');
  };
  
  const contextValue = {
    walletState,
    connect,
    disconnect,
    isLoading,
  };
  
  return (
    <WalletContext.Provider value={contextValue}>
      {children}
    </WalletContext.Provider>
  );
};

export default WalletProvider;
