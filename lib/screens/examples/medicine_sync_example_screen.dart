import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicine.dart';
import '../../services/database_service.dart';
import '../../services/mysql_api_service.dart';
import '../../providers/sync_provider.dart';

/// Example Medicine Sync Screen
/// Shows how to save medicines locally and sync to MySQL
class MedicineSyncExampleScreen extends StatefulWidget {
  @override
  State<MedicineSyncExampleScreen> createState() =>
      _MedicineSyncExampleScreenState();
}

class _MedicineSyncExampleScreenState extends State<MedicineSyncExampleScreen> {
  final DatabaseService _dbService = DatabaseService();
  final MySQLApiService _apiService = MySQLApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  List<Medicine> _medicines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  /// Load medicines from local database
  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);
    try {
      final medicines = await _dbService.getAllMedicines();
      setState(() => _medicines = medicines);
    } catch (e) {
      _showSnackBar('Error loading medicines: $e');
    }
    setState(() => _isLoading = false);
  }

  /// Save medicine locally and sync to server
  Future<void> _saveMedicine() async {
    if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create medicine object
      final medicine = Medicine(
        name: _nameController.text,
        dosage: _dosageController.text,
        time: _timeController.text,
        category: MedicineCategory.tablets,
      );

      // Step 1: Save to local database
      final medicineId = await _dbService.addMedicine(medicine);
      _showSnackBar('✅ Medicine saved locally (ID: $medicineId)');

      // Step 2: Try to sync to server
      final medicineWithId = medicine.copyWith(id: medicineId);
      final isSynced = await _apiService.syncMedicine(medicineWithId);

      if (isSynced) {
        _showSnackBar('✅ Medicine synced to MySQL');
      } else {
        _showSnackBar('⚠️ Medicine saved locally, sync failed (offline mode)');
      }

      // Clear inputs and reload
      _nameController.clear();
      _dosageController.clear();
      _timeController.clear();
      await _loadMedicines();
    } catch (e) {
      _showSnackBar('Error saving medicine: $e');
    }

    setState(() => _isLoading = false);
  }

  /// Sync all medicines to server
  Future<void> _syncAllToServer() async {
    final syncProvider = context.read<SyncProvider>();
    final success = await syncProvider.syncAllData('userId123');

    if (success) {
      _showSnackBar('✅ All medicines synced to MySQL');
    } else {
      _showSnackBar('❌ Sync failed - check connection');
    }
  }

  /// Pull medicines from server
  Future<void> _pullFromServer() async {
    final syncProvider = context.read<SyncProvider>();
    final success = await syncProvider.pullMedicinesFromServer();

    if (success) {
      _showSnackBar('✅ Medicines pulled from server');
      await _loadMedicines();
    } else {
      _showSnackBar('❌ Failed to pull from server');
    }
  }

  /// Delete medicine
  Future<void> _deleteMedicine(int id) async {
    try {
      // Delete from local database
      await _dbService.deleteMedicine(id);
      _showSnackBar('Medicine deleted from local storage');

      // Try to delete from server
      final isDeleted = await _apiService.deleteMedicineFromServer(id);
      if (isDeleted) {
        _showSnackBar('Medicine deleted from server too');
      }

      await _loadMedicines();
    } catch (e) {
      _showSnackBar('Error deleting medicine: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Sync Example'),
        elevation: 0,
      ),
      body: Consumer<SyncProvider>(
        builder: (context, syncProvider, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Sync Status Card
                Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          syncProvider.syncStatus ?? 'No status',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        if (syncProvider.lastSyncTime != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'Last sync: ${syncProvider.lastSyncTime}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Add Medicine Form
                Card(
                  margin: EdgeInsets.all(16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Medicine',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Medicine name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _dosageController,
                          decoration: InputDecoration(
                            hintText: 'Dosage (e.g., 500mg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _timeController,
                          decoration: InputDecoration(
                            hintText: 'Time (e.g., 08:00)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveMedicine,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Save & Sync'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sync Buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: syncProvider.isSyncing ? null : _syncAllToServer,
                          child: Text('Sync All'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: syncProvider.isSyncing ? null : _pullFromServer,
                          child: Text('Pull from Server'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Medicines List
                if (_medicines.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No medicines yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _medicines[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Text(
                            medicine.category.emoji,
                            style: TextStyle(fontSize: 24),
                          ),
                          title: Text(medicine.name),
                          subtitle: Text(
                            '${medicine.dosage} at ${medicine.time}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              if (medicine.id != null) {
                                _deleteMedicine(medicine.id!);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
