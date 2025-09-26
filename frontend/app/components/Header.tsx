"use client";
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';

const Header = () => {
  const router = useRouter();
  const [showTooltip, setShowTooltip] = useState(false);
  const [showWalletTooltip, setShowWalletTooltip] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  
 
  const verificationStatus = {
    isVerified: true,
    method: 'Passport', // 'Passport', 'Orb', or 'Device'
    level: 'Verified Human'
  };
  
  const walletAddress = '0x1e50cCa4CB425A373Cf2e6e7baD72B06a139312c';
  const truncatedAddress = `${walletAddress.slice(0, 6)}...${walletAddress.slice(-4)}`;

  const getVerificationIcon = (method) => {
    switch (method) {
      case 'Passport':
        return (
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path d="M4 4a2 2 0 00-2 2v1h16V6a2 2 0 00-2-2H4zM2 8v6a2 2 0 002 2h12a2 2 0 002-2V8H2zm8 3a1 1 0 011-1h3a1 1 0 110 2h-3a1 1 0 01-1-1z"/>
          </svg>
        );
      case 'Orb':
        return (
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-8.293l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 001.414 1.414L9 9.414V13a1 1 0 102 0V9.414l1.293 1.293a1 1 0 001.414-1.414z" clipRule="evenodd"/>
          </svg>
        );
      case 'Device':
        return (
          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 011 1v8a1 1 0 01-1 1H4a1 1 0 01-1-1V4zm1 2v6h12V6H4z" clipRule="evenodd"/>
          </svg>
        );
      default:
        return null;
    }
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
         
        </nav>

        {/* World ID & Wallet Section */}
        <div className="hidden md:flex items-center space-x-4">
          {/* World ID Verification Badge */}
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
              <div className="absolute top-full mt-2 left-1/2 transform -translate-x-1/2 bg-slate-800 text-white text-xs px-3 py-2 rounded-lg shadow-lg border border-slate-600 whitespace-nowrap z-10">
                Verified human via World ID
                <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 w-2 h-2 bg-slate-800 rotate-45 border-l border-t border-slate-600"></div>
              </div>
            )}
          </div>

          {/* Connected Wallet */}
          <div 
            className="relative flex items-center space-x-2 bg-slate-700/50 border border-slate-600 px-3 py-2 rounded-lg cursor-pointer hover:bg-slate-700/70 transition-colors"
            onClick={copyAddress}
            onMouseEnter={() => setShowWalletTooltip(true)}
            onMouseLeave={() => setShowWalletTooltip(false)}
          >
            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
            <span className="text-slate-300 text-xs font-mono">
              {truncatedAddress}
            </span>
            <svg className="w-3 h-3 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>

            {/* Wallet Tooltip */}
            {showWalletTooltip && (
              <div className="absolute top-full mt-2 left-1/2 transform -translate-x-1/2 bg-slate-800 text-white text-xs px-3 py-2 rounded-lg shadow-lg border border-slate-600 whitespace-nowrap z-10">
                Click to copy full address
                <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 w-2 h-2 bg-slate-800 rotate-45 border-l border-t border-slate-600"></div>
              </div>
            )}
          </div>

          {/* Get Started Button */}
          <button 
            onClick={() => router.push('/')}
            className="bg-teal-500 hover:bg-teal-600 px-6 py-2 rounded-lg transition-colors duration-200 text-sm font-semibold text-white"
          >
            Get Started
          </button>
        </div>

        {/* Mobile Menu Button */}
        <button 
          className="md:hidden p-2 text-white"
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
              {/* World ID Badge */}
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
                href="#how-it-works" 
                className="block py-2 text-white hover:text-teal-400 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                How It Works
              </a>
              <a 
                href="#why-flowrent" 
                className="block py-2 text-white hover:text-teal-400 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                About
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