import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/photo_provider.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

class AddPhotoScreen extends StatefulWidget {
  final File initialFile;

  const AddPhotoScreen({
    super.key,
    required this.initialFile,
  });

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  late File _currentFile;
  final TextEditingController _captionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.initialFile;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take New Photo'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (picked != null && mounted) {
                  setState(() {
                    _currentFile = File(picked.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (picked != null && mounted) {
                  setState(() {
                    _currentFile = File(picked.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhoto() async {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser;

    if (userId == null || userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User session not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userRole = auth.isCaretaker
        ? 'caretaker'
        : (auth.isAdmin ? 'admin' : 'patient');

    setState(() {
      _isSaving = true;
    });

    final photoProvider = context.read<PhotoProvider>();
    final savedPhoto = await photoProvider.addPhoto(
      imageFile: _currentFile,
      userId: userId,
      userRole: userRole,
      caption: _captionController.text,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (savedPhoto != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to My Photos screen or pop back cleanly
      Navigator.pushReplacementNamed(context, AppRoutes.myPhotos);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(photoProvider.errorMessage ?? 'Failed to save photo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Change / Retake Photo',
            onPressed: _isSaving ? null : _changePhoto,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    _currentFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Caption input field
              TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Caption (Optional)',
                  hintText: 'Add notes or description about this photo...',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons: Retake / Change, Save, Cancel
              if (_isSaving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: _savePhoto,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Save Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _changePhoto,
                  icon: const Icon(Icons.cameraswitch),
                  label: const Text('Retake / Change Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
