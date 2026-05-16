import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/medicine.dart';

class ExpiryCalendarScreen extends StatefulWidget {
  final List<Medicine> medicines;

  const ExpiryCalendarScreen({super.key, required this.medicines});

  @override
  State<ExpiryCalendarScreen> createState() => _ExpiryCalendarScreenState();
}

class _ExpiryCalendarScreenState extends State<ExpiryCalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  List<Medicine> _forDate(DateTime date) {
    return widget.medicines.where((medicine) {
      final expiry = medicine.expiryDate;
      if (expiry == null) return false;
      return expiry.year == date.year &&
          expiry.month == date.month &&
          expiry.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final medicinesOnDate = _forDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Expiry Calendar')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            onDateChanged: (value) {
              setState(() => _selectedDate = value);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: medicinesOnDate.isEmpty
                ? const Center(
                    child: Text('No medicine expires on selected date.'),
                  )
                : ListView.builder(
                    itemCount: medicinesOnDate.length,
                    itemBuilder: (context, index) {
                      final medicine = medicinesOnDate[index];
                      final expiry = medicine.expiryDate!;

                      return ListTile(
                        leading: const Icon(Icons.event_busy, color: Colors.red),
                        title: Text(medicine.name),
                        subtitle: Text(
                          'Expires: ${DateFormat.yMMMd().format(expiry)} • ${medicine.dosage}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}




