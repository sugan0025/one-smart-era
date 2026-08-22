import 'dart:convert';
import 'dart:io' as io;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading photos to Firebase Storage with offline/base64 fallback
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Uploads image to Firebase Storage and returns URL; returns base64 data URI on error or offline
  Future<String?> uploadImage(String filename, XFile image) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final ref = FirebaseStorage.instance.ref('reports/$filename.jpg');
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          await ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          await ref.putFile(
            io.File(image.path),
            SettableMetadata(contentType: 'image/jpeg'),
          );
        }
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      }
    } catch (e) {
      debugPrint('Firebase Storage upload failed: $e. Falling back to local data URI.');
    }

    // Offline / Local Fallback: Convert to Base64 data URI
    try {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Base64 image conversion error: $e');
      return image.path;
    }
  }
}
