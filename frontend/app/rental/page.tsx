"use client";
import Header from '../components/Header';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
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
} from '../utils/contracts';

interface Vehicle {
	id: string;
	type: 'car' | 'suv' | 'truck';
	model: string;
	deposit: number;
	ratePerMinute: number;
	location: string;
	available: boolean;
	rating: number;
	imageUrl: string;
	features: string[];
	verificationRequired: boolean;
}

const vehicleData: Vehicle[] = [
	{
		id: '1',
		type: 'car',
		model: 'Tesla Model 3',
		deposit: 100,
		ratePerMinute: 0.10,
		location: 'New York, USA',
		available: true,
		rating: 4.8,
		imageUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8dGVzbGElMjBtb2RlbCUyMDN8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
		features: ['Electric', 'Autopilot', 'Climate Control'],
		verificationRequired: true
	},
	{
		id: '2',
		type: 'suv',
		model: 'Toyota RAV4',
		deposit: 75,
		ratePerMinute: 0.08,
		location: 'Los Angeles, USA',
		available: true,
		rating: 4.6,
		imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8Y2FyfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
		features: ['Hybrid', 'Spacious', '4WD'],
		verificationRequired: true
	},
	{
		id: '3',
		type: 'truck',
		model: 'Ford F-150',
		deposit: 120,
		ratePerMinute: 0.12,
		location: 'Chicago, USA',
		available: true,
		rating: 4.9,
		imageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8cGlja3VwJTIwdHJ1Y2t8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60',
		features: ['Powerful', 'Spacious Bed', 'Towing Capacity'],
		verificationRequired: true
	},
	{
		id: '4',
		type: 'car',
		model: 'Honda Civic',
		deposit: 60,
		ratePerMinute: 0.06,
		location: 'Miami, USA',
		available: true,
		rating: 4.7,
		imageUrl: 'https://images.unsplash.com/photo-1533106418989-88406c7cc8ca?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8Y2FyfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
		features: ['Fuel Efficient', 'Reliable', 'Compact'],
		verificationRequired: false
	},
	{
		id: '5',
		type: 'suv',
		model: 'Jeep Wrangler',
		deposit: 90,
		ratePerMinute: 0.09,
		location: 'Denver, USA',
		available: true,
		rating: 4.5,
		imageUrl: 'https://images.unsplash.com/photo-1533106418989-88406c7cc8ca?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8Y2FyfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
		features: ['Off-road', '4WD', 'Convertible'],
		verificationRequired: true
	},
	{
		id: '6',
		type: 'car',
		model: 'BMW i4',
		deposit: 150,
		ratePerMinute: 0.15,
		location: 'San Francisco, USA',
		available: false,
		rating: 4.9,
		imageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fGNhcnxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
		features: ['Electric', 'Luxury', 'Performance'],
		verificationRequired: true
	}
];

const locations = [
	'New York, USA',
	'Los Angeles, USA',
	'Chicago, USA',
	'Miami, USA',
	'Denver, USA',
	'San Francisco, USA',
	'Seattle, USA'
];

