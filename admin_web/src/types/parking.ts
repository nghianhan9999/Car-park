export type ParkingStatus = 'available' | 'nearly_full' | 'full' | 'closed';

export interface ParkingLot {
  id: string;
  name: string;
  address: string;
  district: string;
  city: string;
  latitude: number;
  longitude: number;
  price_per_hour: number;
  price_per_turn: number;
  price_overnight: number;
  total_capacity: number;
  current_status: ParkingStatus;
  status_updated_at: string;
  open_time: string;
  close_time: string;
  is_24h: boolean;
  has_roof: boolean;
  has_ev_charging: boolean;
  has_security: boolean;
  has_camera: boolean;
  phone_number?: string;
  image_url?: string;
  is_approved: boolean;
  created_at: string;
  distance_meters?: number;
}

export interface ParkingReport {
  id: string;
  lot_id: string;
  user_id?: string;
  report_type: 'full' | 'available' | 'wrong_price' | 'closed' | 'other';
  reported_price?: number;
  notes?: string;
  is_reviewed: boolean;
  created_at: string;
  parking_lots?: {
    name: string;
    address: string;
  };
}
