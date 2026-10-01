import React, { useState, useEffect } from 'react';
import { ParkingLot } from '../types/parking';
import { X, Save, MapPin } from 'lucide-react';

interface AddEditLotModalProps {
  isOpen: boolean;
  onClose: () => void;
  lot: ParkingLot | null;
  onSave: (data: Partial<ParkingLot>) => Promise<void>;
}

export const AddEditLotModal: React.FC<AddEditLotModalProps> = ({
  isOpen,
  onClose,
  lot,
  onSave,
}) => {
  const [formData, setFormData] = useState<Partial<ParkingLot>>({
    name: '',
    address: '',
    district: 'Ninh Kiều',
    city: 'Cần Thơ',
    latitude: 10.0336,
    longitude: 105.7876,
    price_per_hour: 10000,
    price_per_turn: 20000,
    price_overnight: 50000,
    total_capacity: 30,
    current_status: 'available',
    open_time: '06:00',
    close_time: '22:00',
    is_24h: false,
    has_roof: false,
    has_ev_charging: false,
    has_security: true,
    has_camera: true,
    phone_number: '',
    image_url: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=600&q=80',
    is_approved: true,
  });

  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (lot) {
      setFormData(lot);
    } else {
      setFormData({
        name: '',
        address: '',
        district: 'Ninh Kiều',
        city: 'Cần Thơ',
        latitude: 10.0336,
        longitude: 105.7876,
        price_per_hour: 10000,
        price_per_turn: 20000,
        price_overnight: 50000,
        total_capacity: 30,
        current_status: 'available',
        open_time: '06:00',
        close_time: '22:00',
        is_24h: false,
        has_roof: false,
        has_ev_charging: false,
        has_security: true,
        has_camera: true,
        phone_number: '',
        image_url: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&w=600&q=80',
        is_approved: true,
      });
    }
  }, [lot, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await onSave(formData);
      onClose();
    } catch (err) {
      console.error(err);
      alert('Có lỗi xảy ra khi lưu dữ liệu!');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/50 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl max-w-2xl w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <div className="flex justify-between items-center px-6 py-4 border-b border-slate-200 bg-slate-50">
          <h3 className="text-lg font-bold text-slate-900">
            {lot ? 'Chỉnh sửa thông tin bãi xe' : 'Thêm bãi đỗ xe ô tô mới'}
          </h3>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 p-1 rounded-lg hover:bg-slate-200 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4 max-h-[80vh] overflow-y-auto">
          {/* Tên & Địa chỉ */}
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Tên bãi đỗ xe *
              </label>
              <input
                type="text"
                required
                value={formData.name || ''}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: Bãi đỗ xe Bến Ninh Kiều"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Địa chỉ chi tiết *
              </label>
              <input
                type="text"
                required
                value={formData.address || ''}
                onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                placeholder="VD: Số 2 Đường Hai Bà Trưng, P. Tân An, Q. Ninh Kiều"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none"
              />
            </div>
          </div>

          {/* Tọa độ Lat, Long */}
          <div className="grid grid-cols-2 gap-3 bg-blue-50/50 p-3 rounded-xl border border-blue-100">
            <div>
              <label className="block text-xs font-semibold text-blue-900 uppercase mb-1 flex items-center">
                <MapPin className="w-3.5 h-3.5 mr-1" /> Vĩ độ (Latitude) *
              </label>
              <input
                type="number"
                step="any"
                required
                value={formData.latitude || ''}
                onChange={(e) => setFormData({ ...formData, latitude: parseFloat(e.target.value) })}
                className="w-full px-3 py-1.5 bg-white border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-blue-900 uppercase mb-1 flex items-center">
                <MapPin className="w-3.5 h-3.5 mr-1" /> Kinh độ (Longitude) *
              </label>
              <input
                type="number"
                step="any"
                required
                value={formData.longitude || ''}
                onChange={(e) => setFormData({ ...formData, longitude: parseFloat(e.target.value) })}
                className="w-full px-3 py-1.5 bg-white border border-slate-300 rounded-lg text-sm"
              />
            </div>
          </div>

          {/* Giá tiền */}
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Giá theo giờ (VNĐ)
              </label>
              <input
                type="number"
                value={formData.price_per_hour || 0}
                onChange={(e) => setFormData({ ...formData, price_per_hour: parseInt(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Giá theo lượt (VNĐ)
              </label>
              <input
                type="number"
                value={formData.price_per_turn || 0}
                onChange={(e) => setFormData({ ...formData, price_per_turn: parseInt(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Gửi qua đêm (VNĐ)
              </label>
              <input
                type="number"
                value={formData.price_overnight || 0}
                onChange={(e) => setFormData({ ...formData, price_overnight: parseInt(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
          </div>

          {/* Sức chứa & Số điện thoại */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Tổng sức chứa (ô tô)
              </label>
              <input
                type="number"
                value={formData.total_capacity || 30}
                onChange={(e) => setFormData({ ...formData, total_capacity: parseInt(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Số hotline liên hệ
              </label>
              <input
                type="text"
                value={formData.phone_number || ''}
                onChange={(e) => setFormData({ ...formData, phone_number: e.target.value })}
                placeholder="VD: 02923812345"
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
          </div>

          {/* Giờ mở cửa */}
          <div className="grid grid-cols-3 gap-3 items-center">
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Giờ mở cửa
              </label>
              <input
                type="time"
                value={formData.open_time || '06:00'}
                onChange={(e) => setFormData({ ...formData, open_time: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 uppercase mb-1">
                Giờ đóng cửa
              </label>
              <input
                type="time"
                value={formData.close_time || '22:00'}
                onChange={(e) => setFormData({ ...formData, close_time: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm"
              />
            </div>
            <div className="pt-5">
              <label className="flex items-center space-x-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.is_24h || false}
                  onChange={(e) => setFormData({ ...formData, is_24h: e.target.checked })}
                  className="rounded text-blue-600 focus:ring-blue-500 w-4 h-4"
                />
                <span className="text-xs font-medium text-slate-700">Mở 24/24</span>
              </label>
            </div>
          </div>

          {/* Tiện ích */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase mb-2">
              Tiện ích bãi xe
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <label className="flex items-center space-x-2 p-2 border border-slate-200 rounded-lg bg-slate-50 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.has_roof || false}
                  onChange={(e) => setFormData({ ...formData, has_roof: e.target.checked })}
                  className="rounded text-blue-600 focus:ring-blue-500"
                />
                <span className="text-xs text-slate-700">Có mái che</span>
              </label>

              <label className="flex items-center space-x-2 p-2 border border-slate-200 rounded-lg bg-slate-50 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.has_ev_charging || false}
                  onChange={(e) => setFormData({ ...formData, has_ev_charging: e.target.checked })}
                  className="rounded text-blue-600 focus:ring-blue-500"
                />
                <span className="text-xs text-slate-700">Sạc xe điện</span>
              </label>

              <label className="flex items-center space-x-2 p-2 border border-slate-200 rounded-lg bg-slate-50 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.has_security || false}
                  onChange={(e) => setFormData({ ...formData, has_security: e.target.checked })}
                  className="rounded text-blue-600 focus:ring-blue-500"
                />
                <span className="text-xs text-slate-700">Có bảo vệ</span>
              </label>

              <label className="flex items-center space-x-2 p-2 border border-slate-200 rounded-lg bg-slate-50 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.has_camera || false}
                  onChange={(e) => setFormData({ ...formData, has_camera: e.target.checked })}
                  className="rounded text-blue-600 focus:ring-blue-500"
                />
                <span className="text-xs text-slate-700">Có camera</span>
              </label>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-200 flex justify-end space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
            >
              Hủy bỏ
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex items-center space-x-2 px-5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold shadow-md transition-colors disabled:opacity-50"
            >
              <Save className="w-4 h-4" />
              <span>{isSubmitting ? 'Đang lưu...' : 'Lưu thông tin'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
