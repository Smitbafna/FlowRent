"use client";
import React from 'react';

interface StepCardProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  step: number;
}

const StepCard: React.FC<StepCardProps> = ({ icon, title, description, step }) => (
  <div className="relative text-center group">
    <div className="absolute -top-2 -right-2 w-8 h-8 bg-teal-500 rounded-full flex items-center justify-center text-sm font-bold z-10">
      {step}
    </div>
    <div className="w-20 h-20 bg-teal-500 rounded-full flex items-center justify-center mx-auto mb-6 group-hover:bg-teal-400 transition-colors duration-200 shadow-lg">
      {icon}
    </div>
    <h3 className="text-2xl font-semibold mb-4 text-slate-100">{title}</h3>
    <p className="text-slate-300 text-lg leading-relaxed">{description}</p>
  </div>
);

const HowItWorks = () => {
  const steps = [
    {
      icon: (
        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      ),
      title: "Pre-Trip Verification",
      description: "Complete one-time passport-based KYC with Self Protocol that works across all supported chains"
    },
    {
      icon: (
        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
      ),
      title: "Arrive & Locate",
      description: "Arrive at your destination, locate available vehicles, and access them with your verified credentials"
    },
    {
      icon: (
        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
        </svg>
      ),
      title: "Pay-as-you-go",
      description: "Enjoy the freedom of seamless pay-per-minute vehicle use with PYUSD streaming payments on Arbitrum"
    }
  ];

  return (
    <section id="how-it-works" className="bg-slate-800 py-20 lg:py-28">
      <div className="max-w-7xl mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-4xl lg:text-5xl font-bold mb-4 text-slate-100">How It Works</h2>
          <p className="text-xl text-slate-300 max-w-3xl mx-auto">
            Rent vehicles globally with these three simple steps
          </p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-12 lg:gap-16">
          {steps.map((step, index) => (
            <StepCard
              key={index}
              icon={step.icon}
              title={step.title}
              description={step.description}
              step={index + 1}
            />
          ))}
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
