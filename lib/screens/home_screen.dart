import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/medicine.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<Map<String,dynamic>> medicines=[];

  @override
  void initState(){
    super.initState();
    load();
  }

  Future<void> load() async{
    medicines = await DatabaseService().getMedicines();
    setState(() {});
  }

  Future<void> deleteMedicine(Map medicine) async{

    await NotificationService.cancelNotification(
        medicine['notification_id']);

    await DatabaseService().deleteMedicine(medicine['id']);

    load();
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(title: const Text("Smart Pill Reminder")),

      body: medicines.isEmpty
          ? const Center(child: Text("No medicines added"))
          : ListView.builder(
        itemCount: medicines.length,
        itemBuilder:(context,index){

          final medicine=medicines[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(

              leading: const CircleAvatar(
                child: Icon(Icons.medication),
              ),

              title: Text(medicine['medicine_name']),
              subtitle: Text(
                  "${medicine['dosage']} • ${medicine['reminder_time']}"),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children:[

                  IconButton(
                    icon: const Icon(Icons.edit,color: Colors.blue),
                    onPressed: () async{

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_)=>AddMedicineScreen(
                            medicine: Medicine.fromMap(medicine),
                          ),
                        ),
                      );

                      load();
                    },
                  ),

                  IconButton(
                    icon: const Icon(Icons.delete,color: Colors.red),
                    onPressed: ()=>deleteMedicine(medicine),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async{

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_)=>const AddMedicineScreen(),
            ),
          );

          load();
        },
      ),
    );
  }
}
