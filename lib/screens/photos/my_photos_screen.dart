import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/photo_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/photo_card.dart';
import '../../widgets/photo_picker_bottom_sheet.dart';
import '../../routes/app_routes.dart';

class MyPhotosScreen extends StatefulWidget {
  const MyPhotosScreen({super.key});

  @override
  State<MyPhotosScreen> createState() => _MyPhotosScreenState();
}

class _MyPhotosScreenState extends State<MyPhotosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final auth = context.read<AuthService>();
        context.read<PhotoProvider>().loadPhotos(auth.currentUser);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final photoProvider = context.watch<PhotoProvider>();
    final userPhotos = photoProvider.userPhotos;
    final currentUserId = auth.currentUser ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Add Photo',
            onPressed: () => PhotoPickerBottomSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          photoProvider.loadPhotos(currentUserId);
        },
        child: photoProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : userPhotos.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.photo_library_outlined,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Photos Saved Yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Tap the button below or on your Home screen to add your first photo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => PhotoPickerBottomSheet.show(context),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Add Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: userPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = userPhotos[index];
                      return PhotoCard(
                        photo: photo,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.photoDetails,
                            arguments: photo,
                          );
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PhotoPickerBottomSheet.show(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Add Photo'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
