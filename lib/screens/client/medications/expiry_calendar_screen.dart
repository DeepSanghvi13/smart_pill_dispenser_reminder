import 'package:flutter/material.dart';
import '../../../models/medicine.dart';
import '../../../core/responsive.dart';

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
      final expiry = medicine.resolvedExpiryDate;
      return expiry.year == date.year &&
          expiry.month == date.month &&
          expiry.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medicinesOnDate = _forDate(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Calendar'),
      ),
      body: Center(
        child: ResponsiveContentWrapper(
          maxWidth: 720,
          child: Column(
            children: [
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              onDateChanged: (value) {
                setState(() => _selectedDate = value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medicines Expiring On Selected Date',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${medicinesOnDate.length}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: medicinesOnDate.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No medicines expiring on this date',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: medicinesOnDate.length,
                    itemBuilder: (context, index) {
                      final medicine = medicinesOnDate[index];

                      Color statusColor;
                      String statusLabel;
                      if (medicine.isExpired) {
                        statusColor = Colors.red;
                        statusLabel = 'Expired';
                      } else if (medicine.isExpiringSoon) {
                        statusColor = Colors.orange;
                        statusLabel = 'Expiring Soon';
                      } else {
                        statusColor = Colors.green;
                        statusLabel = 'Active';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: statusColor.withValues(alpha: 0.3),
                            width: medicine.isExpired ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.12),
                            child: Icon(
                              medicine.isExpired ? Icons.event_busy : Icons.event_note,
                              color: statusColor,
                            ),
                          ),
                          title: Text(
                            medicine.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Expiry: ${medicine.formattedExpiryDate} • Dosage: ${medicine.dosage} (${medicine.time})',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  ),
);
  }
}




