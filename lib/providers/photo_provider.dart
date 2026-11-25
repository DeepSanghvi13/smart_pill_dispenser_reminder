import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_photo.dart';
import '../services/photo_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService = PhotoService();

  List<UserPhoto> _userPhotos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserPhoto> get userPhotos => List.unmodifiable(_userPhotos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load photos for the given userId
  void loadPhotos(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      _userPhotos = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userPhotos = _photoService.getUserPhotos(userId);
    } catch (e) {
      _errorMessage = "Failed to load photos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new photo for current userId (supports cross-platform XFile, bytes, or File)
  Future<UserPhoto?> addPhoto({
    File? imageFile,
    XFile? xFile,
    Uint8List? imageBytes,
    required String userId,
    required String userRole,
    String? caption,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedPhoto = await _photoService.savePhoto(
        sourceFile: imageFile,
        sourceXFile: xFile,
        imageBytes: imageBytes,
        userId: userId,
        userRole: userRole,
        caption: caption,
      );

      if (savedPhoto != null) {
        loadPhotos(userId);
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
    final success = await _photoService.updateCaption(
      photoId: photoId,
      userId: userId,
      newCaption: newCaption,
    );

    if (success) {
      loadPhotos(userId);
    }
    return success;
  }

  /// Delete a photo
  Future<bool> deletePhoto({
    required UserPhoto photo,
    required String userId,
  }) async {
    final success = await _photoService.deletePhoto(
      photo: photo,
      userId: userId,
    );

    if (success) {
      loadPhotos(userId);
    }
    return success;
  }
}
