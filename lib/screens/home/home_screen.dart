import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav.dart';
import '../medications/add_medication_screen.dart';
import '../updates/updates_screen.dart';
import '../medications/medications_screen.dart';
import '../manage/manage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // ✅ SINGLE SOURCE OF TRUTH
  final List<Medicine> _medicines = [];

  Future<void> _addMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );

    if (result != null && result is Medicine) {
      setState(() {
        _medicines.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeBody(
        medicines: _medicines,
        onAddMed: _addMedicine,
      ),
      const UpdatesScreen(),
      MedicationsScreen(
        medicines: _medicines,
        onAddMed: _addMedicine,
      ),
      const ManageScreen(),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Guest'),
        actions: const [Icon(Icons.notifications_active)],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNav(
        index: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/* ---------------- HOME BODY ---------------- */

class HomeBody extends StatelessWidget {
  final List<Medicine> medicines;
  final VoidCallback onAddMed;

  const HomeBody({
    super.key,
    required this.medicines,
    required this.onAddMed,
  });

  @override
  Widget build(BuildContext context) {
    if (medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 120),
            const SizedBox(height: 20),
            const Text(
              'No medicines added',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAddMed,
              child: const Text('Add a med'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final med = medicines[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.medication),
            title: Text(med.name),
            subtitle: Text('${med.dosage} • ${med.time}'),
          ),
        );
      },
    );
  }
}
