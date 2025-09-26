"use client";
import React from 'react';
import { useRouter } from 'next/navigation';

const HeroSection = () => {
  const router = useRouter();

  // Generate QR code for FlowRent Mini App (mock URL)
  const qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent('https://flowrent.app/miniapp')}`;

  return (
    <section className="max-w-7xl mx-auto px-6 py-20 lg:py-28">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
        <div className="space-y-8">
          <div className="space-y-6">
            <h1 className="text-5xl lg:text-6xl xl:text-7xl font-bold leading-tight text-white font-['Inter',_'system-ui',_sans-serif]">
                The first
              <span className="text-teal-400 block lg:inline"> global micro-rental platform</span> 
            </h1>
            <p className="text-xl lg:text-2xl text-slate-300 leading-relaxed font-['Inter',_'system-ui',_sans-serif]">
              where verified renters pay via PYUSD streaming micropayments with borderless verification.
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
            <div className="bg-white p-4 rounded-lg mb-4 flex items-center justify-center">
              <img 
                src={qrCodeUrl}
                alt="FlowRent Mini App QR Code"
                className="w-48 h-48 rounded"
                onError={(e) => {
                  // Fallback if QR service is unavailable
                  e.currentTarget.style.display = 'none';
                  const fallback = e.currentTarget.nextElementSibling;
                  if (fallback) fallback.style.display = 'flex';
                }}
              />
              <div 
                className="w-48 h-48 bg-gray-200 items-center justify-center rounded hidden"
                style={{ display: 'none' }}
              >
                <span className="text-gray-500 text-sm font-['Inter',_'system-ui',_sans-serif]">QR Code</span>
              </div>
            </div>
            <p className="text-center text-slate-300 font-medium font-['Inter',_'system-ui',_sans-serif]">
              Scan to Launch FlowRent Mini App
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;