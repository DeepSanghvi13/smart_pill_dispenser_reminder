import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import '../models/medicine.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register custom hand-written TypeAdapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MedicineAdapter());
    }

    // Open required boxes
    await Hive.openBox<User>('users');
    await Hive.openBox<UserProfile>('profiles');
    await Hive.openBox<Medicine>('medicines');
    await Hive.openBox('settings');
  }

  Box<User> get usersBox => Hive.box<User>('users');
  Box<UserProfile> get profilesBox => Hive.box<UserProfile>('profiles');
  Box<Medicine> get medicinesBox => Hive.box<Medicine>('medicines');
  Box get settingsBox => Hive.box('settings');
}

// Hand-written Hive TypeAdapters (avoids complex code generation setup)
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return User.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeMap(obj.toMap());
  }
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 2;

  @override
  UserProfile read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return UserProfile.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeMap(obj.toMap());
  }
}

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 3;

  @override
  Medicine read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Medicine.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer.writeMap(obj.toMap());
  }
}
