import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mysql_api_service.dart';

class AppImageHelper {
  /// Resolves an image path/URL to an appropriate Flutter ImageProvider.
  /// Supports:
  /// 1. Remote full HTTP/HTTPS URLs -> NetworkImage
  /// 2. Backend relative paths (e.g. `/uploads/profiles/user_123.jpg`) -> NetworkImage with server baseUrl
  /// 3. Local device file paths (e.g. during picking preview) -> FileImage
  /// 4. Null or empty or invalid -> returns null (allows fallback to default avatar/placeholder)
  static ImageProvider? getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    final path = imagePath.trim();

    // 1. Full remote URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }

    // 2. Relative backend uploads path
    if (path.startsWith('/uploads') || path.startsWith('uploads')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final baseUrl = MySQLApiService().baseUrl;
      return NetworkImage('$baseUrl$cleanPath');
    }

    // 3. Local device file path
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}

    return null;
  }
}
