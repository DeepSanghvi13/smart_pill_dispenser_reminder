import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import '../models/medicine.dart';
import '../models/user_photo.dart';

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
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(UserPhotoAdapter());
    }

    // Open required boxes
    await Hive.openBox<User>('users');
    await Hive.openBox<UserProfile>('profiles');
    await Hive.openBox<Medicine>('medicines');
    await Hive.openBox<UserPhoto>('user_photos');
    await Hive.openBox('settings');
    await Hive.openBox('connections');
    await Hive.openBox('notifications');
    await Hive.openBox('caretakers');
    await Hive.openBox('patients');
    await Hive.openBox('reports');
  }

  Box<User> get usersBox => Hive.box<User>('users');
  Box<UserProfile> get profilesBox => Hive.box<UserProfile>('profiles');
  Box<Medicine> get medicinesBox => Hive.box<Medicine>('medicines');
  Box<UserPhoto> get userPhotosBox => Hive.box<UserPhoto>('user_photos');
  Box get settingsBox => Hive.box('settings');
  Box get connectionsBox => Hive.box('connections');
  Box get notificationsBox => Hive.box('notifications');
  Box get caretakersBox => Hive.box('caretakers');
  Box get patientsBox => Hive.box('patients');
  Box get reportsBox => Hive.box('reports');
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

class UserPhotoAdapter extends TypeAdapter<UserPhoto> {
  @override
  final int typeId = 4;

  @override
  UserPhoto read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return UserPhoto.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, UserPhoto obj) {
    writer.writeMap(obj.toMap());
  }
}