export default function Rental() {
    const router = useRouter();
	const [selectedLocation, setSelectedLocation] = useState('');
	const [filteredVehicles, setFilteredVehicles] = useState<Vehicle[]>(vehicleData);
	const [showVerifiedOnly, setShowVerifiedOnly] = useState(false);

	useEffect(() => {
		// Filter vehicles based on location and verification requirements
		if (selectedLocation || showVerifiedOnly) {
			const filtered = vehicleData.filter(vehicle => 
				(!selectedLocation || vehicle.location === selectedLocation) &&
				(!showVerifiedOnly || vehicle.verificationRequired)
			);
			setFilteredVehicles(filtered);
		} else {
			setFilteredVehicles(vehicleData);
		}
	}, [selectedLocation, showVerifiedOnly]);

	const getVehicleColor = (type: string) => {
		switch (type) {
			case 'car':
				return 'bg-teal-500';
			case 'suv':
				return 'bg-indigo-500';
			case 'truck':
				return 'bg-amber-500';
			default:
				return 'bg-teal-500';
		}
	};

	const getVehicleIcon = (type: string) => {
		switch (type) {
			case 'car':
				return (
					<svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
					</svg>
				);
			case 'suv':
				return (
					<svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
					</svg>
				);
			case 'truck':
				return (
					<svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
					</svg>
				);
			default:
				return (
					<svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
					</svg>
				);
		}
	};

	return (
		<div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
			<Header />
			
			<div className="container mx-auto px-4 py-8">
				{/* Hero Section */}
				<div className="text-center mb-12">
					<h1 className="text-4xl lg:text-5xl font-bold text-teal-400 mb-4">Find Your Perfect Vehicle</h1>
					<p className="text-xl text-slate-300 max-w-3xl mx-auto">
						Browse our selection of premium vehicles and pay only for the time you use them with PYUSD streaming payments
					</p>
				</div>
				
				{/* Filters Section */}
				<div className="mb-10">
					<div className="max-w-5xl mx-auto bg-slate-800/40 backdrop-blur-sm rounded-2xl p-8 border border-slate-700">
						<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
							{/* Location Filter */}
							<div>
								<label className="block text-sm font-medium text-teal-400 mb-3">
									Location
								</label>
								<select
									value={selectedLocation}
									onChange={(e) => setSelectedLocation(e.target.value)}
									className="w-full bg-slate-700 text-slate-100 rounded-lg px-4 py-3 border border-slate-600 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/20 transition-colors"
								>
									<option value="">All Locations</option>
									{locations.map((location) => (
										<option key={location} value={location}>
											{location}
										</option>
									))}
								</select>
							</div>
							
							{/* Verification Filter */}
							<div>
								<label className="block text-sm font-medium text-teal-400 mb-3">
									Verification
								</label>
								<div className="flex items-center space-x-3 h-12">
									<label className="flex items-center space-x-2 cursor-pointer">
										<input
											type="checkbox"
											checked={showVerifiedOnly}
											onChange={() => setShowVerifiedOnly(!showVerifiedOnly)}
											className="w-5 h-5 border-2 border-slate-500 rounded bg-transparent text-teal-500 focus:ring-teal-500"
										/>
										<span className="text-slate-100">Show verified-only vehicles</span>
									</label>
								</div>
							</div>
							
							{/* Self Protocol Integration */}
							<div>
								<label className="block text-sm font-medium text-teal-400 mb-3">
									Passport Status
								</label>
								<div className="bg-emerald-500/10 border border-emerald-500/30 px-4 py-3 rounded-lg flex items-center justify-between">
									<div className="flex items-center space-x-2">
										<div className="text-emerald-400">
											<svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
												<path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
											</svg>
										</div>
										<span className="text-emerald-400 text-sm font-medium">Verified with Self Protocol</span>
									</div>
									<button className="text-xs text-teal-400 hover:text-teal-300 transition-colors">
										Details
									</button>
								</div>
							</div>
						</div>
					</div>
				</div>

				{/* Vehicle List */}
				<div className="max-w-7xl mx-auto">
					<div className="flex justify-between items-center mb-6">
						<h2 className="text-2xl font-bold text-teal-100">
							Available Vehicles {selectedLocation && `in ${selectedLocation}`}
						</h2>
						<div className="text-slate-300">
							{filteredVehicles.length} vehicles found
						</div>
					</div>

					<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
						{filteredVehicles.map((vehicle) => (
							<div
								key={vehicle.id}
								className={`bg-slate-800/50 backdrop-blur-sm rounded-xl overflow-hidden border border-slate-700 hover:border-teal-500/50 transition-all duration-300 ${
									!vehicle.available ? 'opacity-70' : 'hover:shadow-lg hover:shadow-teal-500/10'
								}`}
							>
								{/* Vehicle Image */}
								<div className="h-48 overflow-hidden relative">
									<img 
										src={vehicle.imageUrl} 
										alt={`${vehicle.model}`}
										className="w-full h-full object-cover"
									/>
									{vehicle.verificationRequired && (
										<div className="absolute top-3 right-3 bg-emerald-500/90 px-3 py-1 rounded-full text-xs font-medium text-white">
											Passport Verified
										</div>
									)}
									<div className={`absolute top-3 left-3 px-3 py-1 rounded-full text-xs font-medium ${
										vehicle.available 
											? 'bg-teal-500 text-white' 
											: 'bg-slate-600 text-slate-200'
									}`}>
										{vehicle.available ? 'Available Now' : 'In Use'}
									</div>
								</div>
								
								{/* Vehicle Header */}
								<div className="p-6">
									<div className="flex items-center justify-between mb-4">
										<div>
											<h3 className="text-xl font-semibold text-teal-100 capitalize">
												{vehicle.model}
											</h3>
											<div className="flex items-center space-x-2 mt-1">
												<span className={`px-2 py-1 rounded-md text-xs font-medium ${getVehicleColor(vehicle.type)} text-white`}>
													{vehicle.type.toUpperCase()}
												</span>
												<div className="flex items-center space-x-1 text-slate-300">
													<svg className="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
														<path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
													</svg>
													<span className="text-slate-300 text-sm">{vehicle.rating}</span>
												</div>
											</div>
										</div>
									</div>

									{/* Vehicle Details */}
									<div className="space-y-3">
										<div className="flex justify-between items-center">
											<span className="text-slate-400">Deposit Required</span>
											<span className="text-teal-100 font-semibold">${vehicle.deposit} PYUSD</span>
										</div>
										
										<div className="flex justify-between items-center">
											<span className="text-slate-400">Rate</span>
											<span className="text-teal-100">${vehicle.ratePerMinute.toFixed(2)}/minute</span>
										</div>

										<div className="flex flex-wrap gap-2 pt-3">
											{vehicle.features.map((feature, idx) => (
												<span 
													key={idx} 
													className="px-2 py-1 bg-slate-700/50 rounded-md text-xs text-slate-300"
												>
													{feature}
												</span>
											))}
										</div>
									</div>

									{/* Action Button */}
									<button
										onClick={() => router.push(`/rental/${vehicle.id}`)}
										disabled={!vehicle.available}
										className={`w-full mt-6 py-3 px-4 rounded-lg font-medium transition-all ${
											vehicle.available
												? 'bg-teal-600 hover:bg-teal-700 text-white'
												: 'bg-slate-700 text-slate-400 cursor-not-allowed'
										}`}
									>
										{vehicle.available ? 'Rent This Vehicle' : 'Currently Unavailable'}
									</button>
								</div>
							</div>
						))}
					</div>

					{filteredVehicles.length === 0 && (
						<div className="text-center py-16 bg-slate-800/30 rounded-xl border border-slate-700 my-8">
							<div className="text-6xl mb-4">🔍</div>
							<h3 className="text-xl font-semibold text-teal-100 mb-2">No vehicles found</h3>
							<p className="text-slate-300">Try selecting a different location or adjusting your filters</p>
						</div>
					)}
				</div>
				
				{/* PYUSD Integration Info */}
				<div className="mt-16 max-w-5xl mx-auto bg-slate-800/30 backdrop-blur-sm rounded-xl p-8 border border-slate-700">
					<div className="flex flex-col md:flex-row items-center justify-between">
						<div className="mb-6 md:mb-0 md:mr-8">
							<h3 className="text-xl font-bold text-teal-100 mb-3">Pay-As-You-Go with PYUSD</h3>
							<p className="text-slate-300">
								Our vehicles use Sablier streaming payments via PYUSD, allowing you to pay precisely for the minutes you use a vehicle.
								No overcharges, no hidden fees, just transparent pricing.
							</p>
						</div>
						<button className="px-8 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors flex items-center">
							<span>Learn How It Works</span>
							<svg className="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14 5l7 7m0 0l-7 7m7-7H3" />
							</svg>
						</button>
					</div>
				</div>
			</div>
		</div>
	);
}
