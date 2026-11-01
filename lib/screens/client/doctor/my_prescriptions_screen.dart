import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/prescription.dart';
import '../../../services/auth_service.dart';
import '../../../services/medical_shop_service.dart';
import '../../../services/mysql_api_service.dart';
import '../../../widgets/digital_prescription_slip.dart';

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
        SnackBar(
          content: Text('Renewal requested for ${p.medicineName}.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadPrescriptions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to request renewal. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No Prescriptions Found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Official prescriptions issued by your connected doctor will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPrescriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _prescriptions.length,
                    itemBuilder: (ctx, i) {
                      final p = _prescriptions[i];
                      return _buildPrescriptionCard(p, theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildPrescriptionCard(Prescription p, ThemeData theme) {
    final doctorName = (p.doctorName != null && p.doctorName!.trim().isNotEmpty)
        ? p.doctorName!.trim()
        : 'Doctor';
    final hospital = (p.doctorHospital != null &&
            p.doctorHospital!.trim().isNotEmpty)
        ? p.doctorHospital!.trim()
        : 'Sanghvi Hospital';
    final spec = (p.doctorSpecialization != null &&
            p.doctorSpecialization!.trim().isNotEmpty)
        ? p.doctorSpecialization!.trim()
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Medicine icon, Name, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D4F8B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication,
                      color: Color(0xFF0D4F8B), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.medicineName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Prescribed by Dr. $doctorName ($hospital${spec != null ? ' - $spec' : ''})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.isActive ? 'Active' : 'Expired',
                    style: TextStyle(
                      color: p.isActive
                          ? Colors.green.shade800
                          : Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Chips: Dosage, Frequency, Duration, Quantity
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(Icons.opacity, p.dosage),
                _buildInfoChip(Icons.alarm, p.frequency),
                _buildInfoChip(Icons.timelapse, p.duration),
                _buildInfoChip(Icons.numbers, 'Qty: ${p.quantity}'),
              ],
            ),

            if (p.diagnosis != null && p.diagnosis!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Diagnosis: ${p.diagnosis}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
              ),
            ],

            if (p.instructions != null && p.instructions!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Instructions: ${p.instructions}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const Divider(height: 18),

            // Issued & Expiry Dates Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Issued: ${p.formattedIssuedDate}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  'Valid until: ${p.formattedValidUntilDate}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: p.isActive ? Colors.grey.shade700 : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action Buttons: Download Slip (PNG/JPG) & Request Renewal
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (p.isRenewable && p.renewalsLeft > 0) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.autorenew, size: 16),
                    label: Text(
                      'Renew (${p.renewalsLeft})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _requestRenewal(p),
                  ),
                  const SizedBox(width: 8),
                ],

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4F8B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text(
                    'Download Slip (PNG/JPG)',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    DigitalPrescriptionSlip.showSlipDialog(context, p);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0D4F8B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
