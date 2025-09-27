"use client";

import { ethers } from 'ethers';
import { 
  ProofOfHumanOAppABI, 
  ProofOfHumanReceiverABI, 
  FlowRentEscrowABI, 
  FlowRentOracleABI,
  FlowRentPYUSDOFTABI,
  FlowRentPYUSDSablierABI
} from '../abis';

// Basic PYUSD ABI for token operations
export const PYUSDABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function balanceOf(address account) external view returns (uint256)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "function transfer(address to, uint256 amount) external returns (bool)"
];

// Network configurations
export const NETWORKS = {
  // Testnets
  CELO_ALFAJORES: {
    chainId: 44787,
    name: 'Celo Alfajores Testnet',
    rpcUrl: 'https://alfajores-forno.celo-testnet.org',
    explorer: 'https://alfajores.celoscan.io',
    nativeCurrency: { name: 'CELO', symbol: 'CELO', decimals: 18 }
  },
  ARBITRUM_SEPOLIA: {
    chainId: 421614,
    name: 'Arbitrum Sepolia',
    rpcUrl: 'https://sepolia-rollup.arbitrum.io/rpc',
    explorer: 'https://sepolia.arbiscan.io',
    nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 }
  },
  
  // Mainnets
  CELO_MAINNET: {
    chainId: 42220,
    name: 'Celo Mainnet',
    rpcUrl: 'https://forno.celo.org',
    explorer: 'https://explorer.celo.org',
    nativeCurrency: { name: 'CELO', symbol: 'CELO', decimals: 18 }
  },
  ARBITRUM_ONE: {
    chainId: 42161,
    name: 'Arbitrum One',
    rpcUrl: 'https://arb1.arbitrum.io/rpc',
    explorer: 'https://arbiscan.io',
    nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 }
  }
};

// Environment settings
export const IS_PRODUCTION = process.env.NEXT_PUBLIC_NETWORK === 'mainnet';

// Selected networks based on environment
export const SOURCE_NETWORK = IS_PRODUCTION ? NETWORKS.CELO_MAINNET : NETWORKS.CELO_ALFAJORES;
export const DESTINATION_NETWORK = IS_PRODUCTION ? NETWORKS.ARBITRUM_ONE : NETWORKS.ARBITRUM_SEPOLIA;

// Contract addresses - update with your deployed addresses
// These would ideally come from a deployment configuration file
export const CONTRACT_ADDRESSES = {
  // On Source Network (Celo)
  PROOF_OF_HUMAN_OAPP: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853", // Testnet address
  
  // On Destination Network (Arbitrum)
  PROOF_OF_HUMAN_RECEIVER: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6", // Testnet address
  
  FLOW_RENT_ESCROW: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0x82D8F4a2eF077f2ec32B18c3AF122d4e54a3e9eb", // Testnet address (fixed checksum)
  
  FLOW_RENT_ORACLE: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0x6E516cEc157aE5122e7a75F2Fb89C5dD45Db5af9", // Testnet address
  
  FLOW_RENT_PYUSD_OFT: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0x1F8ec2E3a4B15a29037aC68Cf5378970A13457D", // Testnet address (fixed typo in address)
  
  FLOW_RENT_PYUSD_SABLIER: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0x1C98D588C3CAD0e554De11aB876447520891f58F", // Testnet address
  
  // Token addresses
  PYUSD_TOKEN: IS_PRODUCTION 
    ? "0x0000000000000000000000000000000000000000" // Production address
    : "0x933FcF5D313D67b639ACb3c0d415621e1E522aF5", // Testnet address
};

// Contract instance getters
export const getContract = (
  address: string, 
  abi: any, 
  providerOrSigner: ethers.Provider | ethers.Signer
) => {
  if (!address || address === "0x0000000000000000000000000000000000000000") {
    throw new Error("Contract address not configured");
  }
  // Ensure address has proper checksum
  try {
    const checksummedAddress = ethers.getAddress(address);
    return new ethers.Contract(checksummedAddress, abi, providerOrSigner);
  } catch (error) {
    console.error("Invalid address format:", error);
    throw new Error(`Invalid contract address format: ${address}`);
  }
};

