import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/mock_data.dart';
import '../core/services/storage_service.dart';
import '../models/civic_report_model.dart';
import '../models/logistics_model.dart';
import '../models/crop_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

/// Centralized Data Repository managing Real-Time Firestore streams and Offline Caching
class DataRepository extends ChangeNotifier {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal() {
    _initSeedData();
    _setupFirestoreListeners();
  }

  // --- Data Collections ---
  final List<CivicReport> _reports = [];
  List<CivicReport> get reports => List.unmodifiable(_reports);

  final List<LogisticsRequest> _logistics = [];
  List<LogisticsRequest> get logistics => List.unmodifiable(_logistics);

  final List<CropListing> _cropListings = [];
  List<CropListing> get cropListings => List.unmodifiable(_cropListings);

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotifsCount => _notifications.where((n) => !n.isRead).length;

  final List<AppUser> _allUsers = [];
  List<AppUser> get allUsers => List.unmodifiable(_allUsers);

  List<CropItem> crops = [];

  // --- Subscriptions ---
  StreamSubscription? _reportsSub;
  StreamSubscription? _logisticsSub;
  StreamSubscription? _listingsSub;
  StreamSubscription? _notifsSub;
  StreamSubscription? _usersSub;

  void _initSeedData() {
    // 1. Pre-seed Civic Reports
    _reports.addAll([
      CivicReport(
        id: 'rep_1',
        userId: 'demo_citizen_1',
        userName: 'Karthik S',
        userPhone: '9876543210',
        title: 'Deep Pothole & Water Logging',
        desc: 'Severe 2-foot pothole causing heavy traffic jams and motorbike skidding near Sathy Bus Stand.',
        category: 'Roads',
        loc: const LatLng(11.5034, 77.2387),
        address: 'Market Road, Near Old Bus Stand, Sathyamangalam',
        status: 'Assigned',
        department: 'Roads & Bridges',
        wardId: 'w1',
        wardName: 'Ward 1 - Market Road Area',
        upvotes: 18,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CivicReport(
        id: 'rep_2',
        userId: 'demo_citizen_1',
        userName: 'Karthik S',
        userPhone: '9876543210',
        title: 'Broken Drinking Water Pipeline',
        desc: 'Fresh water gushing onto the road continuously for 24 hours. Wastage of municipal water supply.',
        category: 'Water',
        loc: const LatLng(11.5090, 77.2410),
        address: 'Bus Stand Colony Main Street, Sathyamangalam',
        status: 'In Progress',
        department: 'Water Supply & Drainage',
        wardId: 'w2',
        wardName: 'Ward 2 - Bus Stand Colony',
        upvotes: 24,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CivicReport(
        id: 'rep_3',
        userId: 'usr_33',
        userName: 'Meenakshi Sundaram',
        userPhone: '9842109876',
        title: 'Overflowing Garbage Bin & Stray Cattle',
        desc: 'Waste hasn’t been cleared for 4 days. Strong foul odor attracting stray animals.',
        category: 'Sanitation',
        loc: const LatLng(11.4970, 77.2320),
        address: 'Bannari Road Junction, Sathyamangalam',
        status: 'Pending',
        wardId: 'w3',
        wardName: 'Ward 3 - Bannari Road Junction',
        upvotes: 9,
        createdAt: DateTime.now().subtract(const Duration(days: 8)), // SLA Breached
      ),
      CivicReport(
        id: 'rep_4',
        userId: 'usr_44',
        userName: 'Senthil Kumar',
        userPhone: '9842105555',
        title: 'Flickering High-Mast Street Light',
        desc: 'Main junction high-mast light repaired and working smoothly now.',
        category: 'Electricity',
        loc: const LatLng(11.5060, 77.2350),
        address: 'Town Hall Circle, Sathyamangalam',
        status: 'Resolved',
        department: 'TANGEDCO / Street Lights',
        wardId: 'w5',
        wardName: 'Ward 5 - Town Hall & North Colony',
        upvotes: 31,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // 2. Pre-seed Logistics Requests
    _logistics.addAll([
      LogisticsRequest(
        id: 'log_1',
        farmerId: 'demo_farmer_1',
        farmerName: 'Murugan K',
        farmerPhone: '9876543211',
        crop: 'Tomato',
        weightKg: 650,
        pickupAddress: 'Farm No 4, Bannari Village, Sathyamangalam',
        pickupLoc: const LatLng(11.5034, 77.2387),
        warehouseId: 'wh1',
        warehouseName: 'Sathyamangalam Cold Storage',
        status: 'Scheduled',
        scheduledTime: 'Tomorrow, 08:30 AM',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      LogisticsRequest(
        id: 'log_2',
        farmerId: 'f2',
        farmerName: 'Selvi R',
        farmerPhone: '9842112233',
        crop: 'Onion',
        weightKg: 400,
        pickupAddress: 'Bhavani Road, Gobichettipalayam',
        pickupLoc: const LatLng(11.4520, 77.4350),
        warehouseId: 'wh3',
        warehouseName: 'Gobi Farmers Aggregation Center',
        status: 'Requested',
        createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      ),
    ]);

    // 3. Pre-seed Crop Listings
    _cropListings.addAll([
      CropListing(
        id: 'cl1',
        farmerId: 'demo_farmer_1',
        farmerName: 'Murugan K',
        farmerPhone: '9876543211',
        crop: 'Tomato',
        pricePerKg: 36.0,
        quantityKg: 500,
        location: 'Sathyamangalam',
      ),
      CropListing(
        id: 'cl2',
        farmerId: 'f2',
        farmerName: 'Selvi R',
        farmerPhone: '9842112233',
        crop: 'Onion',
        pricePerKg: 26.0,
        quantityKg: 350,
        location: 'Gobichettipalayam',
      ),
      CropListing(
        id: 'cl3',
        farmerId: 'f3',
        farmerName: 'Balu S',
        farmerPhone: '9842144556',
        crop: 'Banana',
        pricePerKg: 21.0,
        quantityKg: 800,
        location: 'Erode',
      ),
    ]);

    // 4. Pre-seed Notifications
    _notifications.addAll([
      AppNotification(
        id: 'notif_1',
        targetUid: 'all',
        title: '🌱 Mandi Rate Alert',
        body: 'Tomato prices increased by +₹4/kg at Sathy APMC Mandi today.',
        type: 'price_alert',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'notif_2',
        targetUid: 'all',
        title: '🚧 Ward 1 Road Work Notice',
        body: 'Market Road resurfacing will commence on Friday. Plan routes accordingly.',
        type: 'new_report',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ]);

    // 5. Pre-seed Crop Price Items
    loadDistrictCropData(AppConstants.defaultDistrict);
  }

  void loadDistrictCropData(String district) {
    final rawList = MockData.agmarknetData[district] ?? MockData.agmarknetData['Default']!;
    final rng = Random();
    crops = rawList.map((item) {
      final double price = (item['price'] as num).toDouble();
      final double predicted = (item['predicted'] as num).toDouble();
      final List<double> history = List<double>.from(
        (item['history'] as List).map((v) => (v as num).toDouble()),
      );
      return CropItem(
        item['name'] as String,
        price,
        predicted,
        item['demand'] as String,
        history: history,
      );
    }).toList();
    notifyListeners();
  }

  // --- Real-time Firestore Listeners with Fallback Handling ---
  void _setupFirestoreListeners() {
    if (Firebase.apps.isEmpty) return;

    try {
      // 1. Reports Listener
      _reportsSub = FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snap) {
          if (snap.docs.isNotEmpty) {
            _reports.clear();
            for (final doc in snap.docs) {
              try {
                _reports.add(CivicReport.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing report document ${doc.id}: $e');
              }
            }
            notifyListeners();
          }
        },
        onError: (e) => debugPrint('Firestore reports stream error: $e'),
      );

      // 2. Logistics Listener
      _logisticsSub = FirebaseFirestore.instance
          .collection('logistics_requests')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snap) {
          if (snap.docs.isNotEmpty) {
            _logistics.clear();
            for (final doc in snap.docs) {
              try {
                _logistics.add(LogisticsRequest.fromMap(doc.data(), docId: doc.id));
              } catch (e) {
                debugPrint('Error parsing logistics document ${doc.id}: $e');
              }
            }
            notifyListeners();
          }
        },
        onError: (e) => debugPrint('Firestore logistics stream error: $e'),
      );
    } catch (e) {
      debugPrint('Firestore initialization listener setup failed: $e');
    }
  }

  // --- Report Actions ---
  Future<bool> saveReport({
    required String title,
    required String desc,
    required String category,
    required LatLng loc,
    String? address,
    XFile? image,
    required AppUser user,
  }) async {
    final reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}';
    final wardId = _findNearestWard(loc);
    final wardName = _getWardName(wardId);

    String? uploadedImageUrl;
    if (image != null) {
      uploadedImageUrl = await StorageService().uploadImage(reportId, image);
    }

    final newReport = CivicReport(
      id: reportId,
      userId: user.uid,
      userName: user.name,
      userPhone: user.phone,
      title: title,
      desc: desc,
      category: category,
      loc: loc,
      address: address,
      imagePath: uploadedImageUrl ?? image?.path,
      status: 'Pending',
      wardId: wardId,
      wardName: wardName,
      createdAt: DateTime.now(),
    );

    _reports.insert(0, newReport);
    notifyListeners();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .set(newReport.toMap());
      } catch (e) {
        debugPrint('Firestore report save error: $e');
      }
    }

    return true;
  }

  Future<void> upvoteReport(String reportId, String userId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      if (report.upvotedUsers.contains(userId)) {
        report.upvotedUsers.remove(userId);
        report.upvotes = max(0, report.upvotes - 1);
      } else {
        report.upvotedUsers.add(userId);
        report.upvotes += 1;
      }
      notifyListeners();

      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update({
            'upvotes': report.upvotes,
            'upvotedUsers': report.upvotedUsers.toList(),
          });
        } catch (_) {}
      }
    }
  }

  Future<void> acceptAndAssignReport({
    required String reportId,
    required String department,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index].status = 'Assigned';
      _reports[index].department = department;
      _reports[index].assignedAt = DateTime.now();
      notifyListeners();

      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update({
            'status': 'Assigned',
            'department': department,
            'assignedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Assign report error: $e');
        }
      }
    }
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String newStatus,
  }) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index].status = newStatus;
      if (newStatus == 'Resolved') {
        _reports[index].resolvedAt = DateTime.now();
      }
      notifyListeners();

      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(reportId)
              .update({
            'status': newStatus,
            if (newStatus == 'Resolved') 'resolvedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Update status error: $e');
        }
      }
    }
  }

  // --- Logistics Actions ---
  Future<bool> submitLogisticsRequest(LogisticsRequest req) async {
    _logistics.insert(0, req);
    notifyListeners();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('logistics_requests')
            .doc(req.id)
            .set(req.toMap());
      } catch (e) {
        debugPrint('Logistics submit error: $e');
      }
    }
    return true;
  }

  Future<void> updateLogisticsStatus({
    required String reqId,
    required String status,
    String? scheduledTime,
  }) async {
    final index = _logistics.indexWhere((l) => l.id == reqId);
    if (index != -1) {
      _logistics[index].status = status;
      if (scheduledTime != null) _logistics[index].scheduledTime = scheduledTime;
      notifyListeners();

      if (Firebase.apps.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('logistics_requests')
          .doc(reqId)
          .update({
            'status': status,
            if (scheduledTime != null) 'scheduledTime': scheduledTime,
          });
        } catch (_) {}
      }
    }
  }

  // --- Crop Listings ---
  Future<void> addCropListing(CropListing listing) async {
    _cropListings.insert(0, listing);
    notifyListeners();

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('crop_listings')
            .doc(listing.id)
            .set(listing.toMap());
      } catch (_) {}
    }
  }

  // --- Notifications ---
  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  String _findNearestWard(LatLng loc) {
    String closest = 'w1';
    double minDistance = double.infinity;
    for (final ward in MockData.wardData) {
      final lat = ward['center_lat'] as double;
      final lng = ward['center_lng'] as double;
      final dist = const Distance().as(LengthUnit.Kilometer, loc, LatLng(lat, lng));
      if (dist < minDistance) {
        minDistance = dist;
        closest = ward['id'] as String;
      }
    }
    return closest;
  }

  String _getWardName(String wardId) {
    final match = MockData.wardData.firstWhere(
      (w) => w['id'] == wardId,
      orElse: () => MockData.wardData.first,
    );
    return '${match['ward']} - ${match['name']}';
  }

  @override
  void dispose() {
    _reportsSub?.cancel();
    _logisticsSub?.cancel();
    _listingsSub?.cancel();
    _notifsSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }
}

final dataRepository = DataRepository();
