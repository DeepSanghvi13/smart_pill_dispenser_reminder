import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/prescription.dart';
import '../utils/file_downloader.dart';

class DigitalPrescriptionSlip extends StatelessWidget {
  final Prescription prescription;
  final GlobalKey? boundaryKey;

  const DigitalPrescriptionSlip({
    super.key,
    required this.prescription,
    this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final doctorName = (p.doctorName != null && p.doctorName!.trim().isNotEmpty)
        ? p.doctorName!.trim()
        : 'Dhruv';
    final hospital =
        (p.doctorHospital != null && p.doctorHospital!.trim().isNotEmpty)
            ? p.doctorHospital!.trim()
            : 'Sanghvi Hospital';
    final spec = (p.doctorSpecialization != null &&
            p.doctorSpecialization!.trim().isNotEmpty)
        ? p.doctorSpecialization!.trim()
        : 'Orthopedic';
    final patient = (p.patientName != null && p.patientName!.trim().isNotEmpty)
        ? p.patientName!.trim()
        : 'Deep';

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header: Clinic / Hospital & Doctor Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D4F8B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_hospital,
                        color: Color(0xFF0D4F8B), size: 34),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D4F8B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dr. $doctorName, M.B.B.S., M.S.',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$spec Specialist',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (p.doctorEmail != null || p.doctorPhone != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${p.doctorEmail ?? ''} ${p.doctorPhone != null ? '| ${p.doctorPhone}' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Rx',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Container(height: 2, color: const Color(0xFF0D4F8B)),
            const SizedBox(height: 14),

            // 2. Prescription Meta: Rx ID & Dates
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '℞',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: Color(0xFF0D4F8B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prescription #${p.id ?? '---'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Issued: ${p.formattedIssuedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Valid until: ${p.formattedValidUntilDate}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.isActive
                              ? Colors.grey.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Patient Details Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF0D4F8B), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Name: $patient',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (p.patientEmail != null &&
                            p.patientEmail!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Email / ID: ${p.patientEmail}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D4F8B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'STATUS: ${p.status.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D4F8B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Prescribed Medication Block
            const Text(
              'MEDICATION DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D4F8B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D4F8B).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF0D4F8B).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.medicineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D4F8B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D4F8B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Qty: ${p.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _detailTile(
                            Icons.opacity, 'Dosage', p.dosage),
                      ),
                      Expanded(
                        child: _detailTile(
                            Icons.alarm, 'Frequency', p.frequency),
                      ),
                      Expanded(
                        child: _detailTile(
                            Icons.timelapse, 'Duration', p.duration),
                      ),
                    ],
                  ),
                  if (p.diagnosis != null && p.diagnosis!.isNotEmpty) ...[
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.healing,
                            size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Diagnosis: ${p.diagnosis}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (p.instructions != null && p.instructions!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Instructions: ${p.instructions}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. Digital Seal & Doctor Signature Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 12, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'SECURE DIGITAL PRESCRIPTION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Valid across all certified pharmacies',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Dr. $doctorName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF0D4F8B),
                      ),
                    ),
                    Container(
                      width: 140,
                      height: 1,
                      color: Colors.grey.shade400,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                    Text(
                      'Authorized Signature',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF0D4F8B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Convert boundary to image bytes and trigger file download
  static Future<void> downloadPrescriptionImage({
    required BuildContext context,
    required GlobalKey boundaryKey,
    required Prescription prescription,
    required String format, // 'png' or 'jpg'
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Prescription rendering is not ready yet.');
      }

      // Render at 3.0 pixel ratio for ultra-crisp print quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate image bytes.');
      }

      final bytes = byteData.buffer.asUint8List();
      final ext = format.toLowerCase().contains('jpg') ? 'jpg' : 'png';
      final cleanMedName = prescription.medicineName
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filename =
          'prescription_${prescription.id ?? 'rx'}_$cleanMedName.$ext';

      await downloadImageFile(bytes, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescription downloaded: $filename'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download prescription: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Show interactive dialog with the full slip and download buttons
  static void showSlipDialog(BuildContext context, Prescription prescription) {
    final GlobalKey dialogBoundaryKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prescription Slip Card
                  DigitalPrescriptionSlip(
                    prescription: prescription,
                    boundaryKey: dialogBoundaryKey,
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download JPG'),
                          onPressed: () {
                            downloadPrescriptionImage(
                              context: ctx,
                              boundaryKey: dialogBoundaryKey,
                              prescription: prescription,
                              format: 'jpg',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D4F8B),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download PNG'),
                          onPressed: () {
                            downloadPrescriptionImage(
                              context: ctx,
                              boundaryKey: dialogBoundaryKey,
                              prescription: prescription,
                              format: 'png',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

