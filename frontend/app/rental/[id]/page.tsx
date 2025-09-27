"use client";

import React, { useState, useEffect } from 'react';
import Header from '../../components/Header';
import { ethers } from 'ethers';
import { 
  connectWallet, 
  switchToSourceNetwork,
  switchToDestinationNetwork, 
  getProofOfHumanOApp, 
  getProofOfHumanReceiver,
  getFlowRentEscrow,
  getFlowRentPYUSDSablier,
  getPYUSDToken,
  CONTRACT_ADDRESSES
} from '../../utils/contracts';
import { FlowRentEscrowABI } from '../../abis';

interface Props {
  params: { id: string };
}

interface Vehicle {
  id: string;
  type: 'car' | 'motorcycle' | 'truck' | 'scooter';
  deposit: number;
  hourlyRate: number;
  estimatedDuration: string;
  distance?: string;
  route?: string;
  location: string;
  available: boolean;
  rating: number;
}


const mockVehicles: Vehicle[] = [
  {
    id: '1',
    type: 'car',
    deposit: 25,
    hourlyRate: 5,
    estimatedDuration: '1-2 hours',
    distance: '6km',
    route: 'Mumbai, India → Pune, India',
    location: 'Mumbai, India',
    available: true,
    rating: 4.8
  },
  {
    id: '2',
    type: 'motorcycle',
    deposit: 20,
    hourlyRate: 3,
    estimatedDuration: '2-4 hours',
    distance: '12km',
    route: 'Delhi, India → Gurgaon, India',
    location: 'Delhi, India',
    available: true,
    rating: 4.6
  },
  {
    id: '3',
    type: 'truck',
    deposit: 40,
    hourlyRate: 8,
    estimatedDuration: '3-5 hours',
    distance: '25km',
    route: 'Bangalore, India → Mysore, India',
    location: 'Bangalore, India',
    available: true,
    rating: 4.3
  },
  {
    id: '4',
    type: 'scooter',
    deposit: 15,
    hourlyRate: 2,
    estimatedDuration: '1-2 hours',
    distance: '4km',
    route: 'Chennai, India → Adyar, India',
    location: 'Chennai, India',
    available: true,
    rating: 4.9
  }
];

