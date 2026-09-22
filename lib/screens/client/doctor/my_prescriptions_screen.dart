import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/prescription.dart';
import '../../../services/auth_service.dart';
import '../../../services/medical_shop_service.dart';
import '../../../services/mysql_api_service.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  final MedicalShopService _shopService = MedicalShopService();
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final email = auth.currentUser;
    if (email != null) {
      final list = await _shopService.getPrescriptionsForPatient(email);
      if (mounted) {
        setState(() {
          _prescriptions = list;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestRenewal(Prescription p) async {
    if (p.id == null) return;
    final success = await MySQLApiService().requestPrescriptionRenewal(p.id!);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renewal requested for ${p.medicineName}.')),
      );
      _loadPrescriptions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to request renewal.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? const Center(child: Text('No active prescriptions found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (ctx, i) {
                    final p = _prescriptions[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('Dosage: ${p.dosage} | Freq: ${p.frequency} | Duration: ${p.duration}'),
                            if (p.doctorName != null) Text('Doctor: ${p.doctorName}'),
                            const SizedBox(height: 8),
                            Text('Renewable: ${p.isRenewable ? 'Yes' : 'No'} | Renewals Left: ${p.renewalsLeft}'),
                            if (p.isRenewable && p.renewalsLeft > 0)
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => _requestRenewal(p),
                                  child: const Text('Request Renewal'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
