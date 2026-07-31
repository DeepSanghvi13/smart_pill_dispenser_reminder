import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../services/hive_service.dart';
import '../../../services/mysql_sync_helper.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../models/medicine.dart';
import '../../../models/user.dart';
import '../../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class MedicineManagementScreen extends StatefulWidget {
  const MedicineManagementScreen({super.key});

  @override
  State<MedicineManagementScreen> createState() => _MedicineManagementScreenState();
}

class _MedicineManagementScreenState extends State<MedicineManagementScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  List<Medicine> _medicines = [];
  List<User> _patients = [];

  String _searchQuery = '';
  String _selectedTypeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final mBox = HiveService().medicinesBox;
      final uBox = HiveService().usersBox;

      setState(() {
        _medicines = mBox.values.toList();
        _patients = uBox.values.where((u) => u.role == 'patient').toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Medicine> get _filteredMedicines {
    return _medicines.where((med) {
      final patientName = _patients.firstWhere((p) => p.email == med.patientId, orElse: () => User(fullName: med.patientId, email: med.patientId, password: '')).fullName;
      final matchesSearch = med.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          med.patientId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          patientName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesType = _selectedTypeFilter == 'All' ||
          med.type.toLowerCase() == _selectedTypeFilter.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();
  }

  void _showAddMedicineDialog() {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot add medicine because no Patients are registered.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final dosageController = TextEditingController(text: '1 Pill');
    final quantityController = TextEditingController(text: '10');
    final notesController = TextEditingController();
    String selectedType = 'Tablets';
    String selectedFrequency = 'Daily';
    String selectedPatient = _patients[0].email;
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule New Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPatient,
                  decoration: const InputDecoration(labelText: 'Target Patient', prefixIcon: Icon(Icons.person)),
                  items: _patients.map((p) => DropdownMenuItem(value: p.email, child: Text(p.fullName))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedPatient = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name', prefixIcon: Icon(Icons.medication)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                  items: const [
                    DropdownMenuItem(value: 'Tablets', child: Text('Tablets')),
                    DropdownMenuItem(value: 'Syrup', child: Text('Syrup')),
                    DropdownMenuItem(value: 'Injection', child: Text('Injection')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage (e.g. 1 Pill, 5ml)', prefixIcon: Icon(Icons.scale)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Total Quantity', prefixIcon: Icon(Icons.numbers)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency', prefixIcon: Icon(Icons.repeat)),
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Twice a day', child: Text('Twice a day')),
                    DropdownMenuItem(value: 'Three times a day', child: Text('Three times a day')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'As needed', child: Text('As needed')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedFrequency = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text('Scheduled Time: ${selectedTime.format(context)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Start: ${DateFormat('yyyy-MM-dd').format(startDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('End: ${DateFormat('yyyy-MM-dd').format(endDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes / Instructions', prefixIcon: Icon(Icons.notes)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final box = HiveService().medicinesBox;
                var maxId = 0;
                for (final m in box.values) {
                  if (m.id != null && m.id! > maxId) maxId = m.id!;
                }
                final nextId = maxId + 1;

                final currentAdmin = context.read<AuthService>().currentUser ?? 'admin';
                final now = DateTime.now();

                // Format TimeOfDay as hh:mm a
                final dt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                final formattedTime = DateFormat('hh:mm a').format(dt);

                final med = Medicine(
                  id: nextId,
                  userId: selectedPatient,
                  patientId: selectedPatient,
                  name: nameController.text.trim(),
                  type: selectedType,
                  dosage: dosageController.text.trim(),
                  quantity: quantityController.text.trim(),
                  frequency: selectedFrequency,
                  time: formattedTime,
                  startDate: startDate,
                  endDate: endDate,
                  notes: notesController.text.trim(),
                  createdBy: currentAdmin,
                  updatedBy: currentAdmin,
                  createdAt: now,
                  updatedAt: now,
                );

                await box.put(nextId, med);
                await MySQLSyncHelper.syncMedicine(med);
                await _db.adminLogActivity('Medication Schedule added: ${nameController.text.trim()} for patient $selectedPatient');
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicineDialog(Medicine med) {
    final nameController = TextEditingController(text: med.name);
    final dosageController = TextEditingController(text: med.dosage);
    final quantityController = TextEditingController(text: med.quantity);
    final notesController = TextEditingController(text: med.notes);
    String selectedType = med.type;
    String selectedFrequency = med.frequency;

    // Parse time
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    try {
      final parsed = DateFormat('h:mm a').parse(med.time);
      selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {}

    DateTime startDate = med.startDate;
    DateTime endDate = med.endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modify Medication details: ${med.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name', prefixIcon: Icon(Icons.medication)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category)),
                  items: const [
                    DropdownMenuItem(value: 'Tablets', child: Text('Tablets')),
                    DropdownMenuItem(value: 'Syrup', child: Text('Syrup')),
                    DropdownMenuItem(value: 'Injection', child: Text('Injection')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage', prefixIcon: Icon(Icons.scale)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Total Quantity', prefixIcon: Icon(Icons.numbers)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency', prefixIcon: Icon(Icons.repeat)),
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Twice a day', child: Text('Twice a day')),
                    DropdownMenuItem(value: 'Three times a day', child: Text('Three times a day')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'As needed', child: Text('As needed')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedFrequency = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text('Scheduled Time: ${selectedTime.format(context)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('Start: ${DateFormat('yyyy-MM-dd').format(startDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text('End: ${DateFormat('yyyy-MM-dd').format(endDate)}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.notes)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final box = HiveService().medicinesBox;
                final currentAdmin = context.read<AuthService>().currentUser ?? 'admin';
                final now = DateTime.now();

                // Format TimeOfDay as hh:mm a
                final dt = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                final formattedTime = DateFormat('hh:mm a').format(dt);

                final updated = med.copyWith(
                  name: nameController.text.trim(),
                  type: selectedType,
                  dosage: dosageController.text.trim(),
                  quantity: quantityController.text.trim(),
                  frequency: selectedFrequency,
                  time: formattedTime,
                  startDate: startDate,
                  endDate: endDate,
                  notes: notesController.text.trim(),
                  updatedBy: currentAdmin,
                  updatedAt: now,
                );

                await box.put(med.id, updated);
                await MySQLSyncHelper.syncMedicine(updated);
                await _db.adminLogActivity('Modified Medication Info: ${med.name} for Patient ${med.patientId}');
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdminLayout(
      title: 'Medication Manager',
      activeRoute: AppRoutes.adminMedicineList,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by medication or patient name...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: _selectedTypeFilter,
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Types')),
                              DropdownMenuItem(value: 'Tablets', child: Text('Tablets')),
                              DropdownMenuItem(value: 'Syrup', child: Text('Syrup')),
                              DropdownMenuItem(value: 'Injection', child: Text('Injection')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedTypeFilter = val);
                              }
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddMedicineDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Schedule Medicine'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredMedicines.isEmpty
                      ? const Center(child: Text('No active scheduled medications found.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _filteredMedicines.map((med) {
                                final patientName = _patients.firstWhere((p) => p.email == med.patientId, orElse: () => User(fullName: med.patientId, email: med.patientId, password: '')).fullName;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(patientName)),
                                    DataCell(
                                      Row(
                                        children: [
                                          Icon(
                                            med.type == 'Syrup'
                                                ? Icons.medication_liquid
                                                : (med.type == 'Injection' ? Icons.vaccines : Icons.medication),
                                            size: 18,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(med.name),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(med.dosage)),
                                    DataCell(Text(med.frequency)),
                                    DataCell(Text(med.time)),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.indigo),
                                            onPressed: () => _showEditMedicineDialog(med),
                                            tooltip: 'Modify Schedule',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Delete Medicine'),
                                                  content: Text('Are you sure you want to permanently cancel medication ${med.name}?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, false),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                await HiveService().medicinesBox.delete(med.id);
                                                if (med.id != null) {
                                                  await MySQLSyncHelper.deleteMedicine(med.id!, userId: med.patientId);
                                                }
                                                await _db.adminLogActivity('Permanently Deleted Medicine: ${med.name} for Patient ${med.patientId}');
                                                _loadData();
                                              }
                                            },
                                            tooltip: 'Remove Medicine',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
