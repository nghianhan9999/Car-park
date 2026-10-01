import 'package:flutter/material.dart';

enum ParkingStatus {
  available,
  nearlyFull,
  full,
  closed;

  static ParkingStatus fromString(String? status) {
    switch (status) {
      case 'available':
        return ParkingStatus.available;
      case 'nearly_full':
        return ParkingStatus.nearlyFull;
      case 'full':
        return ParkingStatus.full;
      case 'closed':
        return ParkingStatus.closed;
      default:
        return ParkingStatus.available;
    }
  }

  String toDbString() {
    switch (this) {
      case ParkingStatus.available:
        return 'available';
      case ParkingStatus.nearlyFull:
        return 'nearly_full';
      case ParkingStatus.full:
        return 'full';
      case ParkingStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case ParkingStatus.available:
        return 'Còn chỗ';
      case ParkingStatus.nearlyFull:
        return 'Sắp đầy';
      case ParkingStatus.full:
        return 'Hết chỗ';
      case ParkingStatus.closed:
        return 'Đang đóng cửa';
    }
  }

  Color get color {
    switch (this) {
      case ParkingStatus.available:
        return const Color(0xFF16A34A); // Green
      case ParkingStatus.nearlyFull:
        return const Color(0xFFEA580C); // Orange
      case ParkingStatus.full:
        return const Color(0xFFDC2626); // Red
      case ParkingStatus.closed:
        return const Color(0xFF64748B); // Slate
    }
  }

  Color get bgColor {
    switch (this) {
      case ParkingStatus.available:
        return const Color(0xFFDCFCE7);
      case ParkingStatus.nearlyFull:
        return const Color(0xFFFFEDD5);
      case ParkingStatus.full:
        return const Color(0xFFFEE2E2);
      case ParkingStatus.closed:
        return const Color(0xFFF1F5F9);
    }
  }
}

class ParkingLot {
  final String id;
  final String name;
  final String address;
  final String district;
  final String city;
  final double latitude;
  final double longitude;
  final int pricePerHour;
  final int pricePerTurn;
  final int priceOvernight;
  final int totalCapacity;
  final ParkingStatus currentStatus;
  final DateTime? statusUpdatedAt;
  final String openTime;
  final String closeTime;
  final bool is24h;
  final bool hasRoof;
  final bool hasEvCharging;
  final bool hasSecurity;
  final bool hasCamera;
  final String? phoneNumber;
  final String? imageUrl;
  final double? distanceMeters;

  ParkingLot({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.pricePerTurn,
    required this.priceOvernight,
    required this.totalCapacity,
    required this.currentStatus,
    this.statusUpdatedAt,
    required this.openTime,
    required this.closeTime,
    required this.is24h,
    required this.hasRoof,
    required this.hasEvCharging,
    required this.hasSecurity,
    required this.hasCamera,
    this.phoneNumber,
    this.imageUrl,
    this.distanceMeters,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    return ParkingLot(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Bãi đỗ xe',
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? 'Ninh Kiều',
      city: json['city'] as String? ?? 'Cần Thơ',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      pricePerHour: json['price_per_hour'] as int? ?? 10000,
      pricePerTurn: json['price_per_turn'] as int? ?? 20000,
      priceOvernight: json['price_overnight'] as int? ?? 50000,
      totalCapacity: json['total_capacity'] as int? ?? 30,
      currentStatus: ParkingStatus.fromString(json['current_status'] as String?),
      statusUpdatedAt: json['status_updated_at'] != null
          ? DateTime.tryParse(json['status_updated_at'] as String)
          : null,
      openTime: json['open_time'] as String? ?? '06:00',
      closeTime: json['close_time'] as String? ?? '22:00',
      is24h: json['is_24h'] as bool? ?? false,
      hasRoof: json['has_roof'] as bool? ?? false,
      hasEvCharging: json['has_ev_charging'] as bool? ?? false,
      hasSecurity: json['has_security'] as bool? ?? true,
      hasCamera: json['has_camera'] as bool? ?? true,
      phoneNumber: json['phone_number'] as String?,
      imageUrl: json['image_url'] as String?,
      distanceMeters: json['distance_meters'] != null
          ? (json['distance_meters'] as num).toDouble()
          : null,
    );
  }

  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()}m';
    } else {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
    }
  }
}
