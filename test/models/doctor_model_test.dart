import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pill_reminder/models/doctor_connection.dart';
import 'package:smart_pill_reminder/models/user_profile.dart';

void main() {
  group('DoctorModel Tests', () {
    test('DoctorModel correctly parses from API map', () {
      final map = {
        'id': 12,
        'userId': 4,
        'fullName': 'Dr. Sarah Connor',
        'email': 'sarah.doctor@gmail.com',
        'phoneNumber': '9876543210',
        'specialization': 'Cardiologist',
        'licenseNumber': 'MED-12345',
        'hospitalName': 'City Heart Center',
        'experience': '12 years',
        'location': 'Mumbai, India',
        'profilePicture': 'base64sample',
        'connectionStatus': 'connected',
        'connectionId': 99,
      };

      final doctor = DoctorModel.fromMap(map);
      expect(doctor.id, 12);
      expect(doctor.userId, 4);
      expect(doctor.fullName, 'Dr. Sarah Connor');
      expect(doctor.email, 'sarah.doctor@gmail.com');
      expect(doctor.phoneNumber, '9876543210');
      expect(doctor.specialization, 'Cardiologist');
      expect(doctor.licenseNumber, 'MED-12345');
      expect(doctor.hospitalName, 'City Heart Center');
      expect(doctor.experience, '12 years');
      expect(doctor.location, 'Mumbai, India');
      expect(doctor.connectionStatus, 'connected');
      expect(doctor.connectionId, 99);

      final backToMap = doctor.toMap();
      expect(backToMap['id'], 12);
      expect(backToMap['fullName'], 'Dr. Sarah Connor');
      expect(backToMap['specialization'], 'Cardiologist');
    });

    test('DoctorModel copyWith updates fields correctly', () {
      final doc = DoctorModel(
        fullName: 'Dr. John Doe',
        email: 'john.doctor@gmail.com',
        phoneNumber: '9123456780',
        specialization: 'General Physician',
        licenseNumber: 'DOC-111',
        hospitalName: 'General Hospital',
        experience: '5 years',
        location: 'Delhi',
      );

      final updated = doc.copyWith(
        connectionStatus: 'pending',
        connectionId: 55,
      );

      expect(updated.connectionStatus, 'pending');
      expect(updated.connectionId, 55);
      expect(updated.fullName, 'Dr. John Doe');
    });
  });

  group('DoctorConnectionItem Tests', () {
    test('DoctorConnectionItem parses requester info from map', () {
      final map = {
        'id': 101,
        'doctorId': 15,
        'requesterId': 7,
        'requesterRole': 'patient',
        'requesterName': 'Deep Sanghvi',
        'requesterEmail': 'deep.patient@gmail.com',
        'requesterPhone': '9988776655',
        'requesterPhoto': null,
        'status': 'pending',
        'createdAt': '2026-09-12T10:00:00.000Z',
      };

      final item = DoctorConnectionItem.fromMap(map);
      expect(item.id, 101);
      expect(item.doctorId, 15);
      expect(item.requesterId, 7);
      expect(item.requesterRole, 'patient');
      expect(item.requesterName, 'Deep Sanghvi');
      expect(item.requesterEmail, 'deep.patient@gmail.com');
      expect(item.requesterPhone, '9988776655');
      expect(item.status, 'pending');
    });
  });

  group('UserProfile Doctor Fields Tests', () {
    test('UserProfile handles doctor fields properly', () {
      final profile = UserProfile(
        email: 'doctor.patel@gmail.com',
        fullName: 'Dr. Patel',
        specialization: 'Neurologist',
        licenseNumber: 'LIC-999',
        hospitalName: 'Apex Neuro Clinic',
        experience: '15 years',
        location: 'Bangalore',
      );

      expect(profile.specialization, 'Neurologist');
      expect(profile.licenseNumber, 'LIC-999');
      expect(profile.hospitalName, 'Apex Neuro Clinic');

      final map = profile.toMap();
      final fromMap = UserProfile.fromMap(map);

      expect(fromMap.specialization, 'Neurologist');
      expect(fromMap.licenseNumber, 'LIC-999');
      expect(fromMap.hospitalName, 'Apex Neuro Clinic');
    });
  });
}
