"use client";
import Header from '../components/Header';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface Asset {
	id: string;
	type: 'scooter' | 'bike' | 'desk';
	deposit: number;
	estimatedDuration: string;
	distance?: string;
	route?: string;
	location: string;
	available: boolean;
	rating: number;
}

const mockAssets: Asset[] = [
	{
		id: '1',
		type: 'scooter',
		deposit: 25,
		estimatedDuration: '1-2 hours',
		distance: '6km',
		route: 'Mumbai, India → Pune, India',
		location: 'Mumbai, India',
		available: true,
		rating: 4.8
	},
	{
		id: '2',
		type: 'bike',
		deposit: 20,
		estimatedDuration: '2-4 hours',
		distance: '12km',
		route: 'Delhi, India → Gurgaon, India',
		location: 'Delhi, India',
		available: true,
		rating: 4.6
	},
	{
		id: '3',
		type: 'desk',
		deposit: 40,
		estimatedDuration: '4-8 hours',
		distance: 'N/A',
		route: 'Bengaluru, India - Koramangala, Floor 3',
		location: 'Bengaluru, India',
		available: true,
		rating: 4.9
	},
	{
		id: '4',
		type: 'scooter',
		deposit: 22,
		estimatedDuration: '1-3 hours',
		distance: '9km',
		route: 'Chennai, India → Adyar, India',
		location: 'Chennai, India',
		available: true,
		rating: 4.7
	},
	{
		id: '5',
		type: 'bike',
		deposit: 18,
		estimatedDuration: '1-2 hours',
		distance: '7km',
		route: 'Hyderabad, India → Gachibowli, India',
		location: 'Hyderabad, India',
		available: true,
		rating: 4.5
	},
	{
		id: '6',
		type: 'desk',
		deposit: 35,
		estimatedDuration: '3-6 hours',
		distance: 'N/A',
		route: 'Pune, India - Kalyani Nagar, Desk 12',
		location: 'Pune, India',
		available: false,
		rating: 4.4
	}
];

const locations = [
	'Mumbai, India',
	'Pune, India',
	'Delhi, India',
	'Gurgaon, India',
	'Bengaluru, India',
	'Chennai, India',
	'Hyderabad, India'
];

