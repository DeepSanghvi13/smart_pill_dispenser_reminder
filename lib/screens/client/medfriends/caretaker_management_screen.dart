import 'package:flutter/material.dart';
import '../../../services/caretaker_service.dart';
import '../../../models/caretaker.dart';
import 'package:smart_pill_reminder/routes/app_routes.dart';
import 'add_caretaker_screen.dart';

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

  static const String _menuEdit = 'edit';
  static const String _menuToggle = 'toggle';
  static const String _menuDelete = 'delete';

  @override
  void initState() {
    super.initState();
    _loadCaretakers();
  }

  Future<void> _loadCaretakers() async {
    setState(() => isLoading = true);
    try {
      final loaded = await _service.getAllCaretakers();
      if (!mounted) return;
      setState(() => caretakers = loaded);
    } catch (e) {
      if (!mounted) return;
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
        title: const Text('Caretaker Mode'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _openAddCaretaker,
            child: Text(
              'ADD',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : caretakers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No Caretakers Added'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openAddCaretaker,
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
                          backgroundColor:
                              c.isActive ? Colors.green : Colors.grey,
                          child: Text(c.firstName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(c.fullName),
                        subtitle: Text('${c.relationship} • ${c.phoneNumber}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            await _handleMenuAction(value, c);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: _menuEdit,
                              child: Text('Edit'),
                            ),
                            PopupMenuItem<String>(
                              value: _menuToggle,
                              child: Text(c.isActive ? 'Deactivate' : 'Activate'),
                            ),
                            const PopupMenuItem<String>(
                              value: _menuDelete,
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: null,
    );
  }

  Future<void> _openAddCaretaker() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCaretakerScreen(),
      ),
    );
    if (result == true) {
      await _loadCaretakers();
    }
  }

  Future<void> _handleMenuAction(String value, Caretaker caretaker) async {
    if (value == _menuEdit) {
      final result = await Navigator.pushNamed<bool>(
        context,
        AppRoutes.editCaretaker,
        arguments: caretaker,
      );
      if (result == true) {
        await _loadCaretakers();
      }
      return;
    }

    if (value == _menuToggle) {
      await _service.toggleStatus(caretaker.id!, !caretaker.isActive);
      await _loadCaretakers();
      return;
    }

    if (value == _menuDelete) {
      await _service.deleteCaretaker(caretaker.id!);
      await _loadCaretakers();
    }
  }
}



