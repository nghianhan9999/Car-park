import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/parking_lot.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../widgets/parking_card.dart';
import '../../widgets/status_badge.dart';
import '../detail/parking_detail_screen.dart';
import '../saved/saved_parking_screen.dart';
import '../propose/propose_lot_screen.dart';
import '../owner/owner_status_screen.dart';
import '../auth/login_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<ParkingLot> _allLots = [];
  List<ParkingLot> _filteredLots = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Quick filters
  bool _filterOpenNow = false;
  bool _filterRoof = false;
  bool _filterEv = false;
  bool _filterOvernight = false;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadLocationAndLots();
    _listenToRealtimeChanges();
  }

  void _listenToRealtimeChanges() {
    // Listen for realtime changes on parking_lots
    SupabaseService().client
        .channel('public:parking_lots')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'parking_lots',
          callback: (payload) {
            _refreshLots();
          },
        )
        .subscribe();
  }

  Future<void> _loadLocationAndLots() async {
    setState(() => _isLoading = true);
    final pos = await LocationService.getCurrentLocation();
    _currentPosition = pos;

    final lots = await SupabaseService().getNearbyParkingLots(
      lat: pos.latitude,
      lng: pos.longitude,
      radiusMeters: 15000,
    );

    if (mounted) {
      setState(() {
        _allLots = lots;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  Future<void> _refreshLots() async {
    if (_currentPosition == null) return;
    final lots = await SupabaseService().getNearbyParkingLots(
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      radiusMeters: 15000,
    );
    if (mounted) {
      setState(() {
        _allLots = lots;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<ParkingLot> result = List.from(_allLots);

    if (_searchQuery.isNotEmpty) {
      result = result.where((lot) {
        return lot.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            lot.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_filterRoof) {
      result = result.where((lot) => lot.hasRoof).toList();
    }
    if (_filterEv) {
      result = result.where((lot) => lot.hasEvCharging).toList();
    }
    if (_filterOvernight) {
      result = result.where((lot) => lot.is24h || lot.priceOvernight > 0).toList();
    }
    if (_filterOpenNow) {
      result = result.where((lot) => lot.currentStatus != ParkingStatus.closed).toList();
    }

    _filteredLots = result;
    _updateMarkers();
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    for (final lot in _filteredLots) {
      // Pick marker hue based on availability status
      double hue = BitmapDescriptor.hueGreen;
      if (lot.currentStatus == ParkingStatus.nearlyFull) {
        hue = BitmapDescriptor.hueOrange;
      } else if (lot.currentStatus == ParkingStatus.full) {
        hue = BitmapDescriptor.hueRed;
      } else if (lot.currentStatus == ParkingStatus.closed) {
        hue = BitmapDescriptor.hueViolet;
      }

      markers.add(
        Marker(
          markerId: MarkerId(lot.id),
          position: LatLng(lot.latitude, lot.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: lot.name,
            snippet: '${lot.currentStatus.label} • ${lot.formattedDistance}',
            onTap: () => _openLotDetail(lot),
          ),
          onTap: () {
            _showQuickLotSheet(lot);
          },
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  void _showQuickLotSheet(ParkingLot lot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lot.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(status: lot.currentStatus, isLarge: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              lot.address,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Giá giờ: ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  '${lot.pricePerHour}đ/h',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const Spacer(),
                if (lot.formattedDistance.isNotEmpty)
                  Text(
                    'Cách bạn ${lot.formattedDistance}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openLotDetail(lot);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'XEM CHI TIẾT & CHỈ ĐƯỜNG',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLotDetail(ParkingLot lot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParkingDetailScreen(
          lot: lot,
          onStatusUpdated: _refreshLots,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : const LatLng(LocationService.defaultLat, LocationService.defaultLng),
      zoom: 14.5,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Top Search & Filter Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm bãi xe ở Ninh Kiều, Cần Thơ...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => _openDrawerMenu(context),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Horizontal Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Đang mở cửa',
                          icon: Icons.access_time,
                          isSelected: _filterOpenNow,
                          onSelected: (val) {
                            setState(() => _filterOpenNow = val);
                            _applyFilters();
                          },
                        ),
                        _buildFilterChip(
                          label: 'Có mái che',
                          icon: Icons.roofing,
                          isSelected: _filterRoof,
                          onSelected: (val) {
                            setState(() => _filterRoof = val);
                            _applyFilters();
                          },
                        ),
                        _buildFilterChip(
                          label: 'Trạm sạc EV',
                          icon: Icons.electric_car,
                          isSelected: _filterEv,
                          onSelected: (val) {
                            setState(() => _filterEv = val);
                            _applyFilters();
                          },
                        ),
                        _buildFilterChip(
                          label: 'Gửi qua đêm',
                          icon: Icons.night_shelter,
                          isSelected: _filterOvernight,
                          onSelected: (val) {
                            setState(() => _filterOvernight = val);
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Action Buttons (Right Side)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                // GPS Re-center button
                FloatingActionButton.small(
                  heroTag: 'gps_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  onPressed: () async {
                    final pos = await LocationService.getCurrentLocation();
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(pos.latitude, pos.longitude),
                        15.0,
                      ),
                    );
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),

                // Remember parked location button
                FloatingActionButton.small(
                  heroTag: 'park_btn',
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  tooltip: 'Ghi nhớ chỗ đã đỗ xe',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SavedParkingScreen()),
                    );
                  },
                  child: const Icon(Icons.pin_drop),
                ),
              ],
            ),
          ),

          // Bottom Draggable Sheet: List of Lots sorted by distance
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(
                            'Bãi xe quanh đây (${_filteredLots.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Sắp xếp theo khoảng cách',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Lots list
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_filteredLots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'Không tìm thấy bãi xe nào phù hợp.',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    else
                      ..._filteredLots.map(
                        (lot) => ParkingCard(
                          lot: lot,
                          onTap: () {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(lot.latitude, lot.longitude),
                                16.0,
                              ),
                            );
                            _openLotDetail(lot);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: const Color(0xFF2563EB),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey.shade800,
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _openDrawerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pin_drop, color: Color(0xFF2563EB)),
                title: const Text('Ghi nhớ vị trí đã đỗ xe'),
                subtitle: const Text('Lưu tọa độ xe của bạn để không bị lạc'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SavedParkingScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_location_alt, color: Color(0xFF16A34A)),
                title: const Text('Đề xuất bãi đỗ xe mới'),
                subtitle: const Text('Đóng góp bãi xe mới cho cộng đồng tài xế'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProposeLotScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.storefront, color: Color(0xFFEA580C)),
                title: const Text('Chế độ Chủ bãi xe'),
                subtitle: const Text('Đổi nhanh trạng thái còn chỗ / hết chỗ'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OwnerStatusScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất'),
                onTap: () async {
                  await SupabaseService().signOut();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
