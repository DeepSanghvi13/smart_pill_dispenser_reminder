import 'package:flutter/material.dart';
import 'package:smart_pill_reminder/models/medicine.dart';
import 'package:smart_pill_reminder/models/reminder.dart';
import 'package:smart_pill_reminder/services/database_service.dart';

class AddReminderScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final Reminder? reminder;

  const AddReminderScreen({
    super.key,
    required this.medicines,
    this.reminder,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  late Medicine selectedMedicine;
  late TimeOfDay reminderTime;
  late Set<String> selectedDays;
  bool isActive = true;
  bool _isSaving = false;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();

    if (widget.reminder != null) {
      // Edit mode
      selectedMedicine = widget.medicines.firstWhere(
        (m) => m.id == widget.reminder!.medicineId,
        orElse: () => widget.medicines.first,
      );
      reminderTime = TimeOfDay(hour: 9, minute: 0);
      selectedDays = Set.from(widget.reminder!.daysOfWeek);
      isActive = widget.reminder!.isActive;
    } else {
      // Add mode
      selectedMedicine = widget.medicines.first;
      reminderTime = const TimeOfDay(hour: 9, minute: 0);
      selectedDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'};
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );
    if (picked != null) {
      setState(() => reminderTime = picked);
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (selectedDays.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final reminder = Reminder(
        id: widget.reminder?.id,
        medicineId: selectedMedicine.id ?? 0,
        medicineName: selectedMedicine.name,
        time:
            '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
        daysOfWeek: selectedDays.toList(),
        isActive: isActive,
      );

      if (widget.reminder != null && widget.reminder!.id != null) {
        await _dbService.updateReminder(widget.reminder!.id!, reminder);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Reminder updated successfully!')),
        );
      } else {
        await _dbService.addReminder(reminder);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Reminder added successfully!')),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Medicine
            const Text('Medicine',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButton<Medicine>(
              isExpanded: true,
              value: selectedMedicine,
              items: widget.medicines
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (m) {
                if (m != null) setState(() => selectedMedicine = m);
              },
            ),
            const SizedBox(height: 24),

            // Select Time
            const Text('Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),

            // Select Days
            const Text('Days',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days
                  .map(
                    (day) => FilterChip(
                      label: Text(day),
                      selected: selectedDays.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Active Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D4F8B),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        widget.reminder == null
                            ? 'Add Reminder'
                            : 'Update Reminder',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
