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
    <h3 className="text-2xl font-semibold mb-4">{title}</h3>
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
      title: "Verify",
      description: "Secure identity verification with Self Protocol for trusted rentals and enhanced privacy"
    },
    {
      icon: (
        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-4m-5 0H3m2 0V9a2 2 0 012-2h4a2 2 0 012 2v4" />
        </svg>
      ),
      title: "Rent",
      description: "Browse and rent anything with real-time PYUSD micropayments and transparent pricing"
    },
    {
      icon: (
        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1a3 3 0 010 6h-1m1-6V9a3 3 0 013-3h2M9 10V9a3 3 0 013-3h2m-3 12h2a3 3 0 003-3v-1" />
        </svg>
      ),
      title: "Enjoy",
      description: "Access your rental instantly with secure, transparent transactions and full control"
    }
  ];

  return (
    <section id="how-it-works" className="bg-slate-800 py-20 lg:py-28">
      <div className="max-w-7xl mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-4xl lg:text-5xl font-bold mb-4">How It Works</h2>
          <p className="text-xl text-slate-300 max-w-3xl mx-auto">
            Get started with FlowRent in three simple steps
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
