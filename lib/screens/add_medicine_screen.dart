import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/medicine_model.dart';

class AddMedicineScreen extends StatefulWidget {
  @override
  _AddMedicineScreenState createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {

  TextEditingController nameController = TextEditingController();
  TextEditingController timeController = TextEditingController();

  void saveMedicine() {

    DatabaseService().addMedicine(
      Medicine(
        name: nameController.text,
        time: timeController.text,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Add Medicine")),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Medicine Name"),
            ),

            TextField(
              controller: timeController,
              decoration: InputDecoration(labelText: "Time"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveMedicine,
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
