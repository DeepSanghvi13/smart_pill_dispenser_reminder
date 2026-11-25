import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/mysql_api_service.dart';

class AppImageHelper {
  /// Resolves an image path/URL to an appropriate Flutter ImageProvider.
  /// Supports:
  /// 1. Remote full HTTP/HTTPS/blob URLs -> NetworkImage
  /// 2. Base64 data URLs (e.g. data:image/jpeg;base64,...) -> MemoryImage
  /// 3. Backend relative paths (e.g. /uploads/profiles/user_123.jpg) -> NetworkImage with server baseUrl
  /// 4. Local device file paths -> FileImage (on non-web platforms)
  /// 5. Null or empty or invalid -> returns null (allows fallback to default placeholder)
  static ImageProvider? getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return null;
    }

    final path = imagePath.trim();

    // 1. Base64 data URI
    if (path.startsWith('data:image')) {
      try {
        final commaIdx = path.indexOf(',');
        final base64Data = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        final bytes = base64Decode(base64Data);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    // 2. Full remote URL or Web blob URL
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      return NetworkImage(path);
    }

    // 3. Relative backend uploads path
    if (path.startsWith('/uploads') || path.startsWith('uploads')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final baseUrl = MySQLApiService().baseUrl;
      return NetworkImage('$baseUrl$cleanPath');
    }

    // 4. Local device file path (only on non-web)
    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }

    return null;
  }

  /// Builds a cross-platform Image widget that works seamlessly on Web, Android, iOS, Desktop.
  static Widget buildImage({
    String? imagePath,
    Uint8List? bytes,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final fallbackError = errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          ),
        );

    // 1. Direct memory bytes provided
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackError,
      );
    }

    if (imagePath == null || imagePath.trim().isEmpty) {
      return fallbackError;
    }

    final path = imagePath.trim();

    // 2. Base64 data URI
    if (path.startsWith('data:image')) {
      try {
        final commaIdx = path.indexOf(',');
        final base64Data = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        final decodedBytes = base64Decode(base64Data);
        return Image.memory(
          decodedBytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => fallbackError,
        );
      } catch (_) {
        return fallbackError;
      }
    }

    // 3. Web blob URL or remote HTTP URL
    if (path.startsWith('blob:') || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackError,
      );
    }

    // 4. Relative backend uploads path
    if (path.startsWith('/uploads') || path.startsWith('uploads')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final fullUrl = '${MySQLApiService().baseUrl}$cleanPath';
      return Image.network(
        fullUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallbackError,
      );
    }

    // 5. Local file path on native platforms
    if (!kIsWeb) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => fallbackError,
          );
        }
      } catch (_) {}
    }

    return fallbackError;
  }
}
