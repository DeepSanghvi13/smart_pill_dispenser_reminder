import 'package:flutter/material.dart';
import '../models/medicine_model.dart';
import '../services/database_service.dart';

class MedicineCard extends StatefulWidget {

  final Medicine medicine;
  final VoidCallback refresh;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.refresh,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard>
    with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {

    return Dismissible(

      key: UniqueKey(),

      direction: DismissDirection.startToEnd,

      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),

      onDismissed: (direction) {

        DatabaseService()
            .toggleMedicineStatus(widget.medicine);

        widget.refresh();
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),

        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),

        child: Row(
          children: [

            CircleAvatar(
              radius: 24,
              backgroundColor: widget.medicine.taken
                  ? Colors.green.shade200
                  : Colors.green.shade100,

              child: const Icon(Icons.medication),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    widget.medicine.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(widget.medicine.time),

                ],
              ),
            ),

            Icon(
              widget.medicine.taken
                  ? Icons.check_circle
                  : Icons.access_time,
              color: widget.medicine.taken
                  ? Colors.green
                  : Colors.orange,
            )
          ],
        ),
      ),
    );
  }
}

