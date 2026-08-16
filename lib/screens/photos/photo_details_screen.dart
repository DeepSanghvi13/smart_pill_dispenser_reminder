import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_photo.dart';
import '../../providers/photo_provider.dart';
import '../../services/auth_service.dart';
import '../../services/photo_service.dart';

class PhotoDetailsScreen extends StatefulWidget {
  final UserPhoto photo;

  const PhotoDetailsScreen({
    super.key,
    required this.photo,
  });

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  late UserPhoto _currentPhoto;

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
  }

  Future<void> _editCaption() async {
    final controller = TextEditingController(text: _currentPhoto.caption ?? '');

    final newCaption = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter photo caption or notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newCaption != null && mounted) {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser ?? '';

      final success = await context.read<PhotoProvider>().updateCaption(
        photoId: _currentPhoto.photoId,
        userId: userId,
        newCaption: newCaption,
      );

      if (success && mounted) {
        setState(() {
          _currentPhoto = _currentPhoto.copyWith(
            caption: newCaption.trim(),
            updatedAt: DateTime.now(),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caption updated successfully.')),
        );
      }
    }
  }

  Future<void> _sharePhoto() async {
    try {
      final file = File(_currentPhoto.imagePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo file does not exist on disk.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(_currentPhoto.imagePath)],
        text: _currentPhoto.caption ?? 'Photo shared from Smart Pill Reminder',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser ?? '';

      final success = await context.read<PhotoProvider>().deletePhoto(
        photo: _currentPhoto,
        userId: userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Return to My Photos
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete photo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(_currentPhoto.imagePath);
    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(_currentPhoto.createdAt);
    final timeFormatted = DateFormat('h:mm a').format(_currentPhoto.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Photo',
            onPressed: _sharePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Caption',
            onPressed: _editCaption,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Photo',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Interactive Full Image View Container
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              color: Colors.black,
              child: Center(
                child: file.existsSync()
                    ? InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                        ),
                      )
                    : FutureBuilder<File?>(
                        future: PhotoService().getValidImageFile(_currentPhoto),
                        builder: (context, snapshot) {
                          final resolvedFile = snapshot.data;
                          if (resolvedFile != null && resolvedFile.existsSync()) {
                            return InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: Image.file(
                                resolvedFile,
                                fit: BoxFit.contain,
                              ),
                            );
                          }
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image file not found', style: TextStyle(color: Colors.white70)),
                            ],
                          );
                        },
                      ),
              ),
            ),

            // Metadata card section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Time Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeFormatted,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      // Caption section
                      Text(
                        'Caption',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (_currentPhoto.caption != null && _currentPhoto.caption!.isNotEmpty)
                            ? _currentPhoto.caption!
                            : 'No caption provided.',
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: (_currentPhoto.caption == null || _currentPhoto.caption!.isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: (_currentPhoto.caption == null || _currentPhoto.caption!.isEmpty)
                              ? Colors.grey
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Control Action Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editCaption,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Caption'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sharePhoto,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
