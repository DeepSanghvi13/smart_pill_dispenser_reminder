import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/medicine_card.dart';
import '../models/medicine_model.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<Medicine> medicines = [];

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  void loadMedicines() {
    medicines = DatabaseService().getMedicines();
    setState(() {});
  }

  double calculateProgress() {

    if (medicines.isEmpty) return 0;

    int takenCount =
        medicines.where((m) => m.taken).length;

    return takenCount / medicines.length;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Good Morning 👋"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// 🔥 PRO LEVEL Progress Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

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

              child: Column(
                children: [

                  const Text(
                    "Today's Progress",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      value: calculateProgress(),
                      strokeWidth: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Today",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 Animated List Feeling
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {

                  final m = medicines[index];

                  return MedicineCard(
                    medicine: m,
                    refresh: loadMedicines, // ⭐ VERY IMPORTANT
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () async {

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMedicineScreen(),
            ),
          );

          loadMedicines();
        },
      ),
    );
  }
}
