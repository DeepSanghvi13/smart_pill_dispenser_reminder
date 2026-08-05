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

  /// Save a newly captured or selected image file to local app storage
  /// and store its metadata in the Hive user_photos box.
  Future<UserPhoto?> savePhoto({
    required File sourceFile,
    required String userId,
    required String userRole,
    String? caption,
  }) async {
    try {
      final normalizedUserId = userId.trim().toLowerCase();
      if (normalizedUserId.isEmpty) {
        throw Exception("Cannot save photo without a valid userId.");
      }

      // Generate unique photo ID
      final photoId = 'PHOTO_${_uuid.v4()}';

      // Get app storage directory: /user_photos/<userId>/
      final appDir = await getApplicationDocumentsDirectory();
      final userPhotosDir = Directory('${appDir.path}/user_photos/$normalizedUserId');

      if (!await userPhotosDir.exists()) {
        await userPhotosDir.create(recursive: true);
      }

      // Copy source file to target path
      final targetPath = '${userPhotosDir.path}/$photoId.jpg';
      final savedFile = await sourceFile.copy(targetPath);

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

      // Save to Hive
      final box = HiveService().userPhotosBox;
      await box.put(photoId, userPhoto);

      return userPhoto;
    } catch (e) {
      debugPrint("Error saving photo: $e");
      return null;
    }
  }

  /// Get all photos belonging to the specified user ID, sorted newest first
  List<UserPhoto> getUserPhotos(String userId) {
    final normalizedUserId = userId.trim().toLowerCase();
    if (normalizedUserId.isEmpty) return [];

    final box = HiveService().userPhotosBox;
    final userPhotos = box.values
        .where((photo) => photo.userId.toLowerCase() == normalizedUserId)
        .toList();

    // Sort newest first
    userPhotos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userPhotos;
  }

  /// Update photo caption in Hive
  Future<bool> updateCaption({
    required String photoId,
    required String userId,
    required String newCaption,
  }) async {
    try {
      final box = HiveService().userPhotosBox;
      final existingPhoto = box.get(photoId);

      if (existingPhoto == null) return false;

      // Ownership check
      if (existingPhoto.userId.toLowerCase() != userId.trim().toLowerCase()) {
        throw Exception("Unauthorized: photo does not belong to user.");
      }

      final updatedPhoto = existingPhoto.copyWith(
        caption: newCaption.trim(),
        updatedAt: DateTime.now(),
      );

      await box.put(photoId, updatedPhoto);
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
      final box = HiveService().userPhotosBox;

      // Ownership check
      if (photo.userId.toLowerCase() != userId.trim().toLowerCase()) {
        throw Exception("Unauthorized: photo does not belong to user.");
      }

      // Delete from Hive
      await box.delete(photo.photoId);

      // Delete actual file from local storage
      final file = File(photo.imagePath);
      if (await file.exists()) {
        await file.delete();
      }

      return true;
    } catch (e) {
      debugPrint("Error deleting photo: $e");
      return false;
    }
  }

  /// Get all photos (For Admin inspection if required)
  List<UserPhoto> getAllPhotosForAdmin() {
    final box = HiveService().userPhotosBox;
    final allPhotos = box.values.toList();
    allPhotos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allPhotos;
  }
}
