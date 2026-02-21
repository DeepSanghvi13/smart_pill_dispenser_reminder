import 'package:flutter/material.dart';
import '../../services/caretaker_service.dart';
import '../../models/caretaker.dart';
import 'add_caretaker_screen.dart';
import 'edit_caretaker_screen.dart';

class CaretakerManagementScreen extends StatefulWidget {
  const CaretakerManagementScreen({super.key});

  @override
  State<CaretakerManagementScreen> createState() =>
      _CaretakerManagementScreenState();
}

class _CaretakerManagementScreenState extends State<CaretakerManagementScreen> {
  final CaretakerService _service = CaretakerService();
  List<Caretaker> caretakers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaretakers();
  }

  Future<void> _loadCaretakers() async {
    setState(() => isLoading = true);
    try {
      final loaded = await _service.getAllCaretakers();
      setState(() => caretakers = loaded);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍⚕️ Caretaker Mode'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : caretakers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No Caretakers Added'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const AddCaretakerScreen(),
                            ),
                          );
                          if (result == true) _loadCaretakers();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Caretaker'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: caretakers.length,
                  itemBuilder: (context, index) {
                    final c = caretakers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c.isActive ? Colors.green : Colors.grey,
                          child: Text(c.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(c.fullName),
                        subtitle: Text('${c.relationship} • ${c.phoneNumber}'),
                        trailing: PopupMenuButton(
                          itemBuilder: (c) => [
                            PopupMenuItem(
                              onTap: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) =>
                                        EditCaretakerScreen(caretaker: caretakers[index]),
                                  ),
                                );
                                if (result == true) _loadCaretakers();
                              },
                              child: const Text('Edit'),
                            ),
                            PopupMenuItem(
                              onTap: () async {
                                await _service.toggleStatus(caretakers[index].id!, !caretakers[index].isActive);
                                _loadCaretakers();
                              },
                              child: Text(
                                caretakers[index].isActive ? 'Deactivate' : 'Activate',
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () async {
                                await _service.deleteCaretaker(caretakers[index].id!);
                                _loadCaretakers();
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (c) => const AddCaretakerScreen()),
          );
          if (result == true) _loadCaretakers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

