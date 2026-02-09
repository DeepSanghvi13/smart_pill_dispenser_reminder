import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() =>
      _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {

  List medicines=[];

  @override
  void initState(){
    super.initState();
    load();
  }

  Future<void> load() async{
    medicines = await DatabaseService().getMedicines();
    setState(() {});
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Schedule")),

      body: ListView.builder(
        itemCount: medicines.length,
        itemBuilder: (context,index){

          final m = medicines[index];

          return ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(m['medicine_name']),
            subtitle: Text(m['reminder_time']),
          );
        },
      ),
    );
  }
}
