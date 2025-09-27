"use client";

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  WalletState, 
  defaultWalletState,
  connectWallet, 
  setupNetworkListeners,
  switchToSourceNetwork,
  switchToDestinationNetwork,
  SOURCE_NETWORK,
  DESTINATION_NETWORK
} from '../utils/contracts';

// Context for wallet state
interface WalletContextType extends WalletState {
  connect: () => Promise<void>;
  disconnect: () => void;
  switchToSource: () => Promise<boolean>;
  switchToDestination: () => Promise<boolean>;
  isLoading: boolean;
  error: string | null;
}

const defaultContext: WalletContextType = {
  ...defaultWalletState,
  connect: async () => {},
  disconnect: () => {},
  switchToSource: async () => false,
  switchToDestination: async () => false,
  isLoading: false,
  error: null
};

const WalletContext = createContext<WalletContextType>(defaultContext);

export const useWallet = () => useContext(WalletContext);

interface WalletProviderProps {
  children: ReactNode;
}

export const WalletProvider: React.FC<WalletProviderProps> = ({ children }) => {
  const [walletState, setWalletState] = useState<WalletState>(defaultWalletState);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Auto-connect if previously connected
  useEffect(() => {
    const checkConnection = async () => {
      if (typeof window === 'undefined') return;
      
      // Check if wallet was previously connected
      const shouldAutoConnect = localStorage.getItem('wallet_connected') === 'true';
      
      if (shouldAutoConnect && typeof window.ethereum !== 'undefined' && window.ethereum.isConnected()) {
        try {
          setIsLoading(true);
          const state = await connectWallet();
          setWalletState(state);
        } catch (e) {
          // Silent fail on auto-connect
          console.log('Auto-connect failed:', e);
        } finally {
          setIsLoading(false);
        }
      }
    };

    checkConnection();
  }, []);

  // Setup network and account change listeners
  useEffect(() => {
    if (typeof window === 'undefined' || !window.ethereum) return;
    
    // Network change listener
    const chainChangeHandler = (chainId: string) => {
      const numericChainId = parseInt(chainId, 16);
      setWalletState((prev) => ({
        ...prev,
        chainId: numericChainId,
        isCorrectChain: 
          numericChainId === SOURCE_NETWORK.chainId || 
          numericChainId === DESTINATION_NETWORK.chainId
      }));
    };
    
    // Account change listener
    const accountsChangedHandler = async (accounts: string[]) => {
      if (accounts.length === 0) {
        // User disconnected wallet
        disconnect();
      } else if (accounts[0] !== walletState.account) {
        // Account changed, update state
        try {
          const state = await connectWallet();
          setWalletState(state);
        } catch (e) {
          console.error('Failed to update on account change:', e);
        }
      }
    };
    
    window.ethereum.on('chainChanged', chainChangeHandler);
    window.ethereum.on('accountsChanged', accountsChangedHandler);
    
    // Cleanup listeners
    return () => {
      window.ethereum.removeListener('chainChanged', chainChangeHandler);
      window.ethereum.removeListener('accountsChanged', accountsChangedHandler);
    };
  }, [walletState.account]);

  // Connect wallet function
  const connect = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const state = await connectWallet();
      setWalletState(state);
      
      // Save connection state to localStorage
      if (state.isConnected) {
        localStorage.setItem('wallet_connected', 'true');
      }
    } catch (e: any) {
      setError(e.message || 'Failed to connect wallet');
      console.error('Connect error:', e);
    } finally {
      setIsLoading(false);
    }
  };

  // Disconnect wallet function
  const disconnect = () => {
    setWalletState(defaultWalletState);
    localStorage.removeItem('wallet_connected');
  };

  // Switch to source network
  const switchToSource = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const success = await switchToSourceNetwork();
      if (success) {
        setWalletState((prev) => ({
          ...prev,
          chainId: SOURCE_NETWORK.chainId,
          isCorrectChain: true
        }));
      }
      return success;
    } catch (e: any) {
      setError(e.message || 'Failed to switch network');
      console.error('Network switch error:', e);
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  // Switch to destination network
  const switchToDestination = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const success = await switchToDestinationNetwork();
      if (success) {
        setWalletState((prev) => ({
          ...prev,
          chainId: DESTINATION_NETWORK.chainId,
          isCorrectChain: true
        }));
      }
      return success;
    } catch (e: any) {
      setError(e.message || 'Failed to switch network');
      console.error('Network switch error:', e);
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <WalletContext.Provider
      value={{
        ...walletState,
        connect,
        disconnect,
        switchToSource,
        switchToDestination,
        isLoading,
        error
      }}
    >
      {children}
    </WalletContext.Provider>
  );
};
