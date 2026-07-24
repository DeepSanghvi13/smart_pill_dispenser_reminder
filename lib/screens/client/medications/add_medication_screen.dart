import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/medicine.dart';
import '../../../screens/client/medications/barcode_scanner_screen.dart';
import '../../../services/medicine_barcode_lookup_service.dart';
import '../../../services/database_service.dart';
import '../../../services/medicine_scan_service.dart';
import '../../../services/medicine_suggestion_service.dart';
import '../../../services/auth_service.dart';

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
  late TextEditingController quantityController;
  late TextEditingController timeController;
  late TextEditingController conditionController;
  late TextEditingController notesController;
  late TextEditingController startDateController;
  late TextEditingController endDateController;

  late MedicineCategory selectedCategory;
  String selectedFrequency = 'Daily';
  DateTime? _startDate;
  DateTime? _endDate;

  String? _scannedText;
  String? _imagePath;
  bool _isScanned = false;
  String? _scannedBarcode;
  bool _isScanning = false;
  bool _isBarcodeLookupLoading = false;
  List<String> _suggestions = const [];
  final DatabaseService _databaseService = DatabaseService();

  final List<String> _frequencies = ['Daily', 'Twice a day', 'Three times a day', 'Weekly', 'As needed'];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.medicine?.name ?? '');
    dosageController = TextEditingController(text: widget.medicine?.dosage ?? '');
    quantityController = TextEditingController(text: widget.medicine?.quantity ?? '1');
    timeController = TextEditingController(text: widget.medicine?.time ?? '');
    conditionController = TextEditingController(text: widget.medicine?.healthCondition ?? '');
    notesController = TextEditingController(text: widget.medicine?.notes ?? '');

    selectedCategory = widget.medicine?.category ?? MedicineCategory.tablets;
    selectedFrequency = _frequencies.contains(widget.medicine?.frequency) 
        ? widget.medicine!.frequency 
        : 'Daily';
        
    _startDate = widget.medicine?.startDate ?? DateTime.now();
    _endDate = widget.medicine?.endDate ?? DateTime.now().add(const Duration(days: 30));

    startDateController = TextEditingController(text: DateFormat.yMMMd().format(_startDate!));
    endDateController = TextEditingController(text: DateFormat.yMMMd().format(_endDate!));

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
    quantityController.dispose();
    timeController.dispose();
    conditionController.dispose();
    notesController.dispose();
    startDateController.dispose();
    endDateController.dispose();
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

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _startDate = selected;
        startDateController.text = DateFormat.yMMMd().format(selected);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _endDate = selected;
        endDateController.text = DateFormat.yMMMd().format(selected);
      });
    }
  }

  Future<void> _scanMedicine() async {
    setState(() => _isScanning = true);
    try {
      final result = await MedicineScanService.scanMedicineFromImage();
      if (result == null) return;

      setState(() {
        if ((result.medicineName ?? '').trim().isNotEmpty) {
          nameController.text = result.medicineName!.trim();
        }
        if ((result.dosage ?? '').trim().isNotEmpty) {
          dosageController.text = result.dosage!.trim();
        }
        if (result.expiryDate != null) {
          _endDate = result.expiryDate;
          endDateController.text = DateFormat.yMMMd().format(_endDate!);
        }
        if ((result.healthCondition ?? '').trim().isNotEmpty) {
          conditionController.text = result.healthCondition!.trim();
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
    if (_isBarcodeLookupLoading) return;

    String? barcode;
    try {
      barcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open scanner: $e')),
        );
      }
      return;
    }

    if (barcode == null || barcode.trim().isEmpty) return;

    setState(() {
      _isBarcodeLookupLoading = true;
      _scannedBarcode = barcode;
    });

    BarcodeLookupResult? result;
    try {
      result = await MedicineBarcodeLookupService.lookupByBarcode(
        barcode,
        cacheReader: _databaseService.getBarcodeLookupCache,
        cacheWriter: (lookup) => _databaseService.upsertBarcodeLookupCache(
          barcode: lookup.barcode,
          name: lookup.name,
          dosage: lookup.dosage,
          category: lookup.category.name,
          expiryDate: lookup.expiryDate,
          healthCondition: lookup.healthCondition,
        ),
        backendOnly: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Barcode lookup failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBarcodeLookupLoading = false;
          if (result != null) {
            final resolved = result;
            nameController.text = resolved.name;
            dosageController.text = resolved.dosage;
            selectedCategory = resolved.category;
            if (resolved.expiryDate != null) {
              _endDate = resolved.expiryDate;
              endDateController.text = DateFormat.yMMMd().format(_endDate!);
            }
            if ((resolved.healthCondition ?? '').trim().isNotEmpty) {
              conditionController.text = resolved.healthCondition!.trim();
            }
          }
        });
      }
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final userId = auth.currentUser ?? 'guest';

    final medicine = Medicine(
      id: widget.medicine?.id,
      userId: userId,
      name: nameController.text.trim(),
      type: selectedCategory.name,
      dosage: dosageController.text.trim(),
      quantity: quantityController.text.trim(),
      frequency: selectedFrequency,
      time: timeController.text.trim(),
      startDate: _startDate ?? DateTime.now(),
      endDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      isScanned: _isScanned,
      scannedText: _scannedText,
      imagePath: _imagePath,
      healthCondition: conditionController.text.trim().isEmpty ? null : conditionController.text.trim(),
      status: widget.medicine?.status ?? 'pending',
      lastActionDate: widget.medicine?.lastActionDate,
    );

    if (_scannedBarcode != null && _scannedBarcode!.isNotEmpty) {
      _databaseService.upsertBarcodeLookupCache(
        barcode: _scannedBarcode!,
        name: nameController.text.trim(),
        dosage: dosageController.text.trim(),
        category: selectedCategory.name,
        expiryDate: _endDate,
        healthCondition: conditionController.text.trim().isEmpty ? null : conditionController.text.trim(),
      );
    }

    Navigator.pop(context, medicine);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine == null ? 'Add Medication' : 'Edit Medication'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
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
                        label: Text(_isScanning ? 'Scanning...' : 'Scan Label'),
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
                        label: Text(_isBarcodeLookupLoading ? 'Looking up...' : 'Scan Barcode'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Card containing Fields
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Dosage & Quantity
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: dosageController,
                              decoration: const InputDecoration(
                                labelText: 'Dosage (e.g. 500mg)',
                                prefixIcon: Icon(Icons.scale),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity (e.g. 1 pill)',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category (Type)
                      DropdownButtonFormField<MedicineCategory>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: MedicineCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Frequency
                      DropdownButtonFormField<String>(
                        value: selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: _frequencies.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(freq),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedFrequency = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Scheduled Time
                      TextFormField(
                        controller: timeController,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: const InputDecoration(
                          labelText: 'Reminder Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please pick a time' : null,
                      ),
                      const SizedBox(height: 16),

                      // Start & End Dates
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: startDateController,
                              readOnly: true,
                              onTap: _pickStartDate,
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: endDateController,
                              readOnly: true,
                              onTap: _pickEndDate,
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.calendar_month),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Health Condition (OCR Suggestions helper)
                      TextFormField(
                        controller: conditionController,
                        decoration: const InputDecoration(
                          labelText: 'Health Condition (for suggestions)',
                          prefixIcon: Icon(Icons.healing),
                        ),
                      ),
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestions.map((item) {
                            return ActionChip(
                              label: Text(item),
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) {
                                  nameController.text = item;
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Instructions',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _onSave,
                child: Text(
                  widget.medicine == null ? 'Save Medicine' : 'Update Medicine',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
