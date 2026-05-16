import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _handled = false;
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Medicine Barcode')),
      body: MobileScanner(
        controller: _controller,
        errorBuilder: (context, error, child) {
          return Center(
            child: Text(
              'Scanner error: ${error.errorCode}',
              textAlign: TextAlign.center,
            ),
          );
        },
        onDetect: (capture) {
          if (_handled) return;
          final barcode = capture.barcodes.isNotEmpty
              ? capture.barcodes.first.rawValue
              : null;
          if (barcode == null || barcode.trim().isEmpty) {
            return;
          }
          _handled = true;
          Navigator.pop(context, barcode.trim());
        },
      ),
    );
  }
}
