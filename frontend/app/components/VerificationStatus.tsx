"use client";

import React, { useState, useEffect } from 'react';
import { useWallet } from '../context/WalletProvider';
import { 
  getProofOfHumanReceiver,
  switchToDestinationNetwork,
  DESTINATION_NETWORK
} from '../utils/contracts';
import { ethers } from 'ethers';

const VerificationStatus: React.FC = () => {
  const { account, isConnected, chainId, provider, signer } = useWallet();
  const [isVerified, setIsVerified] = useState<boolean>(false);
  const [verificationData, setVerificationData] = useState<{
    name: string;
    nationality: string;
    timestamp: number;
  } | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Check verification status when account or network changes
  useEffect(() => {
    const checkVerificationStatus = async () => {
      if (!isConnected || !account || !signer) {
        setIsVerified(false);
        setVerificationData(null);
        return;
      }

      // Make sure we're on the right network for verification checks
      if (chainId !== DESTINATION_NETWORK.chainId) {
        try {
          await switchToDestinationNetwork();
        } catch (error) {
          console.error('Failed to switch network:', error);
          return;
        }
      }

      setIsLoading(true);
      setError(null);

      try {
        // Get contract instance
        const receiverContract = getProofOfHumanReceiver(signer);
        
        // Check if the user is verified
        const [verified, chainSource, timestamp] = await receiverContract.isUserVerified(account);
        setIsVerified(verified);
        
        if (verified) {
          // Get more detailed verification data
          const [name, nationality, timeValue] = await receiverContract.getUserEssentialData(account);
          setVerificationData({
            name,
            nationality,
            timestamp: Number(timestamp)
          });
        } else {
          setVerificationData(null);
        }
      } catch (err: any) {
        console.error('Error checking verification status:', err);
        setError(err.message || 'Failed to check verification status');
        setIsVerified(false);
        setVerificationData(null);
      } finally {
        setIsLoading(false);
      }
    };

    checkVerificationStatus();
  }, [isConnected, account, chainId, signer]);

  if (!isConnected) {
    return (
      <div className="p-6 max-w-md mx-auto bg-white rounded-lg shadow-md">
        <h2 className="text-lg font-semibold text-gray-700 mb-4">Verification Status</h2>
        <p className="text-gray-600">Connect your wallet to check your verification status.</p>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-md mx-auto bg-white rounded-lg shadow-md">
      <h2 className="text-lg font-semibold text-gray-700 mb-4">Verification Status</h2>
      
      {isLoading ? (
        <div className="flex items-center justify-center py-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
          <span className="ml-2 text-gray-600">Checking status...</span>
        </div>
      ) : error ? (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
          <p>{error}</p>
        </div>
      ) : (
        <div>
          <div className="flex items-center mb-4">
            <span className="mr-2">Status:</span>
            {isVerified ? (
              <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm flex items-center">
                <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                Verified
              </span>
            ) : (
              <span className="px-3 py-1 bg-red-100 text-red-800 rounded-full text-sm flex items-center">
                <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                Not Verified
              </span>
            )}
          </div>
          
          {verificationData && (
            <div className="border-t pt-4 mt-4">
              <h3 className="font-medium text-gray-700 mb-2">Verification Details</h3>
              <div className="space-y-2">
                <p><span className="font-medium">Name:</span> {verificationData.name}</p>
                <p><span className="font-medium">Nationality:</span> {verificationData.nationality}</p>
                <p><span className="font-medium">Verified on:</span> {new Date(verificationData.timestamp * 1000).toLocaleString()}</p>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default VerificationStatus;
