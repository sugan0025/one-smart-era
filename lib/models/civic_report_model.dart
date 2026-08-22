import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Model representing Citizen Grievance & Civic Issue Reports
class CivicReport {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String title;
  final String desc;
  final String category; // 'Roads', 'Water', 'Sanitation', 'Electricity', 'Health', 'Other'
  final LatLng loc;
  final String? address;
  final String? imagePath;
  String status; // 'Pending', 'Assigned', 'In Progress', 'Resolved'
  String? department;
  String? wardId;
  String? wardName;
  DateTime? assignedAt;
  DateTime? resolvedAt;
  final DateTime createdAt;
  int upvotes;
  Set<String> upvotedUsers;

  CivicReport({
    required this.id,
    required this.userId,
    this.userName = 'Citizen',
    this.userPhone = '',
    required this.title,
    required this.desc,
    required this.category,
    required this.loc,
    this.address,
    this.imagePath,
    this.status = 'Pending',
    this.department,
    this.wardId,
    this.wardName,
    this.assignedAt,
    this.resolvedAt,
    DateTime? createdAt,
    this.upvotes = 0,
    Set<String>? upvotedUsers,
  })  : createdAt = createdAt ?? DateTime.now(),
        upvotedUsers = upvotedUsers ?? {};

  bool get isSlaBreached =>
      (status == 'Pending' || status == 'Assigned') &&
      DateTime.now().difference(createdAt).inDays >= 7;

  int get daysOpen => DateTime.now().difference(createdAt).inDays;

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userPhone': userPhone,
    'title': title,
    'desc': desc,
    'category': category,
    'lat': loc.latitude,
    'lng': loc.longitude,
    'address': address,
    'imagePath': imagePath,
    'status': status,
    'department': department,
    'wardId': wardId,
    'wardName': wardName,
    'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'upvotes': upvotes,
    'upvotedUsers': upvotedUsers.toList(),
  };

  factory CivicReport.fromMap(Map<String, dynamic> data, {String? docId}) {
    DateTime parsedCreated = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedCreated = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedCreated = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    }

    DateTime? parsedAssigned;
    if (data['assignedAt'] is Timestamp) {
      parsedAssigned = (data['assignedAt'] as Timestamp).toDate();
    }

    DateTime? parsedResolved;
    if (data['resolvedAt'] is Timestamp) {
      parsedResolved = (data['resolvedAt'] as Timestamp).toDate();
    }

    double lat = 11.5034;
    double lng = 77.2387;
    if (data['lat'] != null) lat = (data['lat'] as num).toDouble();
    if (data['lng'] != null) lng = (data['lng'] as num).toDouble();

    Set<String> upvoters = {};
    if (data['upvotedUsers'] is List) {
      upvoters = Set<String>.from(data['upvotedUsers'] as List);
    }

    return CivicReport(
      id: docId ?? (data['id'] as String? ?? ''),
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Citizen',
      userPhone: data['userPhone'] as String? ?? '',
      title: data['title'] as String? ?? 'Civic Issue',
      desc: data['desc'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      loc: LatLng(lat, lng),
      address: data['address'] as String?,
      imagePath: (data['imageUrl'] ?? data['imagePath']) as String?,
      status: data['status'] as String? ?? 'Pending',
      department: data['department'] as String?,
      wardId: data['wardId'] as String?,
      wardName: data['wardName'] as String?,
      assignedAt: parsedAssigned,
      resolvedAt: parsedResolved,
      createdAt: parsedCreated,
      upvotes: (data['upvotes'] as num?)?.toInt() ?? 0,
      upvotedUsers: upvoters,
    );
  }
}
