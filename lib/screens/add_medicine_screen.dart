import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {

  final Medicine? medicine;

  const AddMedicineScreen({super.key,this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {

  final nameController = TextEditingController();
  final dosageController = TextEditingController();
  final timeController = TextEditingController();

  @override
  void initState(){
    super.initState();

    if(widget.medicine!=null){
      nameController.text = widget.medicine!.name;
      dosageController.text = widget.medicine!.dosage;
      timeController.text = widget.medicine!.time;
    }
  }

  Future<void> save() async{

    if(widget.medicine!=null){

      await NotificationService.cancelNotification(
          widget.medicine!.notificationId);
    }

    Medicine med = Medicine(
      id: widget.medicine?.id ??
          DateTime.now().millisecondsSinceEpoch,
      name: nameController.text,
      dosage: dosageController.text,
      time: timeController.text,
    );

    int newId =
    await NotificationService.scheduleNotification(med);

    med.notificationId = newId;

    if(widget.medicine==null){
      await DatabaseService().insertMedicine(med);
    }else{
      await DatabaseService().updateMedicine(med);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine==null?"Add":"Edit"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:[

            TextField(controller:nameController),
            TextField(controller:dosageController),
            TextField(controller:timeController),

            const SizedBox(height:20),

            ElevatedButton(
              onPressed: save,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
