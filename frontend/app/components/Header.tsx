"use client";
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import ConnectWalletButton from './ConnectWalletButton';
import { useWallet } from '../context/WalletProvider';

const Header = () => {
  const router = useRouter();
  const [showTooltip, setShowTooltip] = useState(false);
  const [showWalletTooltip, setShowWalletTooltip] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
  const { isConnected, account } = useWallet();
  
  // Verification status - this would come from contract in real implementation
  const verificationStatus = {
    isVerified: isConnected,
    method: 'Self Protocol', // Using Self Protocol for verification
    level: 'Verified Human'
  };
  
  const walletAddress = account || '';
  const truncatedAddress = walletAddress ? `${walletAddress.slice(0, 6)}...${walletAddress.slice(-4)}` : '';

  const getVerificationIcon = (method) => {
    // Self Protocol icon
    return (
      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
        <path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
      </svg>
    );
  };

  const copyAddress = async () => {
    try {
      await navigator.clipboard.writeText(walletAddress);
      // You could add a toast notification here
      console.log('Address copied to clipboard');
    } catch (err) {
      console.error('Failed to copy address:', err);
    }
  };

  return (
    <header className="border-b border-slate-700 sticky top-0 bg-slate-900/95 backdrop-blur-sm z-50">
      <div className="max-w-7xl mx-auto px-6 py-8 flex items-center justify-between">
        {/* Logo */}
        <div className="text-4xl font-bold text-teal-400 cursor-pointer" onClick={() => router.push('/flowrent')}>
          FlowRent
        </div>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center space-x-8">
          <a href="#features" className="text-slate-100 hover:text-teal-400 transition-colors">Key Features</a>
          <a href="#how-it-works" className="text-slate-100 hover:text-teal-400 transition-colors">How It Works</a>
          <a href="#benefits" className="text-slate-100 hover:text-teal-400 transition-colors">Benefits</a>
        </nav>

        {/* Self ID & Wallet Section */}
        <div className="hidden md:flex items-center space-x-4">
          {/* Self ID Verification Badge */}
          {isConnected && (
                      <div 
                className="relative flex items-center space-x-2 bg-emerald-500/10 border border-emerald-500/30 px-3 py-2 rounded-lg"
                onMouseEnter={() => setShowTooltip(true)}
                onMouseLeave={() => setShowTooltip(false)}
              >
                <div className="text-emerald-400">
                  {getVerificationIcon(verificationStatus.method)}
                </div>
                <span className="text-emerald-400 text-xs font-medium">
                  Verified via {verificationStatus.method}
                </span>
                
                {/* Tooltip */}
                {showTooltip && (
                  <div className="absolute top-full mt-2 left-1/2 transform -translate-x-1/2 bg-slate-800 text-slate-100 text-xs px-3 py-2 rounded-lg shadow-lg border border-slate-600 whitespace-nowrap z-10">
                    Verified human via Self Protocol
                    <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 w-2 h-2 bg-slate-800 rotate-45 border-l border-t border-slate-600"></div>
                  </div>
                )}
              </div>
          )}

          {/* Wallet Connection Button */}
          <ConnectWalletButton variant="secondary" size="sm" className="z-50" />
          
          {/* Connected Wallet - Only show if connected */}
         

        
        </div>

        {/* Mobile Menu Button */}
        <button 
          className="md:hidden p-2 text-slate-100"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-slate-900/98 backdrop-blur-sm border-t border-slate-700">
          <div className="px-6 py-4 space-y-4">
            {/* Mobile Verification & Wallet */}
            <div className="flex flex-col space-y-3">
              {/* Self Protocol Verification Badge */}
              <div className="flex items-center space-x-2 bg-emerald-500/10 border border-emerald-500/30 px-3 py-2 rounded-lg w-fit">
                <div className="text-emerald-400">
                  {getVerificationIcon(verificationStatus.method)}
                </div>
                <span className="text-emerald-400 text-xs font-medium">
                  Verified via {verificationStatus.method}
                </span>
              </div>

              {/* Mobile Wallet */}
              <div 
                className="flex items-center space-x-2 bg-slate-700/50 border border-slate-600 px-3 py-2 rounded-lg w-fit cursor-pointer"
                onClick={copyAddress}
              >
                <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                <span className="text-slate-300 text-xs font-mono">
                  {truncatedAddress}
                </span>
                <svg className="w-3 h-3 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </div>
            </div>

            {/* Mobile Navigation Links */}
            <div className="space-y-2 pt-2">
              <a 
                href="#features" 
                className="block py-2 text-slate-100 hover:text-teal-400 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Key Features
              </a>
              <a 
                href="#how-it-works" 
                className="block py-2 text-slate-100 hover:text-teal-400 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                How It Works
              </a>
              <a 
                href="#benefits" 
                className="block py-2 text-slate-100 hover:text-teal-400 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Benefits
              </a>
              <button 
                onClick={() => {
                  router.push('/');
                  setMobileMenuOpen(false);
                }}
                className="w-full mt-4 bg-teal-500 hover:bg-teal-600 px-6 py-3 rounded-lg transition-colors duration-200 text-sm font-semibold text-white"
              >
                Get Started
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;