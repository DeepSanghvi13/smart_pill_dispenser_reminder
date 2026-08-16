import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_photo.dart';
import '../services/photo_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();

  List<UserPhoto> _userPhotos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserPhoto> get userPhotos => List.unmodifiable(_userPhotos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _resolveUserId(String? userId) {
    if (userId != null && userId.trim().isNotEmpty) {
      return userId.trim().toLowerCase();
    }
    final current = AuthService().currentUser;
    if (current != null && current.trim().isNotEmpty) {
      return current.trim().toLowerCase();
    }
    return DatabaseService().activePatientId.trim().toLowerCase();
  }

  /// Load photos for the given userId
  void loadPhotos([String? userId]) {
    final targetUserId = _resolveUserId(userId);

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userPhotos = _photoService.getUserPhotos(targetUserId);
    } catch (e) {
      _errorMessage = "Failed to load photos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new photo for current userId
  Future<UserPhoto?> addPhoto({
    required File imageFile,
    required String userId,
    required String userRole,
    String? caption,
  }) async {
    final targetUserId = _resolveUserId(userId);

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedPhoto = await _photoService.savePhoto(
        sourceFile: imageFile,
        userId: targetUserId,
        userRole: userRole,
        caption: caption,
      );

      if (savedPhoto != null) {
        _userPhotos = _photoService.getUserPhotos(targetUserId);
      } else {
        _errorMessage = "Could not save photo to storage.";
      }
      return savedPhoto;
    } catch (e) {
      _errorMessage = "Error adding photo: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update caption of a photo
  Future<bool> updateCaption({
    required String photoId,
    required String userId,
    required String newCaption,
  }) async {
    final targetUserId = _resolveUserId(userId);

    final success = await _photoService.updateCaption(
      photoId: photoId,
      userId: targetUserId,
      newCaption: newCaption,
    );

    if (success) {
      loadPhotos(targetUserId);
    }
    return success;
  }

  /// Delete a photo
  Future<bool> deletePhoto({
    required UserPhoto photo,
    required String userId,
  }) async {
    final targetUserId = _resolveUserId(userId);

    final success = await _photoService.deletePhoto(
      photo: photo,
      userId: targetUserId,
    );

    if (success) {
      loadPhotos(targetUserId);
    }
    return success;
  }
}
