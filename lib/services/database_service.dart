class DatabaseService {

  static List<Map<String,dynamic>> fakeDB = [];

  Future<List<Map<String,dynamic>>> getMedicines() async{
    return fakeDB;
  }

  Future<void> insertMedicine(medicine) async{
    fakeDB.add(medicine.toMap());
  }

  Future<void> updateMedicine(medicine) async{
    int index = fakeDB.indexWhere((m)=>m['id']==medicine.id);
    if(index!=-1){
      fakeDB[index]=medicine.toMap();
    }
  }

  Future<void> deleteMedicine(int id) async{
    fakeDB.removeWhere((m)=>m['id']==id);
  }
}
