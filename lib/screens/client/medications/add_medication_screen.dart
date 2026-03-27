import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../../../models/medicine.dart';
import 'barcode_scanner_screen.dart';
import '../../../services/medicine_barcode_lookup_service.dart';
import '../../../services/database_service.dart';
import '../../../services/medicine_scan_service.dart';
import '../../../services/medicine_suggestion_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medicine? medicine; // null = add, not null = edit

  const AddMedicationScreen({super.key, this.medicine});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController dosageController;
  late TextEditingController timeController;
  late TextEditingController conditionController;
  late MedicineCategory selectedCategory;
  DateTime? _expiryDate;
  String? _scannedText;
  String? _imagePath;
  bool _isScanned = false;
  String? _scannedBarcode;
  bool _isScanning = false;
  bool _isBarcodeLookupLoading = false;
  List<String> _suggestions = const [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.medicine?.name ?? '');
    dosageController =
        TextEditingController(text: widget.medicine?.dosage ?? '');
    timeController =
        TextEditingController(text: widget.medicine?.time ?? '');
    conditionController =
        TextEditingController(text: widget.medicine?.healthCondition ?? '');
    selectedCategory = widget.medicine?.category ?? MedicineCategory.tablets;
    _expiryDate = widget.medicine?.expiryDate;
    _scannedText = widget.medicine?.scannedText;
    _imagePath = widget.medicine?.imagePath;
    _isScanned = widget.medicine?.isScanned ?? false;
    _suggestions = MedicineSuggestionService.getSuggestions(conditionController.text);

    conditionController.addListener(() {
      setState(() {
        _suggestions = MedicineSuggestionService.getSuggestions(conditionController.text);
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    timeController.dispose();
    conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        timeController.text = time.format(context);
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _expiryDate = selected;
      });
    }
  }

  Future<void> _scanMedicine() async {
    setState(() => _isScanning = true);
    try {
      final result = await MedicineScanService.scanMedicineFromImage();
      if (result == null) {
        return;
      }

      setState(() {
        if ((result.medicineName ?? '').trim().isNotEmpty) {
          nameController.text = result.medicineName!.trim();
        }
        if ((result.dosage ?? '').trim().isNotEmpty) {
          dosageController.text = result.dosage!.trim();
        }
        _scannedText = result.extractedText;
        _imagePath = result.imagePath;
        _isScanned = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _scanBarcode() async {
    if (_isBarcodeLookupLoading) {
      return;
    }

    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.trim().isEmpty) {
      return;
    }

    setState(() {
      _isBarcodeLookupLoading = true;
      _scannedBarcode = barcode;
    });

    final result = await MedicineBarcodeLookupService.lookupByBarcode(
      barcode,
      cacheReader: _databaseService.getBarcodeLookupCache,
      cacheWriter: (lookup) => _databaseService.upsertBarcodeLookupCache(
        barcode: lookup.barcode,
        name: lookup.name,
        dosage: lookup.dosage,
        category: lookup.category.name,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBarcodeLookupLoading = false;
      if (result != null) {
        nameController.text = result.name;
        dosageController.text = result.dosage;
        selectedCategory = result.category;
      }
    });

    if (!mounted) {
      return;
    }

    final message = result == null
        ? 'Barcode scanned. No medicine match found online.'
        : result.source == BarcodeLookupSource.backendApi
            ? 'Matched from backend drug API: ${result.name}'
        : result.source == BarcodeLookupSource.onlineApi
            ? 'Matched from online drug database: ${result.name}'
            : result.source == BarcodeLookupSource.localCache
                ? 'Loaded from local cache: ${result.name}'
            : 'Matched from local fallback list: ${result.name}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine == null ? 'Add a med' : 'Edit med'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!kIsWeb)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isScanning ? null : _scanMedicine,
                        icon: _isScanning
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.document_scanner),
                        label: Text(_isScanning
                            ? 'Scanning...'
                            : 'Scan image label'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isBarcodeLookupLoading ? null : _scanBarcode,
                        icon: _isBarcodeLookupLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.qr_code_scanner),
                        label: Text(
                          _isBarcodeLookupLoading
                              ? 'Looking up...'
                              : 'Scan barcode',
                        ),
                      ),
                    ),
                  ],
                ),
              if (!kIsWeb) const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: conditionController,
                decoration: const InputDecoration(
                  labelText: 'Health condition (for suggestions)',
                ),
              ),
              const SizedBox(height: 8),

              if (_suggestions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map(
                        (item) => ActionChip(
                          label: Text(item),
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) {
                              nameController.text = item;
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              if (_suggestions.isNotEmpty) const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<MedicineCategory>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Medicine Category',
                  border: OutlineInputBorder(),
                ),
                items: MedicineCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                readOnly: true,
                onTap: _pickExpiryDate,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  suffixIcon: const Icon(Icons.calendar_month),
                  hintText: _expiryDate == null
                      ? 'Select expiry date'
                      : DateFormat.yMMMd().format(_expiryDate!),
                ),
              ),
              const SizedBox(height: 8),

              if (_isScanned && (_scannedText ?? '').trim().isNotEmpty)
                Text(
                  'Scanned details captured successfully.',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              if ((_scannedBarcode ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Barcode: $_scannedBarcode',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(
                        context,
                        Medicine(
                          name: nameController.text,
                          dosage: dosageController.text,
                          time: timeController.text,
                          category: selectedCategory,
                          expiryDate: _expiryDate,
                          isScanned: _isScanned,
                          scannedText: _scannedText,
                          imagePath: _imagePath,
                          healthCondition: conditionController.text.trim().isEmpty
                              ? null
                              : conditionController.text.trim(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    widget.medicine == null ? 'Save' : 'Update',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



