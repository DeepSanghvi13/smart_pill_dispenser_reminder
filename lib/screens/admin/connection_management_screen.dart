import 'package:flutter/material.dart';
import '../../../services/mysql_api_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../routes/app_routes.dart';
import '../../../models/admin_patient_connection.dart';

class ConnectionManagementScreen extends StatefulWidget {
  const ConnectionManagementScreen({super.key});

  @override
  State<ConnectionManagementScreen> createState() =>
      _ConnectionManagementScreenState();
}

class _ConnectionManagementScreenState
    extends State<ConnectionManagementScreen> {
  final MySQLApiService _api = MySQLApiService();
  bool _isLoading = true;
  String? _error;

  List<dynamic> _doctorConnections = [];
  List<dynamic> _caretakerConnections = [];
  List<dynamic> _pharmacyConnections = [];
  List<AdminPatientConnection> _patientConnections = [];

  List<dynamic> _patients = [];
  List<dynamic> _doctors = [];
  List<dynamic> _caretakers = [];
  List<dynamic> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final connRes = await _api.adminGetConnections();
      if (connRes['ok'] == true) {
        final data =
            Map<String, dynamic>.from(connRes['connections'] as Map? ?? {});
        _doctorConnections = List.from(data['doctorConnections'] ?? []);
        _caretakerConnections = List.from(data['caretakerConnections'] ?? []);
        _pharmacyConnections = List.from(data['pharmacyConnections'] ?? []);
        _patientConnections = [
          for (final entry in [
            ('doctor', _doctorConnections),
            ('caretaker', _caretakerConnections),
            ('pharmacy', _pharmacyConnections),
          ])
            for (final item in entry.$2)
              AdminPatientConnection.fromMap(
                  entry.$1, Map<String, dynamic>.from(item as Map)),
        ];
      } else {
        _error = connRes['message'] as String? ?? 'Unable to load connections.';
      }

      final pRes = await _api.adminGetUsers('patient');
      final dRes = await _api.adminGetUsers('doctor');
      final cRes = await _api.adminGetUsers('caretaker');
      final phRes = await _api.adminGetUsers('pharmacy');

      if (pRes['ok'] == true) _patients = List.from(pRes['users'] ?? []);
      if (dRes['ok'] == true) _doctors = List.from(dRes['users'] ?? []);
      if (cRes['ok'] == true) _caretakers = List.from(cRes['users'] ?? []);
      if (phRes['ok'] == true) _pharmacies = List.from(phRes['users'] ?? []);
    } catch (e) {
      _error = 'Unable to load connection data.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createConnection(String type) async {
    int? selectedPatientId;
    int? selectedTargetId;
    List<dynamic> targets = [];
    String targetLabel = '';

    if (type == 'patient') {
      String? selectedType;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Create Patient Connection'),
          content: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Connection type'),
            items: const [
              DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
              DropdownMenuItem(value: 'caretaker', child: Text('Caretaker')),
              DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
            ],
            onChanged: (value) => selectedType = value,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (selectedType != null) Navigator.pop(ctx, selectedType);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ).then((selectedType) {
        if (selectedType is String) _createConnection(selectedType);
      });
      return;
    } else if (type == 'doctor') {
      targets = _doctors;
      targetLabel = 'Doctor';
    } else if (type == 'caretaker') {
      targets = _caretakers;
      targetLabel = 'Caretaker';
    } else if (type == 'pharmacy') {
      targets = _pharmacies;
      targetLabel = 'Pharmacy';
    }

    await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Create $targetLabel Connection'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration:
                        const InputDecoration(labelText: 'Select Patient'),
                    items: _patients
                        .map((p) => DropdownMenuItem<int>(
                              value: p['id'],
                              child: Text(p['fullName'] ?? 'Unknown'),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedPatientId = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration:
                        InputDecoration(labelText: 'Select $targetLabel'),
                    items: targets
                        .map((t) => DropdownMenuItem<int>(
                              value: t['id'],
                              child: Text(
                                  t['fullName'] ?? t['shopName'] ?? 'Unknown'),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedTargetId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (selectedPatientId != null &&
                          selectedTargetId != null)
                      ? () async {
                          Navigator.pop(ctx);
                          setState(() => _isLoading = true);
                          final res = await _api.adminCreateConnection(
                              type, selectedPatientId!, selectedTargetId!);
                          if (res['ok'] == true) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Connection created successfully')));
                            }
                            await _loadData();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Error: ${res["message"]}')));
                            }
                            setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  child: const Text('Create'),
                ),
              ],
            );
          });
        });
  }

  Future<void> _deleteConnection(String type, int id) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text(
                  'Are you sure you want to delete this connection?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await _api.adminDeleteConnection(type, id);
      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connection deleted successfully')));
        }
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${res["message"]}')));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildConnectionsTable(
      String title, List<dynamic> items, String type, String targetNameField) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () => _createConnection(type),
                  icon: const Icon(Icons.add),
                  label: const Text('Link New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(child: Text('No connections found.'))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Patient')),
                    DataColumn(label: Text(title.split(' ').first)),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: items.map((item) {
                    final patientName = item['requesterName'] ??
                        item['patientName'] ??
                        'Unknown';
                    final targetName = item['doctorName'] ??
                        item['caretakerName'] ??
                        item['shopName'] ??
                        'Unknown';
                    return DataRow(cells: [
                      DataCell(Text(patientName)),
                      DataCell(Text(targetName)),
                      DataCell(Text(item['status'] ?? 'Unknown')),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteConnection(type, item['id']),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Connection Management',
      activeRoute: AppRoutes.adminConnections,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_error!,
                            style: TextStyle(color: Colors.red.shade900)),
                      ),
                    ),
                  _buildConnectionsTable('Doctor Connections',
                      _doctorConnections, 'doctor', 'doctorName'),
                  _buildConnectionsTable('Caretaker Connections',
                      _caretakerConnections, 'caretaker', 'caretakerName'),
                  _buildConnectionsTable('Pharmacy Connections',
                      _pharmacyConnections, 'pharmacy', 'shopName'),
                  _buildPatientConnectionsTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientConnectionsTable() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Patient Connections',
                    style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () => _createConnection('patient'),
                  icon: const Icon(Icons.add),
                  label: const Text('Link New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_patientConnections.isEmpty)
              const Center(child: Text('No patient connections found.'))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Patient')),
                    DataColumn(label: Text('Connection')),
                    DataColumn(label: Text('Target')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _patientConnections
                      .map((connection) => DataRow(cells: [
                            DataCell(Text(connection.patientName)),
                            DataCell(Text(connection.type)),
                            DataCell(Text(connection.targetName)),
                            DataCell(Text(connection.status)),
                            DataCell(IconButton(
                              onPressed: connection.id == 0
                                  ? null
                                  : () => _deleteConnection(
                                      connection.type, connection.id),
                              icon: const Icon(Icons.link_off),
                            )),
                          ]))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
