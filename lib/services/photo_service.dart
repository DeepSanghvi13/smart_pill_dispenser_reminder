import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_photo.dart';
import 'hive_service.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();

  factory PhotoService() {
    return _instance;
  }

  PhotoService._internal();

  final _uuid = const Uuid();

  String _settingsKey(String userId) => 'user_photos_json_${userId.trim().toLowerCase()}';

  /// Dynamically locate an image file on disk even if app container path changed on mobile platform
  Future<File?> getValidImageFile(UserPhoto photo) async {
    final primary = File(photo.imagePath);
    if (await primary.exists()) return primary;

    try {
      final filename = photo.imagePath.split('/').last.split('\\').last;
      Directory appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        appDir = await getApplicationSupportDirectory();
      }

      final userPhotosDir = Directory('${appDir.path}/user_photos');
      if (await userPhotosDir.exists()) {
        final entities = userPhotosDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && (entity.path.endsWith(filename) || entity.path.endsWith('${photo.photoId}.jpg'))) {
            return entity;
          }
        }
      }
    } catch (_) {}

    return primary;
  }

  /// Save a newly captured or selected image file to local app storage
  /// and store its metadata in both Hive user_photos box and settingsBox JSON backup.
  Future<UserPhoto?> savePhoto({
    required File sourceFile,
    required String userId,
    required String userRole,
    String? caption,
  }) async {
    try {
      final normalizedUserId = userId.trim().isEmpty ? 'guest' : userId.trim().toLowerCase();

      // Generate unique photo ID
      final photoId = 'PHOTO_${_uuid.v4()}';

      // Get app storage directory: /user_photos/<userId>/
      Directory appDir;
      try {
        appDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        appDir = await getApplicationSupportDirectory();
      }

      final userPhotosDir = Directory('${appDir.path}/user_photos/$normalizedUserId');
      if (!await userPhotosDir.exists()) {
        await userPhotosDir.create(recursive: true);
      }

      // Write bytes directly to target path (bulletproof across all platform filesystems)
      final targetPath = '${userPhotosDir.path}/$photoId.jpg';
      final savedFile = File(targetPath);

      try {
        final bytes = await sourceFile.readAsBytes();
        await savedFile.writeAsBytes(bytes, flush: true);
      } catch (e) {
        debugPrint("writeAsBytes warning, attempting copy fallback: $e");
        await sourceFile.copy(targetPath);
      }

      // Create model instance
      final now = DateTime.now();
      final userPhoto = UserPhoto(
        photoId: photoId,
        userId: normalizedUserId,
        userRole: userRole,
        imagePath: savedFile.path,
        caption: caption?.trim(),
        createdAt: now,
        updatedAt: now,
      );

      // 1. Save to Hive typed box
      try {
        final box = HiveService().userPhotosBox;
        await box.put(photoId, userPhoto);
      } catch (e) {
        debugPrint("Hive box put warning: $e");
      }

      // 2. Save to settingsBox JSON backup (failsafe)
      try {
        final settingsBox = HiveService().settingsBox;
        final jsonKey = _settingsKey(normalizedUserId);
        final raw = settingsBox.get(jsonKey);
        List<dynamic> list = [];
        if (raw != null) {
          try {
            list = jsonDecode(raw as String) as List<dynamic>;
          } catch (_) {}
        }
        list.add(userPhoto.toMap());
        await settingsBox.put(jsonKey, jsonEncode(list));
      } catch (e) {
        debugPrint("SettingsBox json backup warning: $e");
      }

      return userPhoto;
    } catch (e) {
      debugPrint("Error saving photo: $e");
      return null;
    }
  }

  /// Get all photos belonging to the specified user ID (or all saved photos on device if filtering yields none)
  List<UserPhoto> getUserPhotos([String? userId]) {
    final normalizedUserId = userId?.trim().toLowerCase() ?? '';

    final Map<String, UserPhoto> photoMap = {};

    // 1. Read from Hive typed box safely
    try {
      final box = HiveService().userPhotosBox;
      for (final key in box.keys) {
        final dynamic raw = box.get(key);
        if (raw is UserPhoto) {
          photoMap[raw.photoId] = raw;
        } else if (raw is Map) {
          try {
            final photo = UserPhoto.fromMap(Map<String, dynamic>.from(raw));
            photoMap[photo.photoId] = photo;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("Error reading userPhotosBox: $e");
    }

    // 2. Read from settingsBox JSON backup across all user_photos_json_ keys
    try {
      final settingsBox = HiveService().settingsBox;
      for (final key in settingsBox.keys) {
        if (key is String && key.startsWith('user_photos_json_')) {
          final raw = settingsBox.get(key);
          if (raw != null) {
            try {
              final List<dynamic> list = jsonDecode(raw as String);
              for (final item in list) {
                try {
                  final photo = UserPhoto.fromMap(Map<String, dynamic>.from(item));
                  if (!photoMap.containsKey(photo.photoId)) {
                    photoMap[photo.photoId] = photo;
                  }
                } catch (_) {}
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint("Error reading settingsBox photo json: $e");
    }

    List<UserPhoto> allPhotos = photoMap.values.toList();

    // If normalizedUserId is specific (and not 'guest'), filter for user
    if (normalizedUserId.isNotEmpty && normalizedUserId != 'guest') {
      final userFiltered = allPhotos
          .where((p) => p.userId.trim().toLowerCase() == normalizedUserId)
          .toList();
      if (userFiltered.isNotEmpty) {
        userFiltered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return userFiltered;
      }
    }

    allPhotos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPhotos;
  }

  /// Update photo caption in Hive & settingsBox
  Future<bool> updateCaption({
    required String photoId,
    required String userId,
    required String newCaption,
  }) async {
    try {
      final normalizedUserId = userId.trim().toLowerCase();
      UserPhoto? existingPhoto;

      // Check Hive box
      try {
        final box = HiveService().userPhotosBox;
        final dynamic raw = box.get(photoId);
        if (raw is UserPhoto) existingPhoto = raw;
      } catch (_) {}

      // Fallback check settingsBox / getUserPhotos
      if (existingPhoto == null) {
        final all = getUserPhotos(normalizedUserId);
        for (final p in all) {
          if (p.photoId == photoId) {
            existingPhoto = p;
            break;
          }
        }
      }

      if (existingPhoto == null) return false;

      final updatedPhoto = existingPhoto.copyWith(
        caption: newCaption.trim(),
        updatedAt: DateTime.now(),
      );

      // Update Hive box
      try {
        final box = HiveService().userPhotosBox;
        await box.put(photoId, updatedPhoto);
      } catch (_) {}

      // Update settingsBox JSON backup
      try {
        final settingsBox = HiveService().settingsBox;
        final jsonKey = _settingsKey(normalizedUserId);
        final photos = getUserPhotos(normalizedUserId);
        final index = photos.indexWhere((p) => p.photoId == photoId);
        if (index >= 0) {
          photos[index] = updatedPhoto;
          await settingsBox.put(jsonKey, jsonEncode(photos.map((p) => p.toMap()).toList()));
        }
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint("Error updating caption: $e");
      return false;
    }
  }

  /// Delete photo metadata from Hive AND actual image file from local storage
  Future<bool> deletePhoto({
    required UserPhoto photo,
    required String userId,
  }) async {
    try {
      // Delete from Hive box
      try {
        final box = HiveService().userPhotosBox;
        await box.delete(photo.photoId);
      } catch (_) {}

      // Delete from settingsBox JSON backup
      try {
        final settingsBox = HiveService().settingsBox;
        for (final key in settingsBox.keys) {
          if (key is String && key.startsWith('user_photos_json_')) {
            final raw = settingsBox.get(key);
            if (raw != null) {
              try {
                final List<dynamic> list = jsonDecode(raw as String);
                final updated = list.where((item) => item['photoId'] != photo.photoId).toList();
                await settingsBox.put(key, jsonEncode(updated));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // Delete actual file from local storage
      try {
        final file = await getValidImageFile(photo);
        if (file != null && await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint("Error deleting photo: $e");
      return false;
    }
  }

  /// Get all photos (For Admin inspection if required)
  List<UserPhoto> getAllPhotosForAdmin() {
    return getUserPhotos();
  }
}
