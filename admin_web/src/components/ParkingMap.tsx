import React, { useEffect, useRef } from 'react';
import L from 'leaflet';
import { ParkingLot, ParkingStatus } from '../types/parking';
import { Shield, Zap, Umbrella, Video, Phone, Clock, DollarSign } from 'lucide-react';

interface ParkingMapProps {
  lots: ParkingLot[];
  onUpdateStatus: (lotId: string, status: ParkingStatus) => Promise<void>;
  onEditLot: (lot: ParkingLot) => void;
}

export const ParkingMap: React.FC<ParkingMapProps> = ({ lots, onUpdateStatus, onEditLot }) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<{ [key: string]: L.Marker }>({});

  const getStatusColor = (status: ParkingStatus) => {
    switch (status) {
      case 'available':
        return '#16a34a'; // green-600
      case 'nearly_full':
        return '#ea580c'; // orange-600
      case 'full':
        return '#dc2626'; // red-600
      case 'closed':
        return '#64748b'; // slate-500
    }
  };

  const getStatusLabel = (status: ParkingStatus) => {
    switch (status) {
      case 'available':
        return '🟢 Còn chỗ';
      case 'nearly_full':
        return '🟡 Sắp đầy';
      case 'full':
        return '🔴 Hết chỗ';
      case 'closed':
        return '⚫ Đang đóng cửa';
    }
  };

  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Initialize Leaflet Map centered at Ninh Kieu, Can Tho
    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current).setView([10.0336, 105.7876], 14);

      // OpenStreetMap standard tiles
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors | Can Tho Car Park',
        maxZoom: 19,
      }).addTo(map);

      mapInstanceRef.current = map;
    }

    const map = mapInstanceRef.current;

    // Clear existing markers
    Object.values(markersRef.current).forEach((marker) => marker.remove());
    markersRef.current = {};

    // Add markers for each lot
    lots.forEach((lot) => {
      const color = getStatusColor(lot.current_status);
      const customIcon = L.divIcon({
        className: 'custom-pin-wrapper',
        html: `
          <div style="
            background-color: ${color};
            width: 34px;
            height: 34px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 13px;
            border: 3px solid white;
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
            cursor: pointer;
            transition: transform 0.2s;
          ">
            P
          </div>
        `,
        iconSize: [34, 34],
        iconAnchor: [17, 17],
        popupAnchor: [0, -18],
      });

      const marker = L.marker([lot.latitude, lot.longitude], { icon: customIcon }).addTo(map);

      // Bind popup with details & 1-tap status switch
      const popupContent = document.createElement('div');
      popupContent.className = 'p-1 text-slate-800 min-w-[280px] max-w-[320px]';
      popupContent.innerHTML = `
        <div class="font-bold text-base text-slate-900 border-b pb-1 mb-2">${lot.name}</div>
        <p class="text-xs text-slate-600 mb-2 leading-relaxed">${lot.address}</p>
        
        <div class="grid grid-cols-2 gap-1.5 text-xs bg-slate-50 p-2 rounded-lg mb-3">
          <div><span class="text-slate-500">Giá giờ:</span> <strong class="text-blue-600">${lot.price_per_hour.toLocaleString()}đ</strong></div>
          <div><span class="text-slate-500">Giá lượt:</span> <strong>${lot.price_per_turn.toLocaleString()}đ</strong></div>
          <div><span class="text-slate-500">Qua đêm:</span> <strong>${lot.price_overnight.toLocaleString()}đ</strong></div>
          <div><span class="text-slate-500">Sức chứa:</span> <strong>${lot.total_capacity} xe</strong></div>
          <div><span class="text-slate-500">Giờ mở:</span> <strong>${lot.is_24h ? '24/24' : `${lot.open_time} - ${lot.close_time}`}</strong></div>
          <div><span class="text-slate-500">Hotline:</span> <strong>${lot.phone_number || 'Chưa có'}</strong></div>
        </div>

        <div class="text-xs font-semibold text-slate-700 mb-1.5">⚡ Đổi nhanh trạng thái:</div>
        <div class="grid grid-cols-2 gap-1.5 mb-2">
          <button data-status="available" class="status-btn px-2 py-1.5 text-xs rounded font-medium bg-green-50 text-green-700 border border-green-200 hover:bg-green-100 flex items-center justify-center">🟢 Còn chỗ</button>
          <button data-status="nearly_full" class="status-btn px-2 py-1.5 text-xs rounded font-medium bg-orange-50 text-orange-700 border border-orange-200 hover:bg-orange-100 flex items-center justify-center">🟡 Sắp đầy</button>
          <button data-status="full" class="status-btn px-2 py-1.5 text-xs rounded font-medium bg-red-50 text-red-700 border border-red-200 hover:bg-red-100 flex items-center justify-center">🔴 Hết chỗ</button>
          <button data-status="closed" class="status-btn px-2 py-1.5 text-xs rounded font-medium bg-slate-100 text-slate-700 border border-slate-300 hover:bg-slate-200 flex items-center justify-center">⚫ Đóng cửa</button>
        </div>
      `;

      // Attach event listeners for status buttons
      popupContent.querySelectorAll('.status-btn').forEach((btn) => {
        btn.addEventListener('click', (e) => {
          const targetStatus = (e.currentTarget as HTMLElement).getAttribute('data-status') as ParkingStatus;
          if (targetStatus) {
            onUpdateStatus(lot.id, targetStatus);
            marker.closePopup();
          }
        });
      });

      marker.bindPopup(popupContent);
      markersRef.current[lot.id] = marker;
    });
  }, [lots, onUpdateStatus]);

  return (
    <div className="relative w-full h-[calc(100vh-64px)]">
      <div ref={mapContainerRef} className="w-full h-full z-10" />

      {/* Map Legend */}
      <div className="absolute bottom-6 left-6 z-20 bg-white/95 backdrop-blur-sm p-4 rounded-xl shadow-lg border border-slate-200/80 max-w-xs">
        <h4 className="font-bold text-xs uppercase tracking-wider text-slate-500 mb-2">Chú thích trạng thái</h4>
        <div className="space-y-1.5 text-xs font-medium text-slate-700">
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-green-600"></span>
            <span>Còn nhiều chỗ (Bình thường)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-orange-600"></span>
            <span>Sắp đầy (Còn dưới 5 chỗ)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-red-600"></span>
            <span>Hết chỗ đỗ ô tô</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-slate-500"></span>
            <span>Đang đóng cửa / Ngưng nhận xe</span>
          </div>
        </div>
        <p className="text-[11px] text-slate-400 mt-2 border-t pt-2">
          👉 Bấm vào bất kỳ bãi xe nào trên bản đồ để đổi trạng thái nhanh bằng 1 chạm.
        </p>
      </div>
    </div>
  );
};
