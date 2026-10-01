import React from 'react';
import { ParkingLot } from '../types/parking';
import { Check, X, MapPin, DollarSign, Clock } from 'lucide-react';

interface ApprovalsModalProps {
  pendingLots: ParkingLot[];
  onApprove: (lotId: string) => Promise<void>;
  onReject: (lotId: string) => Promise<void>;
}

export const ApprovalsModal: React.FC<ApprovalsModalProps> = ({
  pendingLots,
  onApprove,
  onReject,
}) => {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-6">
        <h2 className="text-xl font-bold text-slate-900">Danh sách bãi xe chờ duyệt</h2>
        <p className="text-sm text-slate-500">Các bãi đỗ xe do tài xế hoặc chủ bãi gửi đề xuất lên hệ thống.</p>
      </div>

      {pendingLots.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-slate-200 shadow-sm">
          <div className="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
            <Check className="w-8 h-8" />
          </div>
          <h3 className="text-base font-semibold text-slate-800">Không có bãi xe nào đang chờ duyệt!</h3>
          <p className="text-xs text-slate-500 mt-1">Khi tài xế gửi đề xuất bãi mới từ app, yêu cầu sẽ xuất hiện tại đây.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {pendingLots.map((lot) => (
            <div key={lot.id} className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden flex flex-col">
              {lot.image_url ? (
                <img src={lot.image_url} alt={lot.name} className="h-44 w-full object-cover" />
              ) : (
                <div className="h-44 bg-slate-100 flex items-center justify-center text-slate-400 text-sm">
                  Không có ảnh đính kèm
                </div>
              )}

              <div className="p-5 flex-1 flex flex-col justify-between">
                <div>
                  <h4 className="font-bold text-base text-slate-900 mb-1">{lot.name}</h4>
                  <p className="text-xs text-slate-600 flex items-start mb-3">
                    <MapPin className="w-3.5 h-3.5 mr-1 text-slate-400 shrink-0 mt-0.5" />
                    <span>{lot.address}</span>
                  </p>

                  <div className="bg-slate-50 p-3 rounded-xl space-y-1.5 text-xs text-slate-600 mb-4">
                    <div className="flex justify-between">
                      <span>Giá theo giờ:</span>
                      <strong className="text-blue-600">{lot.price_per_hour.toLocaleString()}đ</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Giá theo lượt:</span>
                      <strong>{lot.price_per_turn.toLocaleString()}đ</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Sức chứa:</span>
                      <strong>{lot.total_capacity} chỗ</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Tọa độ:</span>
                      <span className="font-mono text-[11px]">{lot.latitude.toFixed(4)}, {lot.longitude.toFixed(4)}</span>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3 pt-3 border-t border-slate-100">
                  <button
                    onClick={() => onReject(lot.id)}
                    className="flex items-center justify-center space-x-1.5 py-2 px-3 border border-rose-300 text-rose-700 bg-rose-50 hover:bg-rose-100 rounded-xl text-xs font-semibold transition-colors"
                  >
                    <X className="w-4 h-4" />
                    <span>Từ chối</span>
                  </button>
                  <button
                    onClick={() => onApprove(lot.id)}
                    className="flex items-center justify-center space-x-1.5 py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-semibold shadow-md transition-colors"
                  >
                    <Check className="w-4 h-4" />
                    <span>Duyệt bãi</span>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
