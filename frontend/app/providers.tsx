"use client";

import { WalletProvider } from './context/WalletProvider';
import React from 'react';

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WalletProvider>
      {children}
    </WalletProvider>
  );
}
