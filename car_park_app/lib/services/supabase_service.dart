import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parking_lot.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://jyjdrmwmjoboawuxtkhc.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_-B42s-_Vpzsa2b7MJ5iyCg_DUkHAH_w';

  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Auth getters
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Sign In with Email & Password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Up with Email & Password
  Future<AuthResponse> signUpWithEmail(String email, String password, {String? fullName}) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName ?? email.split('@')[0], 'role': 'driver'},
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Get Nearby Parking Lots via PostGIS RPC function
  Future<List<ParkingLot>> getNearbyParkingLots({
    required double lat,
    required double lng,
    double radiusMeters = 10000,
  }) async {
    try {
      final response = await client.rpc(
        'get_nearby_parking_lots',
        params: {
          'user_lat': lat,
          'user_lng': lng,
          'radius_meters': radiusMeters,
        },
      ) as List<dynamic>;

      return response
          .map((item) => ParkingLot.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting nearby parking lots: $e');
      // Fallback to table query if RPC fails
      final res = await client
          .from('parking_lots')
          .select()
          .eq('is_approved', true);
      return (res as List<dynamic>)
          .map((item) => ParkingLot.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  // Update status (chủ bãi hoặc admin)
  Future<void> updateLotStatus(String lotId, ParkingStatus status) async {
    await client.from('parking_lots').update({
      'current_status': status.toDbString(),
      'status_updated_at': DateTime.now().toIso8601String(),
      'status_updated_by': currentUser?.id,
    }).eq('id', lotId);
  }

  // Submit Driver Report
  Future<void> submitReport({
    required String lotId,
    required String reportType,
    int? reportedPrice,
    String? notes,
  }) async {
    await client.from('reports').insert({
      'lot_id': lotId,
      'user_id': currentUser?.id,
      'report_type': reportType,
      'reported_price': reportedPrice,
      'notes': notes,
    });
  }

  // Driver propose new parking lot
  Future<void> proposeNewLot({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required int pricePerHour,
    required int pricePerTurn,
    required int totalCapacity,
    bool hasRoof = false,
    bool hasEvCharging = false,
    String? phoneNumber,
    String? imageUrl,
  }) async {
    await client.from('parking_lots').insert({
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'price_per_turn': pricePerTurn,
      'total_capacity': totalCapacity,
      'has_roof': hasRoof,
      'has_ev_charging': hasEvCharging,
      'phone_number': phoneNumber,
      'image_url': imageUrl,
      'is_approved': false, // Chờ admin duyệt
    });
  }

  // Save current parked location
  Future<void> saveParkedLocation({
    required double latitude,
    required double longitude,
    String? lotName,
    String? note,
  }) async {
    // Clear previous active locations first
    if (currentUser != null) {
      await client
          .from('saved_parked_locations')
          .update({'is_active': false})
          .eq('user_id', currentUser!.id);

      await client.from('saved_parked_locations').insert({
        'user_id': currentUser!.id,
        'latitude': latitude,
        'longitude': longitude,
        'lot_name': lotName,
        'note': note,
        'is_active': true,
      });
    }
  }

  // Get active parked location
  Future<Map<String, dynamic>?> getActiveParkedLocation() async {
    if (currentUser == null) return null;
    final res = await client
        .from('saved_parked_locations')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('is_active', true)
        .order('parked_at', {ascending: false})
        .limit(1);

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  // Clear parked location
  Future<void> clearParkedLocation() async {
    if (currentUser != null) {
      await client
          .from('saved_parked_locations')
          .update({'is_active': false})
          .eq('user_id', currentUser!.id);
    }
  }
}
