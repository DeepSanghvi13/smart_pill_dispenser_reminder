import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class AlarmPopupScreen extends StatelessWidget {

  final String medicineName;

  const AlarmPopupScreen({super.key, required this.medicineName});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.red.shade100,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.alarm, size: 80),

            Text(
              "Time to take:",
              style: TextStyle(fontSize: 22),
            ),

            Text(
              medicineName,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ElevatedButton(
                  child: const Text("Snooze 10 min"),
                  onPressed: () async {

                    await NotificationService.snoozeNotification(
                        medicineName);

                    Navigator.pop(context);
                  },
                ),

                const SizedBox(width: 20),

                ElevatedButton(
                  child: const Text("Taken"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
