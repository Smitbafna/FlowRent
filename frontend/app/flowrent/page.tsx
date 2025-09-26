"use client";
import Header from '../components/Header';
import HeroSection from '../components/HeroSection';
import HowItWorks from '../components/HowItWorks';
import WhyFlowRent from '../components/WhyFlowRent';
import Footer from '../components/Footer';

export default function FlowRentLanding() {
	return (
		<div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
			<Header />
			<HeroSection />
			<HowItWorks />
			<WhyFlowRent />
			
			{/* CTA Section */}
			<section className="py-20 px-6 bg-gradient-to-r from-teal-600 to-teal-700">
				<div className="max-w-4xl mx-auto text-center">
					<h2 className="text-4xl font-bold text-white mb-6">Ready to Transform Your Rentals?</h2>
					<p className="text-xl text-teal-100 mb-8 max-w-2xl mx-auto">
						Join the future of rental payments with privacy-preserving identity verification and stable micropayments.
					</p>
					<div className="flex flex-col sm:flex-row gap-4 justify-center">
						<a
							href="/"
							className="bg-white text-teal-600 hover:bg-slate-100 px-8 py-4 rounded-lg font-semibold text-lg transition-all duration-200 hover:scale-105 transform hover:shadow-lg inline-block"
						>
							Start Verification Now
						</a>
						<a 
							href="/status"
							className="border-2 border-white text-white hover:bg-white hover:text-teal-600 px-8 py-4 rounded-lg font-semibold text-lg transition-all duration-200 hover:scale-105 flex items-center justify-center"
						>
							Check Status
						</a>
					</div>
				</div>
			</section>

			<Footer />
		</div>
	);
}
