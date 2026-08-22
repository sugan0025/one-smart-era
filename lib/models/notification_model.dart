import 'package:cloud_firestore/cloud_firestore.dart';

/// In-App Notifications and Ward Announcements Model
class AppNotification {
  final String id;
  final String targetUid;
  final String title;
  final String body;
  final String type; // 'new_report', 'report_assigned', 'report_resolved', 'sos_alert', 'price_alert', 'logistics_update'
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.targetUid,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'targetUid': targetUid,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? docId}) =>
      AppNotification(
        id: docId ?? (map['id'] as String? ?? ''),
        targetUid: map['targetUid'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: map['type'] as String? ?? 'general',
        isRead: map['isRead'] as bool? ?? false,
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : (map['createdAt'] != null
                ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now()),
      );
}

class WardNotice {
  final String id;
  final String title;
  final String body;
  final String wardId;
  final DateTime createdAt;

  WardNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.wardId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'wardId': wardId,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory WardNotice.fromMap(Map<String, dynamic> m, {String? docId}) => WardNotice(
        id: docId ?? (m['id'] as String? ?? ''),
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        wardId: m['wardId'] as String? ?? '',
        createdAt: m['createdAt'] is Timestamp
            ? (m['createdAt'] as Timestamp).toDate()
            : (m['createdAt'] != null
                ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now()),
      );
}
