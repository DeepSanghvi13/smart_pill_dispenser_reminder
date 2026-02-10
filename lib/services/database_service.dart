import '../models/medicine_model.dart';

class DatabaseService {

  static List<Medicine> medicines = [
    Medicine(name: "Vitamin D", time: "08:00 AM"),
    Medicine(name: "Antibiotic", time: "01:00 PM"),
  ];

  List<Medicine> getMedicines() {
    return medicines;
  }

  void addMedicine(Medicine medicine) {
    medicines.add(medicine);
  }

  void toggleMedicineStatus(Medicine medicine) {
    medicine.taken = !medicine.taken;
  }

}
