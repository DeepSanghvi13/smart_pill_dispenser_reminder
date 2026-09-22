import 'package:flutter/material.dart';
import '../../services/mysql_api_service.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  Map<String, dynamic>? _healthData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }

  Future<void> _fetchHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await MySQLApiService().getSystemHealth();
      if (data != null) {
        setState(() => _healthData = data);
      } else {
        setState(() => _error = 'Failed to load system health data');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHealth,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _healthData == null
                  ? const Center(child: Text('No data available'))
                  : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final status = _healthData!['status'] ?? 'Unknown';
    final timestamp = _healthData!['timestamp'] ?? '';
    final uptime = _healthData!['uptime'] ?? 0;
    
    final dbStatus = _healthData!['database']?['status'] ?? 'Unknown';
    final dbLatency = _healthData!['database']?['latency_ms'] ?? 0;
    
    final mem = _healthData!['memory'] ?? {};
    final rss = ((mem['rss'] ?? 0) / 1024 / 1024).toStringAsFixed(2);
    final heapTotal = ((mem['heapTotal'] ?? 0) / 1024 / 1024).toStringAsFixed(2);
    final heapUsed = ((mem['heapUsed'] ?? 0) / 1024 / 1024).toStringAsFixed(2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMetricCard('Status', status.toString().toUpperCase(), status == 'ok' ? Colors.green : Colors.red),
        _buildMetricCard('Uptime', '${(uptime / 60).toStringAsFixed(1)} minutes', Colors.blue),
        _buildMetricCard('Timestamp', timestamp.toString(), Colors.grey),
        
        const SizedBox(height: 16),
        const Text('Database', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildMetricCard('DB Status', dbStatus.toString().toUpperCase(), dbStatus == 'connected' ? Colors.green : Colors.red),
        _buildMetricCard('DB Latency', '${dbLatency}ms', Colors.orange),

        const SizedBox(height: 16),
        const Text('Memory Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildMetricCard('RSS', '${rss}MB', Colors.purple),
        _buildMetricCard('Heap Total', '${heapTotal}MB', Colors.purple),
        _buildMetricCard('Heap Used', '${heapUsed}MB', Colors.purple),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