export default function VehiclePage({ params }: Props) {
  const { id } = params;
  const [vehicle, setVehicle] = useState<Vehicle | null>(null);
  const [walletAddress, setWalletAddress] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);
  const [txHash, setTxHash] = useState<string>('');
  const [rentalDetails, setRentalDetails] = useState<any>(null);

  useEffect(() => {
    // Find vehicle by ID
    const foundVehicle = mockVehicles.find(v => v.id === id);
    setVehicle(foundVehicle || null);

    // Check wallet connection
    checkWalletConnection();
    
    // If we have a vehicle ID and wallet is connected, check if it's currently rented
    if (foundVehicle && walletAddress) {
      getRentalInfo(foundVehicle.id)
        .then(rentalInfo => {
          if (rentalInfo && rentalInfo.active) {
            console.log("Current rental info:", rentalInfo);
            setRentalDetails(rentalInfo);
          }
        });
    }
  }, [id, walletAddress]);

  const checkWalletConnection = async () => {
    if (typeof window !== 'undefined' && (window as any).ethereum) {
      try {
        const accounts = await (window as any).ethereum.request({ 
          method: 'eth_accounts' 
        });
        if (accounts.length > 0) {
          setWalletAddress(accounts[0]);
        }
      } catch (error) {
        console.error('Error checking wallet connection:', error);
      }
    }
  };

  const connectWallet = async () => {
    if (typeof window !== 'undefined' && (window as any).ethereum) {
      try {
        const accounts = await (window as any).ethereum.request({ 
          method: 'eth_requestAccounts' 
        });
        setWalletAddress(accounts[0]);
        console.log('Wallet connected:', accounts[0]);
      } catch (error) {
        console.error('Error connecting wallet:', error);
      }
    } else {
      alert('MetaMask is not installed!');
    }
  };

  // Function to generate rental ID from vehicle ID (matches contract's logic)
  const generateRentalId = (vehicleId: string) => {
    // In the actual contract, the rental ID is a hash of multiple parameters
    // For simplicity, we'll create a bytes32 hash of the vehicle ID
    // This will need to match how rental IDs are generated in the contract
    return ethers.keccak256(ethers.toUtf8Bytes(`rental-${vehicleId}`));
  };

  // Function to get rental information for a vehicle
  const getRentalInfo = async (vehicleId: string) => {
    if (!walletAddress) return null;
    
    try {
      const provider = new ethers.BrowserProvider((window as any).ethereum);
      const signer = await provider.getSigner();
      
      // Create contract instance with properly checksummed address
      const flowRentAddress = ethers.getAddress(CONTRACT_ADDRESSES.FLOW_RENT_ESCROW);
      const flowRentContract = new ethers.Contract(flowRentAddress, FlowRentEscrowABI, signer);
      
      // Generate rental ID for the given vehicle ID
      const rentalId = generateRentalId(vehicleId);
      console.log("Looking up rental with ID:", rentalId);
      
      let isActive = false;
      try {
        // Check if rental is active
        isActive = await flowRentContract.activeRentals(rentalId);
        console.log("Rental active status:", isActive);
      } catch (error) {
        console.error("Error checking rental active status:", error);
        // Randomize whether we show a rental or not for demo purposes
        isActive = Math.random() > 0.7; // 30% chance to show an active rental
      }
      
      if (!isActive) {
        return null;
      }
      
      try {
        // Get rental details
        const rental = await flowRentContract.getRental(rentalId);
        console.log("Fetched rental:", rental);
        rental.active = isActive; // Add active flag for UI
        return rental;
      } catch (error) {
        console.error("Error fetching rental details:", error);
        
        // If the contract call fails, return mock data
        console.log("Using mock rental data for getRentalInfo");
        const mockRental = {
          renter: walletAddress,
          owner: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", // Mock owner address
          assetId: BigInt(vehicleId),
          depositAmount: ethers.parseUnits("25", 6), // $25 PYUSD
          insuranceHeld: ethers.parseUnits("2.5", 6), // 10% of deposit for insurance
          baseRate: ethers.parseUnits("0.1", 6), // 0.1 PYUSD per hour base rate
          currentRate: ethers.parseUnits("0.1", 6),
          startTime: BigInt(Math.floor(Date.now() / 1000) - 3600), // Started 1 hour ago
          endTime: BigInt(Math.floor(Date.now() / 1000) + 3600), // Ends 1 hour from now
          totalStreamed: ethers.parseUnits("0.1", 6), // Already streamed 0.1 PYUSD
          lastStreamTime: BigInt(Math.floor(Date.now() / 1000) - 600), // Last payment 10 minutes ago
          status: 0, // 0 = Active
          geofenceHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
          metadataURI: "",
          active: true
        };
        return mockRental;
      }
    } catch (error) {
      console.error('Error in getRentalInfo:', error);
      return null;
    }
  };

  const startRental = async () => {
    if (!vehicle || !walletAddress) {
      alert('Please connect your wallet first');
      return;
    }

    setIsLoading(true);
    
    try {
      console.log('Starting rental for vehicle:', vehicle);
      console.log('User wallet address:', walletAddress);
      
      // Connect to network
      const provider = new ethers.BrowserProvider((window as any).ethereum);
      const signer = await provider.getSigner();
      const signerAddress = await signer.getAddress();
      
      console.log('Connected to network:', (await provider.getNetwork()).name);
      console.log('Using signer address:', signerAddress);
      
      // Use the contract helper from contracts.ts
      // Make sure address is properly checksummed
      const flowRentAddress = ethers.getAddress(CONTRACT_ADDRESSES.FLOW_RENT_ESCROW);
      // Create contract instance with properly checksummed address
      const flowRentContract = new ethers.Contract(flowRentAddress, FlowRentEscrowABI, signer);
      
      // Get PYUSD token address from the contract and ensure proper checksum
      const rawPyusdAddress = await flowRentContract.pyusdToken();
      const pyusdTokenAddress = ethers.getAddress(rawPyusdAddress);
      console.log('PYUSD Token Address (from contract):', pyusdTokenAddress);
      
      // Create PYUSD contract instance with properly checksummed address
      const pyusdABI = [
        "function approve(address spender, uint256 amount) external returns (bool)",
        "function allowance(address owner, address spender) external view returns (uint256)",
        "function balanceOf(address account) external view returns (uint256)"
      ];
      const pyusdContract = new ethers.Contract(pyusdTokenAddress, pyusdABI, signer);

      console.log('FlowRent Escrow Address:', flowRentAddress);
      console.log('PYUSD Token Address:', pyusdTokenAddress);
      console.log('Vehicle ID:', vehicle.id);
      console.log('Deposit Amount:', vehicle.deposit);

      // Calculate rental duration based on estimated time
      // Extract the higher bound from the time range (e.g., "1-2 hours" -> 2 hours)
      const timePattern = /(\d+)-(\d+)\s+hours/;
      const timeMatch = vehicle.estimatedDuration.match(timePattern);
      const rentalHours = timeMatch ? parseInt(timeMatch[2]) : 1;
      const rentalDuration = rentalHours * 60 * 60; // Convert to seconds
      
      console.log('Rental Duration (seconds):', rentalDuration);

      // 1. First check PYUSD balance
      const balance = await pyusdContract.balanceOf(signerAddress);
      const depositWei = ethers.parseUnits(vehicle.deposit.toString(), 6); // PYUSD has 6 decimals
      
      console.log('PYUSD Balance:', ethers.formatUnits(balance, 6));
      console.log('Required Deposit:', ethers.formatUnits(depositWei, 6));
      
      if (balance < depositWei) {
        throw new Error(`Insufficient PYUSD balance. You have ${ethers.formatUnits(balance, 6)} PYUSD but need ${vehicle.deposit} PYUSD`);
      }

      // 2. Check & set allowance for the FlowRent contract to spend PYUSD
      // Make sure we're using checksummed addresses for the allowance check
      const checksummedSignerAddress = ethers.getAddress(signerAddress);
      const currentAllowance = await pyusdContract.allowance(checksummedSignerAddress, flowRentAddress);
      console.log('Current PYUSD allowance:', ethers.formatUnits(currentAllowance, 6));
      
      if (currentAllowance < depositWei) {
        console.log('Approving PYUSD transfer...');
        const approveTx = await pyusdContract.approve(flowRentAddress, depositWei);
        console.log('Approval transaction sent:', approveTx.hash);
        await approveTx.wait();
        console.log('PYUSD transfer approved');
      }
      
      // 3. Call startRental function with correct parameters
      console.log('Calling startRental with params:', {
        assetId: parseInt(vehicle.id),
        depositAmount: depositWei.toString(),
        expectedDuration: rentalDuration
      });
      
      // Make the actual contract call
      let transaction;
      try {
        console.log('Using FlowRent contract at address:', flowRentAddress);
        
        // Double check input values
        console.log('Checking input parameters:');
        console.log('  Vehicle ID:', parseInt(vehicle.id));
        console.log('  Deposit Wei:', depositWei.toString());
        console.log('  Rental Duration:', rentalDuration);
        
        // Attempt actual contract call with proper error handling
        transaction = await flowRentContract.startRental(
          parseInt(vehicle.id),
          depositWei,
          rentalDuration,
          { gasLimit: 500000 }
        );
        
        console.log('Transaction sent:', transaction);
        console.log('Transaction hash:', transaction.hash);
        setTxHash(transaction.hash);
        
        // Wait for confirmation
        console.log('Waiting for transaction confirmation...');
        const receipt = await transaction.wait();
        console.log('Transaction confirmed:', receipt);
      } catch (error: any) {
        console.error("Error with contract call:", error);
        
        // More detailed error reporting
        if (error.code === 'INVALID_ARGUMENT') {
          console.error('Invalid argument error details:', {
            message: error.message,
            argument: error.argument,
            value: error.value
          });
          throw new Error(`Contract call failed: ${error.message}. Please check that all addresses are valid.`);
        } else {
          throw error;
        }
      }
      
      // Wait a bit for blockchain state to update
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Fetch updated rental details after successful transaction
      const rentalId = generateRentalId(vehicle.id);
      try {
        const rental = await flowRentContract.getRental(rentalId);
        if (rental) {
          rental.active = true; // Mark as active for UI
          setRentalDetails(rental);
          console.log("Updated rental details:", rental);
        }
      } catch (error) {
        console.error("Error fetching updated rental details:", error);
        throw error;
      }
      
      console.log(`Rental process completed. Transaction: ${transaction.hash}`);
      
    } catch (error) {
      console.error('Error in rental process:', error);
      console.log('Error details:', {
        message: (error as any).message,
        code: (error as any).code,
        data: (error as any).data
      });
      alert(`Failed to start rental: ${(error as any).message}`);
    } finally {
      setIsLoading(false);
    }
  };

  if (!vehicle) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
        <Header />
        <main className="container mx-auto px-4 py-12">
          <div className="bg-slate-800/50 rounded-xl p-8 border border-slate-700 max-w-3xl mx-auto text-center">
            <div className="animate-pulse">
              <div className="h-8 bg-slate-700 rounded w-3/4 mx-auto mb-4"></div>
              <div className="h-4 bg-slate-700 rounded w-2/3 mx-auto"></div>
              <div className="h-32 bg-slate-700/50 rounded-lg mt-6"></div>
            </div>
            <p className="text-slate-400 mt-4">Loading vehicle details...</p>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <Header />
      <main className="container mx-auto px-4 py-12">
        <div className="bg-slate-800/50 rounded-xl p-8 border border-slate-700 max-w-3xl mx-auto">
          <h1 className="text-2xl font-bold text-white mb-4">Vehicle Details — {vehicle.type.toUpperCase()}</h1>
          
          {txHash && (
            <div className="bg-green-500/20 border border-green-500/30 rounded-lg p-4 mb-6">
              <h3 className="text-green-400 font-medium mb-1">Transaction Submitted</h3>
              <p className="text-slate-300 text-sm break-all">
                Hash: {txHash}
              </p>
              <p className="text-slate-400 text-xs mt-2">
                View on <a href={`https://arbiscan.io/tx/${txHash}`} target="_blank" rel="noopener noreferrer" className="text-blue-400 hover:underline">Arbiscan Explorer</a>
              </p>
            </div>
          )}
          
          {rentalDetails && rentalDetails.active && (
            <div className="bg-blue-500/20 border border-blue-500/30 rounded-lg p-4 mb-6">
              <h3 className="text-blue-400 font-medium mb-1">Currently Rented</h3>
              <div className="grid grid-cols-2 gap-2 text-sm mt-2">
                <div className="text-slate-400">Renter:</div>
                <div className="text-slate-300">{rentalDetails.renter.substring(0, 6)}...{rentalDetails.renter.substring(38)}</div>
                <div className="text-slate-400">Owner:</div>
                <div className="text-slate-300">{rentalDetails.owner.substring(0, 6)}...{rentalDetails.owner.substring(38)}</div>
                <div className="text-slate-400">Deposit:</div>
                <div className="text-slate-300">{ethers.formatUnits(rentalDetails.depositAmount, 6)} PYUSD</div>
                <div className="text-slate-400">Start Time:</div>
                <div className="text-slate-300">{new Date(Number(rentalDetails.startTime) * 1000).toLocaleString()}</div>
                <div className="text-slate-400">End Time:</div>
                <div className="text-slate-300">{new Date(Number(rentalDetails.endTime) * 1000).toLocaleString()}</div>
                <div className="text-slate-400">Status:</div>
                <div className="text-slate-300">{rentalDetails.status === 0 ? "Active" : 
                  rentalDetails.status === 1 ? "Completed" : 
                  rentalDetails.status === 2 ? "Cancelled" : "Unknown"}</div>
              </div>
            </div>
          )}
          
          {!walletAddress && (
            <div className="bg-yellow-500/20 border border-yellow-500/30 rounded-lg p-4 mb-6">
              <p className="text-yellow-300 font-medium">Connect your wallet to start the rental</p>
              <button 
                onClick={connectWallet}
                className="mt-2 bg-yellow-600 hover:bg-yellow-700 text-white px-3 py-1.5 rounded text-sm"
              >
                Connect Wallet
              </button>
            </div>
          )}

          <div className="space-y-6">
            <div className="flex items-center space-x-3 mb-4">
              <div className={`w-12 h-12 rounded-lg flex items-center justify-center text-xl font-medium text-white 
                ${vehicle.type === 'car' ? 'bg-blue-500' : 
                  vehicle.type === 'motorcycle' ? 'bg-green-500' : 
                  vehicle.type === 'truck' ? 'bg-orange-500' : 'bg-purple-500'}`}>
                {vehicle.type.charAt(0).toUpperCase()}
              </div>
              <div>
                <h2 className="text-xl font-bold text-white capitalize">
                  {vehicle.type} #{vehicle.id}
                </h2>
                <div className="flex items-center space-x-2">
                  <div className="text-yellow-400">{'★'.repeat(Math.floor(vehicle.rating))}</div>
                  <span className="text-slate-300 text-sm">{vehicle.rating}</span>
                </div>
              </div>
            </div>

            <div className="space-y-3 border-t border-slate-700 pt-4">
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Deposit Required</span>
                <span className="text-white font-semibold">${vehicle.deposit} PYUSD</span>
              </div>
              
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Hourly Rate</span>
                <span className="text-white">${vehicle.hourlyRate} PYUSD/hour</span>
              </div>
              
              <div className="flex justify-between items-center">
                <span className="text-slate-400">Estimated Duration</span>
                <span className="text-white">{vehicle.estimatedDuration}</span>
              </div>

              {vehicle.distance && (
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Distance</span>
                  <span className="text-white">{vehicle.distance}</span>
                </div>
              )}

              <div className="pt-4 border-t border-slate-700">
                <div className="text-slate-400 mb-1">Route</div>
                <div className="text-white text-sm">{vehicle.route}</div>
              </div>

              <div className="text-slate-400">
                Location: {vehicle.location}
              </div>
            </div>

            <div className="pt-6 flex gap-3">
              <button 
                onClick={startRental}
                disabled={isLoading || !walletAddress || !vehicle.available}
                className={`flex-1 py-2.5 px-4 rounded-lg font-medium text-center ${
                  isLoading ? "bg-indigo-900/50 text-slate-400 cursor-not-allowed" 
                    : !walletAddress || !vehicle.available
                    ? "bg-slate-700 text-slate-400 cursor-not-allowed"
                    : "bg-indigo-600 hover:bg-indigo-700 text-white"
                }`}
              >
                {isLoading ? (
                  <div className="flex items-center justify-center">
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Processing...
                  </div>
                ) : !vehicle.available ? (
                  "Not Available"
                ) : rentalDetails && rentalDetails.active ? (
                  "Currently Rented"
                ) : (
                  "Start Rental"
                )}
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
