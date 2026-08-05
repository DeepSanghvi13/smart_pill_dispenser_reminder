import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../routes/app_routes.dart';

class PhotoPickerBottomSheet extends StatelessWidget {
  const PhotoPickerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const PhotoPickerBottomSheet(),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Close bottom sheet
    navigator.pop();

    try {
      // Permission check if camera on mobile platforms
      if (source == ImageSource.camera && (Platform.isAndroid || Platform.isIOS)) {
        final status = await Permission.camera.status;
        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            _showPermissionDialog(
              context,
              'Camera Permission Required',
              'Camera access is permanently denied. Please enable camera permission in your system settings to take photos.',
            );
          }
          return;
        } else if (status.isDenied) {
          final result = await Permission.camera.request();
          if (result.isDenied || result.isPermanentlyDenied) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Camera permission is required to capture photos.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
      }

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        // Selection cancelled by user
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Image selection cancelled.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to load selected image file.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (context.mounted) {
        // Navigate to preview/add photo screen
        Navigator.pushNamed(
          context,
          AppRoutes.addPhoto,
          arguments: file,
        );
      }
    } catch (e) {
      debugPrint("Photo picker error: $e");
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Photo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select how you would like to add a photo',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            title: const Text(
              'Take Photo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Use camera to capture a new photo'),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_rounded,
                color: theme.colorScheme.secondary,
              ),
            ),
            title: const Text(
              'Choose from Gallery',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Pick an existing photo from device gallery'),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
