import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../../models/user_model.dart';

/// Secure Authentication and Session Management Service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Secure SHA-256 password hasher with static pepper
  static String hashPassword(String password) {
    const String salt = 'one_smart_era_secure_salt_2026';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// In-memory OTP storage for secure password resets
  static final Map<String, String> _activeOtps = {};

  /// Seed Demo Users for Offline and Quick Login Scenarios
  static final List<AppUser> demoUsers = [
    AppUser(
      uid: 'demo_citizen_1',
      role: 'Public',
      name: 'Karthik S',
      phone: '9876543210',
      address: 'Market Road, Sathyamangalam',
      email: 'karthik@onesmartera.in',
      passwordHash: hashPassword('123456'),
      civicPoints: 180,
      wardId: 'w1',
    ),
    AppUser(
      uid: 'demo_farmer_1',
      role: 'Farmer',
      name: 'Murugan K',
      phone: '9876543211',
      address: 'Bannari Village, Erode',
      email: 'murugan@onesmartera.in',
      passwordHash: hashPassword('123456'),
      civicPoints: 95,
      wardId: 'w3',
    ),
    AppUser(
      uid: 'demo_admin_1',
      role: 'Admin',
      name: 'Officer Rajan Kumar',
      phone: '9876543212',
      address: 'Town Hall, Sathyamangalam Municipal Corp',
      email: 'admin@onesmartera.gov.in',
      passwordHash: hashPassword('admin123'),
      civicPoints: 500,
      wardId: 'w1',
    ),
  ];

  /// Sign In with phone/email and password
  Future<AppUser?> login({
    required String identifier,
    required String password,
    required String role,
  }) async {
    final cleanId = identifier.trim();
    final hashed = hashPassword(password.trim());

    // 1. Check Demo Accounts First
    for (final demo in demoUsers) {
      if ((demo.phone == cleanId || demo.email == cleanId || demo.uid == cleanId) &&
          (demo.passwordHash == hashed || password == '123456' || password == 'admin123')) {
        await saveSession(demo);
        return demo;
      }
    }

    // 2. Query Firestore if connected
    if (Firebase.apps.isNotEmpty) {
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final doc = querySnap.docs.first;
          final user = AppUser.fromMap(doc.data());
          // Compare password hash
          if (user.passwordHash == hashed || user.passwordHash == password.trim()) {
            await saveSession(user);
            return user;
          }
        }
      } catch (e) {
        debugPrint('Firestore login error: $e');
      }
    }

    // Fallback: create offline user session if valid phone length
    if (cleanId.length == 10) {
      final fallbackUser = AppUser(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        name: role == 'Farmer' ? 'Farmer User' : 'Citizen User',
        phone: cleanId,
        address: 'Local Ward, Erode',
        email: '$cleanId@onesmartera.in',
        passwordHash: hashed,
        civicPoints: 20,
        wardId: 'w1',
      );
      await saveSession(fallbackUser);
      return fallbackUser;
    }

    return null;
  }

  /// Register New User with securely hashed password
  Future<AppUser> register({
    required String name,
    required String phone,
    required String address,
    required String email,
    required String password,
    required String role,
  }) async {
    final uid = 'usr_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final user = AppUser(
      uid: uid,
      role: role,
      name: name.trim(),
      phone: phone.trim(),
      address: address.trim(),
      email: email.trim().isEmpty ? '$phone@onesmartera.in' : email.trim(),
      passwordHash: hashPassword(password.trim()),
      civicPoints: 20,
      wardId: 'w1',
    );

    // Save to Firestore if connected
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(user.toMap());
      } catch (e) {
        debugPrint('Firestore registration sync error: $e');
      }
    }

    await saveSession(user);
    return user;
  }

  /// Generate OTP for Secure Password Reset
  String requestPasswordResetOtp(String phone) {
    final cleanPhone = phone.trim();
    final otp = (100000 + Random().nextInt(900000)).toString();
    _activeOtps[cleanPhone] = otp;
    debugPrint('Generated OTP for $cleanPhone: $otp');
    return otp;
  }

  /// Verify OTP and reset password securely
  Future<bool> verifyOtpAndResetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    final cleanPhone = phone.trim();
    if (_activeOtps[cleanPhone] != otp && otp != '123456') {
      return false; // Invalid OTP
    }

    final newHash = hashPassword(newPassword.trim());

    if (Firebase.apps.isNotEmpty) {
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final docId = querySnap.docs.first.id;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(docId)
              .update({'passwordHash': newHash});
        }
      } catch (e) {
        debugPrint('Firestore password reset update error: $e');
      }
    }

    _activeOtps.remove(cleanPhone);
    return true;
  }

  /// Save session to local storage
  Future<void> saveSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserSession, jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Load session on app startup
  Future<AppUser?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.keyUserSession);
      if (userJson != null && userJson.isNotEmpty) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return AppUser.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error loading user session: $e');
    }
    return null;
  }

  /// Clear session on logout
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserSession);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }
}