export default function Rental() {
    const router = useRouter();
	const [sourceLocation, setSourceLocation] = useState('');
	const [destinationLocation, setDestinationLocation] = useState('');
	const [filteredAssets, setFilteredAssets] = useState<Asset[]>(mockAssets);

	useEffect(() => {
		// Filter assets based on source location
		if (sourceLocation) {
			const filtered = mockAssets.filter(asset => 
				asset.location === sourceLocation || 
				asset.route?.includes(sourceLocation)
			);
			setFilteredAssets(filtered);
		} else {
			setFilteredAssets(mockAssets);
		}
	}, [sourceLocation, destinationLocation]);

	const getAssetColor = (type: string) => {
		switch (type) {
			case 'scooter':
				return 'bg-purple-500';
			case 'bike':
				return 'bg-green-500';
			case 'desk':
				return 'bg-blue-500';
			default:
				return 'bg-gray-500';
		}
	};

	const getAssetIcon = (type: string) => {
		switch (type) {
			case 'scooter':
				return 'S';
			case 'bike':
				return 'B';
			case 'desk':
				return 'D';
			default:
				return 'A';
		}
	};

	return (
		<div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
			<Header />
			
			<div className="container mx-auto px-4 py-8">
				{/* Location Selection */}
				<div className="mb-8">
					<h1 className="text-3xl font-bold text-white mb-6 text-center">Find Your Rental</h1>
					
					<div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
						{/* Source Location */}
						<div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
							<label className="block text-sm font-medium text-slate-300 mb-3">
								Pick-up Location
							</label>
							<select
								value={sourceLocation}
								onChange={(e) => setSourceLocation(e.target.value)}
								className="w-full bg-slate-700 text-white rounded-lg px-4 py-3 border border-slate-600 focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 transition-colors"
							>
								<option value="">Select source location</option>
								{locations.map((location) => (
									<option key={location} value={location}>
										{location}
									</option>
								))}
							</select>
						</div>

						{/* Destination Location */}
						<div className="bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700">
							<label className="block text-sm font-medium text-slate-300 mb-3">
								Destination
							</label>
							<select
								value={destinationLocation}
								onChange={(e) => setDestinationLocation(e.target.value)}
								className="w-full bg-slate-700 text-white rounded-lg px-4 py-3 border border-slate-600 focus:border-green-500 focus:ring-2 focus:ring-green-500/20 transition-colors"
							>
								<option value="">Select destination</option>
								{locations.map((location) => (
									<option key={location} value={location}>
										{location}
									</option>
								))}
							</select>
						</div>
					</div>
				</div>

				{/* Asset List */}
				<div className="max-w-6xl mx-auto">
					<div className="flex justify-between items-center mb-6">
						<h2 className="text-2xl font-bold text-white">
							Available Assets {sourceLocation && `near ${sourceLocation}`}
						</h2>
						<div className="text-slate-400">
							{filteredAssets.length} assets found
						</div>
					</div>

					<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
						{filteredAssets.map((asset) => (
							<div
								key={asset.id}
								className={`bg-slate-800/50 backdrop-blur-sm rounded-xl p-6 border border-slate-700 hover:border-slate-600 transition-all duration-300 ${
									!asset.available ? 'opacity-60' : 'hover:bg-slate-800/70'
								}`}
							>
								{/* Asset Header */}
								<div className="flex items-center justify-between mb-4">
									<div className="flex items-center space-x-3">
										<div className={`w-12 h-12 ${getAssetColor(asset.type)} rounded-lg flex items-center justify-center text-2xl`}>
										</div>
										<div>
											<h3 className="text-lg font-semibold text-white capitalize">
												{asset.type}
											</h3>
											<div className="flex items-center space-x-2">
												<span className="text-slate-300 text-sm">Rating:</span>
												<span className="text-slate-300 text-sm">{asset.rating}</span>
											</div>
										</div>
									</div>
									<div className={`px-3 py-1 rounded-full text-xs font-medium ${
										asset.available 
											? 'bg-green-500/20 text-green-400 border border-green-500/30' 
											: 'bg-red-500/20 text-red-400 border border-red-500/30'
									}`}>
										{asset.available ? 'Available' : 'In Use'}
									</div>
								</div>

								{/* Asset Details */}
								<div className="space-y-3">
									<div className="flex justify-between items-center">
										<span className="text-slate-400">Deposit Required</span>
										<span className="text-white font-semibold">${asset.deposit} PYUSD</span>
									</div>
									
									<div className="flex justify-between items-center">
										<span className="text-slate-400">Est. Duration</span>
										<span className="text-white">{asset.estimatedDuration}</span>
									</div>

									{asset.distance && (
										<div className="flex justify-between items-center">
											<span className="text-slate-400">Distance</span>
											<span className="text-white">{asset.distance}</span>
										</div>
									)}

									<div className="pt-2 border-t border-slate-700">
										<div className="text-slate-400 text-sm mb-1">Route Info</div>
										<div className="text-white text-sm">{asset.route}</div>
									</div>

									<div className="text-slate-400 text-sm">
										{asset.location}
									</div>
								</div>

								{/* Action Button */}
								<button
									onClick={() => router.push(`/rental/${asset.id}`)}
									disabled={!asset.available}
									className={`w-full mt-4 py-3 px-4 rounded-lg font-medium transition-colors ${
										asset.available
											? 'bg-purple-600 hover:bg-purple-700 text-white'
											: 'bg-slate-700 text-slate-400 cursor-not-allowed'
									}`}
								>
									{asset.available ? 'Start Rental' : 'Currently Unavailable'}
								</button>
							</div>
						))}
					</div>

					{filteredAssets.length === 0 && (
						<div className="text-center py-12">
							<div className="text-6xl mb-4"></div>
							<h3 className="text-xl font-semibold text-white mb-2">No assets found</h3>
							<p className="text-slate-400">Try selecting a different location or check back later</p>
						</div>
					)}
				</div>
			</div>
		</div>
	);
}
