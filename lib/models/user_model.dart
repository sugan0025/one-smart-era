/// App User Model representing Citizens, Farmers, and City Officials
class AppUser {
  final String uid;
  final String role; // 'Public', 'Farmer', 'Admin'
  String name;
  String phone;
  String address;
  String email;
  String passwordHash;
  int civicPoints;
  String? wardId;
  bool isVerified;
  DateTime createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    this.passwordHash = '',
    this.civicPoints = 0,
    this.wardId,
    this.isVerified = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCitizen => role == 'Public';
  bool get isFarmer => role == 'Farmer';
  bool get isAdmin => role == 'Admin';

  String get championBadge {
    if (civicPoints >= 300) return 'Platinum Champion';
    if (civicPoints >= 150) return 'Gold Citizen';
    if (civicPoints >= 50) return 'Silver Citizen';
    return 'Active Citizen';
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': role,
    'name': name,
    'phone': phone,
    'address': address,
    'email': email,
    'passwordHash': passwordHash,
    'civicPoints': civicPoints,
    'wardId': wardId,
    'isVerified': isVerified,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      if (map['createdAt'] is String) {
        parsedDate = DateTime.parse(map['createdAt']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppUser(
      uid: map['uid'] as String? ?? '',
      role: map['role'] as String? ?? 'Public',
      name: map['name'] as String? ?? 'Citizen',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? (map['password'] as String? ?? ''),
      civicPoints: (map['civicPoints'] as num?)?.toInt() ?? 0,
      wardId: map['wardId'] as String?,
      isVerified: map['isVerified'] as bool? ?? true,
      createdAt: parsedDate,
    );
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? address,
    String? email,
    String? passwordHash,
    int? civicPoints,
    String? wardId,
    bool? isVerified,
    String? role,
  }) {
    return AppUser(
      uid: uid,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      civicPoints: civicPoints ?? this.civicPoints,
      wardId: wardId ?? this.wardId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}
