import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Model representing Farm-to-Mandi / Cold Storage Logistics Requests
class LogisticsRequest {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String crop;
  final double weightKg;
  final String pickupAddress;
  final LatLng pickupLoc;
  final String? warehouseId;
  final String? warehouseName;
  String status; // 'Requested', 'Confirmed', 'Scheduled', 'Picked Up', 'Delivered'
  String? scheduledTime;
  String? groupId;
  final DateTime createdAt;

  LogisticsRequest({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone = '',
    required this.crop,
    required this.weightKg,
    required this.pickupAddress,
    required this.pickupLoc,
    this.warehouseId,
    this.warehouseName,
    this.status = 'Requested',
    this.scheduledTime,
    this.groupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'farmerId': farmerId,
    'farmerName': farmerName,
    'farmerPhone': farmerPhone,
    'crop': crop,
    'weightKg': weightKg,
    'pickupAddress': pickupAddress,
    'pickupLat': pickupLoc.latitude,
    'pickupLng': pickupLoc.longitude,
    'warehouseId': warehouseId,
    'warehouseName': warehouseName,
    'status': status,
    'scheduledTime': scheduledTime,
    'groupId': groupId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory LogisticsRequest.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedCreated = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      parsedCreated = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreated = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    }

    double lat = 11.5034;
    double lng = 77.2387;
    if (map['pickupLat'] != null) lat = (map['pickupLat'] as num).toDouble();
    if (map['pickupLng'] != null) lng = (map['pickupLng'] as num).toDouble();

    return LogisticsRequest(
      id: docId ?? (map['id'] as String? ?? ''),
      farmerId: map['farmerId'] as String? ?? '',
      farmerName: map['farmerName'] as String? ?? 'Farmer',
      farmerPhone: map['farmerPhone'] as String? ?? '',
      crop: map['crop'] as String? ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      pickupAddress: map['pickupAddress'] as String? ?? '',
      pickupLoc: LatLng(lat, lng),
      warehouseId: map['warehouseId'] as String?,
      warehouseName: map['warehouseName'] as String?,
      status: map['status'] as String? ?? 'Requested',
      scheduledTime: map['scheduledTime'] as String?,
      groupId: map['groupId'] as String?,
      createdAt: parsedCreated,
    );
  }
}
