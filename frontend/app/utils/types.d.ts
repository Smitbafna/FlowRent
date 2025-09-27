// types.d.ts
interface Window {
  ethereum?: any;
}

interface RentalDetails {
  renter: string;
  provider: string;
  vehicleId: number;
  depositAmount: bigint;
  hourlyRate: bigint;
  startTime: number;
  endTime: number;
  durationInMinutes: number;
  streamId: number;
  status: number;
}
