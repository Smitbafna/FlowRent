"use client";
import React from 'react';
import { useRouter } from 'next/navigation';

const HeroSection = () => {
  const router = useRouter();

  return (
    <section className="max-w-7xl mx-auto px-6 py-20 lg:py-28">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
        <div className="space-y-8">
          <div className="space-y-6">
            <h1 className="text-5xl lg:text-6xl xl:text-7xl font-bold leading-tight text-white font-['Inter',_'system-ui',_sans-serif]">
                A global
              <span className="text-teal-400 block lg:inline"> pay-as-you-go vehicle rental</span> 
            </h1>
            <p className="text-xl lg:text-2xl text-slate-300 leading-relaxed font-['Inter',_'system-ui',_sans-serif]">
              Experience seamless vehicle rentals worldwide with passport-based KYC and PYUSD streaming payments.
            </p>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-4">
            <button 
              onClick={() => router.push('/rental')}
              className="bg-teal-500 hover:bg-teal-600 px-8 py-4 rounded-xl text-lg font-semibold transition-all duration-200 transform hover:scale-105 shadow-lg hover:shadow-teal-500/25 text-white font-['Inter',_'system-ui',_sans-serif]"
            >
              Start a Rental
            </button>
            
          </div>
        </div>
        
        <div className="flex justify-center lg:justify-end">
          <div className="bg-slate-800 p-8 rounded-2xl border border-slate-700 max-w-sm shadow-2xl">
            <div className="flex flex-col space-y-4">
              <div className="flex items-center space-x-4 mb-2">
                <div className="w-12 h-12 bg-teal-500 rounded-full flex items-center justify-center">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-slate-100">Cross-Chain Verified</h3>
              </div>
              
              <div className="flex items-center space-x-4 mb-2">
                <div className="w-12 h-12 bg-teal-500 rounded-full flex items-center justify-center">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-slate-100">Pay-As-You-Go</h3>
              </div>
              
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 bg-teal-500 rounded-full flex items-center justify-center">
                  <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-slate-100">Global Access</h3>
              </div>
            </div>
            <p className="text-center text-slate-300 font-medium mt-6 font-['Inter',_'system-ui',_sans-serif]">
              Access vehicles worldwide with borderless verification
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;