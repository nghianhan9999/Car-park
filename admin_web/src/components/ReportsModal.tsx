import React from 'react';
import { ParkingReport } from '../types/parking';
import { Check, AlertCircle, Clock, DollarSign } from 'lucide-react';

interface ReportsModalProps {
  reports: ParkingReport[];
  onResolveReport: (reportId: string) => Promise<void>;
}

export const ReportsModal: React.FC<ReportsModalProps> = ({ reports, onResolveReport }) => {
  const getReportTypeBadge = (type: ParkingReport['report_type']) => {
    switch (type) {
      case 'wrong_price':
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-amber-100 text-amber-800">💰 Giá khác niêm yết</span>;
      case 'closed':
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-rose-100 text-rose-800">🚫 Bãi đã đóng cửa</span>;
      case 'full':
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-red-100 text-red-800">🔴 Bãi đã hết chỗ</span>;
      case 'available':
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-green-100 text-green-800">🟢 Bãi vẫn còn chỗ</span>;
      default:
        return <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-slate-100 text-slate-800">📝 Khác</span>;
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-6">
        <h2 className="text-xl font-bold text-slate-900">Báo cáo & Phản ánh từ Tài xế</h2>
        <p className="text-sm text-slate-500">Các báo cáo về tình trạng sai giá, bãi đóng cửa hoặc hết chỗ thực tế.</p>
      </div>

      {reports.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-slate-200 shadow-sm">
          <div className="w-16 h-16 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-4">
            <Check className="w-8 h-8" />
          </div>
          <h3 className="text-base font-semibold text-slate-800">Không có báo cáo nào chưa xử lý!</h3>
          <p className="text-xs text-slate-500 mt-1">Hệ thống đang hoạt động ổn định và chính xác.</p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden divide-y divide-slate-100">
          {reports.map((report) => (
            <div key={report.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50/60 transition-colors">
              <div className="space-y-1.5 flex-1">
                <div className="flex items-center space-x-2.5">
                  {getReportTypeBadge(report.report_type)}
                  <span className="text-xs text-slate-400">
                    {new Date(report.created_at).toLocaleString('vi-VN')}
                  </span>
                </div>

                <div className="font-semibold text-slate-900 text-sm">
                  {report.parking_lots?.name || 'Bãi xe'}
                </div>

                {report.notes && (
                  <p className="text-xs text-slate-600 bg-slate-50 p-2.5 rounded-lg border border-slate-200/60 max-w-2xl">
                    "{report.notes}"
                  </p>
                )}

                {report.reported_price && (
                  <div className="text-xs text-amber-700 font-medium">
                    Giá tài xế phản ánh: {report.reported_price.toLocaleString()}đ
                  </div>
                )}
              </div>

              <div className="flex items-center">
                <button
                  onClick={() => onResolveReport(report.id)}
                  className="flex items-center space-x-1.5 px-4 py-2 bg-slate-100 hover:bg-green-600 text-slate-700 hover:text-white rounded-xl text-xs font-semibold transition-all shadow-sm"
                >
                  <Check className="w-4 h-4" />
                  <span>Đã giải quyết</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
