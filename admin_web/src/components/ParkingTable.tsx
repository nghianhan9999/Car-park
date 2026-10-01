import React, { useState } from 'react';
import { ParkingLot, ParkingStatus } from '../types/parking';
import { Search, Edit, Trash2, Shield, Zap, Umbrella, Video, ExternalLink } from 'lucide-react';

interface ParkingTableProps {
  lots: ParkingLot[];
  onUpdateStatus: (lotId: string, status: ParkingStatus) => Promise<void>;
  onEditLot: (lot: ParkingLot) => void;
  onDeleteLot: (lotId: string) => Promise<void>;
}

export const ParkingTable: React.FC<ParkingTableProps> = ({
  lots,
  onUpdateStatus,
  onEditLot,
  onDeleteLot,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const filteredLots = lots.filter((lot) => {
    const matchesSearch =
      lot.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lot.address.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || lot.current_status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusBadge = (status: ParkingStatus) => {
    switch (status) {
      case 'available':
        return <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800 border border-green-200">🟢 Còn chỗ</span>;
      case 'nearly_full':
        return <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-orange-100 text-orange-800 border border-orange-200">🟡 Sắp đầy</span>;
      case 'full':
        return <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800 border border-red-200">🔴 Hết chỗ</span>;
      case 'closed':
        return <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-slate-100 text-slate-700 border border-slate-200">⚫ Đóng cửa</span>;
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Search & Filter Header */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 mb-6 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="relative w-full sm:w-96">
          <Search className="w-5 h-5 text-slate-400 absolute left-3 top-2.5" />
          <input
            type="text"
            placeholder="Tìm theo tên bãi xe hoặc đường..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        <div className="flex items-center space-x-2 w-full sm:w-auto">
          <label className="text-xs font-medium text-slate-500 whitespace-nowrap">Lọc trạng thái:</label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="border border-slate-300 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">Tất cả ({lots.length})</option>
            <option value="available">🟢 Còn chỗ</option>
            <option value="nearly_full">🟡 Sắp đầy</option>
            <option value="full">🔴 Hết chỗ</option>
            <option value="closed">⚫ Đóng cửa</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3.5 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">Tên & Địa chỉ bãi xe</th>
                <th className="px-6 py-3.5 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">Trạng thái hiện tại</th>
                <th className="px-6 py-3.5 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">Bảng giá (VNĐ)</th>
                <th className="px-6 py-3.5 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">Sức chứa & Giờ mở</th>
                <th className="px-6 py-3.5 text-left text-xs font-bold text-slate-500 uppercase tracking-wider">Tiện ích</th>
                <th className="px-6 py-3.5 text-right text-xs font-bold text-slate-500 uppercase tracking-wider">Thao tác</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-slate-200 text-sm">
              {filteredLots.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-500">
                    Không tìm thấy bãi xe nào phù hợp.
                  </td>
                </tr>
              ) : (
                filteredLots.map((lot) => (
                  <tr key={lot.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-6 py-4">
                      <div className="font-semibold text-slate-900">{lot.name}</div>
                      <div className="text-xs text-slate-500 mt-0.5">{lot.address}</div>
                      {lot.phone_number && (
                        <div className="text-xs text-blue-600 font-medium mt-1">📞 {lot.phone_number}</div>
                      )}
                    </td>

                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="mb-2">{getStatusBadge(lot.current_status)}</div>
                      <select
                        value={lot.current_status}
                        onChange={(e) => onUpdateStatus(lot.id, e.target.value as ParkingStatus)}
                        className="text-xs border border-slate-300 rounded px-2 py-1 bg-white hover:bg-slate-50 cursor-pointer"
                      >
                        <option value="available">🟢 Đổi sang: Còn chỗ</option>
                        <option value="nearly_full">🟡 Đổi sang: Sắp đầy</option>
                        <option value="full">🔴 Đổi sang: Hết chỗ</option>
                        <option value="closed">⚫ Đổi sang: Đóng cửa</option>
                      </select>
                    </td>

                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-xs space-y-0.5">
                        <div>Giờ: <strong className="text-blue-600 font-bold">{lot.price_per_hour.toLocaleString()}đ</strong></div>
                        <div>Lượt: <strong>{lot.price_per_turn.toLocaleString()}đ</strong></div>
                        <div>Đêm: <strong>{lot.price_overnight.toLocaleString()}đ</strong></div>
                      </div>
                    </td>

                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-xs font-medium text-slate-700">{lot.total_capacity} chỗ đỗ</div>
                      <div className="text-xs text-slate-500 mt-1">
                        {lot.is_24h ? 'Mở cửa 24/24' : `${lot.open_time} - ${lot.close_time}`}
                      </div>
                    </td>

                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2 text-slate-600">
                        {lot.has_roof && <span title="Có mái che" className="p-1 bg-blue-50 text-blue-600 rounded"><Umbrella className="w-3.5 h-3.5" /></span>}
                        {lot.has_ev_charging && <span title="Có trạm sạc xe điện" className="p-1 bg-green-50 text-green-600 rounded"><Zap className="w-3.5 h-3.5" /></span>}
                        {lot.has_camera && <span title="Có camera an ninh" className="p-1 bg-purple-50 text-purple-600 rounded"><Video className="w-3.5 h-3.5" /></span>}
                        {lot.has_security && <span title="Có bảo vệ trực" className="p-1 bg-amber-50 text-amber-600 rounded"><Shield className="w-3.5 h-3.5" /></span>}
                      </div>
                    </td>

                    <td className="px-6 py-4 whitespace-nowrap text-right text-xs font-medium">
                      <div className="flex items-center justify-end space-x-2">
                        <button
                          onClick={() => onEditLot(lot)}
                          className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Sửa thông tin"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => onDeleteLot(lot.id)}
                          className="p-1.5 text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
                          title="Xóa bãi xe"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
