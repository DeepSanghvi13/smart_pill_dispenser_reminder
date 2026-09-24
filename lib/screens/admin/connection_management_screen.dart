import 'package:flutter/material.dart';
import '../../../services/mysql_api_service.dart';
import '../../../widgets/admin_sidebar.dart';
import '../../../routes/app_routes.dart';

class ConnectionManagementScreen extends StatefulWidget {
  const ConnectionManagementScreen({super.key});

  @override
  State<ConnectionManagementScreen> createState() => _ConnectionManagementScreenState();
}

class _ConnectionManagementScreenState extends State<ConnectionManagementScreen> {
  final MySQLApiService _api = MySQLApiService();
  bool _isLoading = true;
  
  List<dynamic> _doctorConnections = [];
  List<dynamic> _caretakerConnections = [];
  List<dynamic> _pharmacyConnections = [];
  
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
    setState(() => _isLoading = true);
    try {
      final connRes = await _api.adminGetConnections();
      if (connRes['ok'] == true) {
        final data = connRes['connections'] as Map<String, dynamic>;
        _doctorConnections = List.from(data['doctorConnections'] ?? []);
        _caretakerConnections = List.from(data['caretakerConnections'] ?? []);
        _pharmacyConnections = List.from(data['pharmacyConnections'] ?? []);
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
      // Handle error
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
    
    if (type == 'doctor') { targets = _doctors; targetLabel = 'Doctor'; }
    else if (type == 'caretaker') { targets = _caretakers; targetLabel = 'Caretaker'; }
    else if (type == 'pharmacy') { targets = _pharmacies; targetLabel = 'Pharmacy'; }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Create $targetLabel Connection'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Select Patient'),
                    items: _patients.map((p) => DropdownMenuItem<int>(
                      value: p['id'],
                      child: Text(p['fullName'] ?? 'Unknown'),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedPatientId = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Select $targetLabel'),
                    items: targets.map((t) => DropdownMenuItem<int>(
                      value: t['id'],
                      child: Text(t['fullName'] ?? t['shopName'] ?? 'Unknown'),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedTargetId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (selectedPatientId != null && selectedTargetId != null) ? () async {
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final res = await _api.adminCreateConnection(type, selectedPatientId!, selectedTargetId!);
                    if (res['ok'] == true) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection created successfully')));
                      }
                      await _loadData();
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res["message"]}')));
                      }
                      setState(() => _isLoading = false);
                    }
                  } : null,
                  child: const Text('Create'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _deleteConnection(String type, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this connection?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      final res = await _api.adminDeleteConnection(type, id);
      if (res['ok'] == true) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection deleted successfully')));
         }
         await _loadData();
      } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res["message"]}')));
         }
         setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildConnectionsTable(String title, List<dynamic> items, String type, String targetNameField) {
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
                    final patientName = item['requesterName'] ?? item['patientName'] ?? 'Unknown';
                    final targetName = item['doctorName'] ?? item['caretakerName'] ?? item['shopName'] ?? 'Unknown';
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
                  _buildConnectionsTable('Doctor Connections', _doctorConnections, 'doctor', 'doctorName'),
                  _buildConnectionsTable('Caretaker Connections', _caretakerConnections, 'caretaker', 'caretakerName'),
                  _buildConnectionsTable('Pharmacy Connections', _pharmacyConnections, 'pharmacy', 'shopName'),
                ],
              ),
            ),
    );
  }
}
