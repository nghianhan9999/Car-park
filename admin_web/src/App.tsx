import React, { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { ParkingLot, ParkingReport, ParkingStatus } from './types/parking';
import { Navbar } from './components/Navbar';
import { ParkingMap } from './components/ParkingMap';
import { ParkingTable } from './components/ParkingTable';
import { ApprovalsModal } from './components/ApprovalsModal';
import { ReportsModal } from './components/ReportsModal';
import { AddEditLotModal } from './components/AddEditLotModal';
import { Car, CheckCircle2, AlertCircle, Clock } from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState<'map' | 'table' | 'approvals' | 'reports'>('map');
  const [lots, setLots] = useState<ParkingLot[]>([]);
  const [pendingLots, setPendingLots] = useState<ParkingLot[]>([]);
  const [reports, setReports] = useState<ParkingReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isAddEditOpen, setIsAddEditOpen] = useState(false);
  const [editingLot, setEditingLot] = useState<ParkingLot | null>(null);

  // Fetch all lots & reports from Supabase
  const fetchData = async () => {
    setIsRefreshing(true);
    try {
      // 1. Fetch approved lots
      const { data: approvedData, error: lotErr } = await supabase
        .from('parking_lots')
        .select('*')
        .eq('is_approved', true)
        .order('name');

      if (lotErr) throw lotErr;
      setLots(approvedData || []);

      // 2. Fetch pending lots
      const { data: pendingData, error: pendingErr } = await supabase
        .from('parking_lots')
        .select('*')
        .eq('is_approved', false)
        .order('created_at', { ascending: false });

      if (pendingErr) throw pendingErr;
      setPendingLots(pendingData || []);

      // 3. Fetch unresolved reports
      const { data: reportData, error: reportErr } = await supabase
        .from('reports')
        .select(`
          *,
          parking_lots (
            name,
            address
          )
        `)
        .eq('is_reviewed', false)
        .order('created_at', { ascending: false });

      if (reportErr) throw reportErr;
      setReports(reportData || []);
    } catch (err) {
      console.error('Error fetching data from Supabase:', err);
    } finally {
      setLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();

    // Setup Supabase Realtime listener on parking_lots
    const channel = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'parking_lots' },
        (payload) => {
          console.log('Realtime change received:', payload);
          fetchData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // Update status (1-tap)
  const handleUpdateStatus = async (lotId: string, status: ParkingStatus) => {
    try {
      const { error } = await supabase
        .from('parking_lots')
        .update({
          current_status: status,
          status_updated_at: new Date().toISOString(),
        })
        .eq('id', lotId);

      if (error) throw error;

      // Optimistic update
      setLots((prev) =>
        prev.map((lot) => (lot.id === lotId ? { ...lot, current_status: status } : lot))
      );
    } catch (err) {
      console.error('Lỗi khi cập nhật trạng thái:', err);
      alert('Không thể cập nhật trạng thái bãi xe!');
    }
  };

  // Save (Create or Update)
  const handleSaveLot = async (formData: Partial<ParkingLot>) => {
    try {
      if (editingLot) {
        // Update
        const { error } = await supabase
          .from('parking_lots')
          .update(formData)
          .eq('id', editingLot.id);
        if (error) throw error;
      } else {
        // Create
        const { error } = await supabase.from('parking_lots').insert([formData]);
        if (error) throw error;
      }
      fetchData();
    } catch (err) {
      console.error('Lỗi lưu bãi xe:', err);
      throw err;
    }
  };

  // Delete lot
  const handleDeleteLot = async (lotId: string) => {
    if (!window.confirm('Bạn có chắc chắn muốn xóa bãi đỗ xe này khỏi hệ thống?')) return;
    try {
      const { error } = await supabase.from('parking_lots').delete().eq('id', lotId);
      if (error) throw error;
      setLots((prev) => prev.filter((l) => l.id !== lotId));
    } catch (err) {
      console.error('Lỗi khi xóa:', err);
      alert('Không thể xóa bãi xe!');
    }
  };

  // Approve pending lot
  const handleApproveLot = async (lotId: string) => {
    try {
      const { error } = await supabase
        .from('parking_lots')
        .update({ is_approved: true })
        .eq('id', lotId);
      if (error) throw error;
      fetchData();
    } catch (err) {
      console.error('Lỗi duyệt bãi:', err);
      alert('Không thể duyệt bãi xe!');
    }
  };

  // Reject pending lot
  const handleRejectLot = async (lotId: string) => {
    if (!window.confirm('Bạn có chắc muốn từ chối và xóa đề xuất này?')) return;
    try {
      const { error } = await supabase.from('parking_lots').delete().eq('id', lotId);
      if (error) throw error;
      fetchData();
    } catch (err) {
      console.error('Lỗi từ chối bãi:', err);
    }
  };

  // Resolve driver report
  const handleResolveReport = async (reportId: string) => {
    try {
      const { error } = await supabase
        .from('reports')
        .update({ is_reviewed: true })
        .eq('id', reportId);
      if (error) throw error;
      setReports((prev) => prev.filter((r) => r.id !== reportId));
    } catch (err) {
      console.error('Lỗi xử lý báo cáo:', err);
    }
  };

  const availableCount = lots.filter((l) => l.current_status === 'available').length;
  const nearlyFullCount = lots.filter((l) => l.current_status === 'nearly_full').length;
  const fullCount = lots.filter((l) => l.current_status === 'full').length;

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      {/* Header Navbar */}
      <Navbar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        pendingCount={pendingLots.length}
        reportCount={reports.length}
        onAddNew={() => {
          setEditingLot(null);
          setIsAddEditOpen(true);
        }}
        onRefresh={fetchData}
        isRefreshing={isRefreshing}
      />

      {/* Quick Overview Strip */}
      <div className="bg-white border-b border-slate-200 py-3 shadow-xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-wrap items-center justify-between gap-4 text-xs font-medium">
            <div className="flex items-center space-x-6">
              <div className="flex items-center space-x-1.5 text-slate-700">
                <Car className="w-4 h-4 text-slate-400" />
                <span>Tổng số bãi: <strong className="text-slate-900">{lots.length}</strong></span>
              </div>
              <div className="flex items-center space-x-1.5 text-green-700">
                <span className="w-2 h-2 rounded-full bg-green-500"></span>
                <span>Còn nhiều chỗ: <strong>{availableCount}</strong></span>
              </div>
              <div className="flex items-center space-x-1.5 text-orange-700">
                <span className="w-2 h-2 rounded-full bg-orange-500"></span>
                <span>Sắp đầy: <strong>{nearlyFullCount}</strong></span>
              </div>
              <div className="flex items-center space-x-1.5 text-red-700">
                <span className="w-2 h-2 rounded-full bg-red-500"></span>
                <span>Hết chỗ: <strong>{fullCount}</strong></span>
              </div>
            </div>

            <div className="flex items-center space-x-2 text-slate-400">
              <Clock className="w-3.5 h-3.5" />
              <span>Realtime: Đang đồng bộ tự động với Supabase</span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <main className="flex-1">
        {loading ? (
          <div className="h-[60vh] flex flex-col items-center justify-center space-y-3">
            <div className="w-8 h-8 border-3 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
            <p className="text-sm font-medium text-slate-500">Đang tải dữ liệu bãi xe Cần Thơ...</p>
          </div>
        ) : (
          <>
            {activeTab === 'map' && (
              <ParkingMap
                lots={lots}
                onUpdateStatus={handleUpdateStatus}
                onEditLot={(lot) => {
                  setEditingLot(lot);
                  setIsAddEditOpen(true);
                }}
              />
            )}

            {activeTab === 'table' && (
              <ParkingTable
                lots={lots}
                onUpdateStatus={handleUpdateStatus}
                onEditLot={(lot) => {
                  setEditingLot(lot);
                  setIsAddEditOpen(true);
                }}
                onDeleteLot={handleDeleteLot}
              />
            )}

            {activeTab === 'approvals' && (
              <ApprovalsModal
                pendingLots={pendingLots}
                onApprove={handleApproveLot}
                onReject={handleRejectLot}
              />
            )}

            {activeTab === 'reports' && (
              <ReportsModal
                reports={reports}
                onResolveReport={handleResolveReport}
              />
            )}
          </>
        )}
      </main>

      {/* Modal Add / Edit Lot */}
      <AddEditLotModal
        isOpen={isAddEditOpen}
        onClose={() => setIsAddEditOpen(false)}
        lot={editingLot}
        onSave={handleSaveLot}
      />
    </div>
  );
}