// Contract-specific getters
export const getProofOfHumanOApp = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.PROOF_OF_HUMAN_OAPP, ProofOfHumanOAppABI, providerOrSigner);
};

export const getProofOfHumanReceiver = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.PROOF_OF_HUMAN_RECEIVER, ProofOfHumanReceiverABI, providerOrSigner);
};

export const getFlowRentEscrow = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.FLOW_RENT_ESCROW, FlowRentEscrowABI, providerOrSigner);
};

export const getFlowRentOracle = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.FLOW_RENT_ORACLE, FlowRentOracleABI, providerOrSigner);
};

export const getFlowRentPYUSDOFT = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.FLOW_RENT_PYUSD_OFT, FlowRentPYUSDOFTABI, providerOrSigner);
};

export const getFlowRentPYUSDSablier = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.FLOW_RENT_PYUSD_SABLIER, FlowRentPYUSDSablierABI, providerOrSigner);
};

export const getPYUSDToken = (providerOrSigner: ethers.Provider | ethers.Signer) => {
  return getContract(CONTRACT_ADDRESSES.PYUSD_TOKEN, PYUSDABI, providerOrSigner);
};

// Wallet state type
export interface WalletState {
  account: string | null;
  chainId: number | null;
  provider: ethers.Provider | null;
  signer: ethers.Signer | null;
  isConnected: boolean;
  isCorrectChain: boolean;
}

// Default wallet state
export const defaultWalletState: WalletState = {
  account: null,
  chainId: null,
  provider: null,
  signer: null,
  isConnected: false,
  isCorrectChain: false
};

// Wallet connection helper
export const connectWallet = async (): Promise<WalletState> => {
  if (typeof window.ethereum === 'undefined') {
    throw new Error('Please install MetaMask or another Ethereum wallet');
  }
  
  try {
    // Request account access
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new ethers.BrowserProvider(window.ethereum);
    const network = await provider.getNetwork();
    const signer = await provider.getSigner();
    const chainId = Number(network.chainId);
    
    // Check if on correct chain for current operation
    // This checks if the wallet is connected to either the source or destination chain
    const isCorrectChain = 
      chainId === SOURCE_NETWORK.chainId || 
      chainId === DESTINATION_NETWORK.chainId;
    
    return {
      account: accounts[0],
      chainId,
      provider,
      signer,
      isConnected: true,
      isCorrectChain
    };
  } catch (error) {
    console.error('Error connecting wallet:', error);
    return defaultWalletState;
  }
};

// Switch to the specified network
export const switchToNetwork = async (network: typeof SOURCE_NETWORK | typeof DESTINATION_NETWORK): Promise<boolean> => {
  if (typeof window.ethereum === 'undefined') {
    throw new Error('Please install MetaMask or another Ethereum wallet');
  }
  
  const chainIdHex = `0x${network.chainId.toString(16)}`;
  
  try {
    // First try to switch to the network
    await window.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: chainIdHex }]
    });
    return true;
  } catch (error: any) {
    // This error code indicates the chain has not been added to MetaMask
    if (error.code === 4902) {
      try {
        // Add the network
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: chainIdHex,
            chainName: network.name,
            nativeCurrency: network.nativeCurrency,
            rpcUrls: [network.rpcUrl],
            blockExplorerUrls: [network.explorer]
          }]
        });
        return true;
      } catch (addError) {
        console.error('Error adding network:', addError);
        return false;
      }
    } else {
      console.error('Error switching network:', error);
      return false;
    }
  }
};

// Helper functions to switch to specific networks
export const switchToSourceNetwork = () => switchToNetwork(SOURCE_NETWORK);
export const switchToDestinationNetwork = () => switchToNetwork(DESTINATION_NETWORK);

// Listen for network changes
export const setupNetworkListeners = (callback: (chainId: number) => void): (() => void) => {
  if (typeof window.ethereum === 'undefined') {
    return () => {}; // Return empty cleanup function if no ethereum
  }
  
  const handleChainChanged = (chainId: string) => {
    // Handle the new chain
    callback(parseInt(chainId, 16));
  };
  
  window.ethereum.on('chainChanged', handleChainChanged);
  
  // Return cleanup function
  return () => {
    window.ethereum.removeListener('chainChanged', handleChainChanged);
  };
};
