class AdminPatientConnection {
  final String type;
  final int id;
  final String patientName;
  final String targetName;
  final String status;

  const AdminPatientConnection({
    required this.type,
    required this.id,
    required this.patientName,
    required this.targetName,
    required this.status,
  });

  factory AdminPatientConnection.fromMap(
      String type, Map<String, dynamic> map) {
    return AdminPatientConnection(
      type: type,
      id: (map['id'] as num?)?.toInt() ?? 0,
      patientName:
          (map['patientName'] ?? map['requesterName'] ?? 'Unknown').toString(),
      targetName: (map['doctorName'] ??
              map['caretakerName'] ??
              map['shopName'] ??
              'Unknown')
          .toString(),
      status: (map['status'] ?? 'Unknown').toString(),
    );
  }
}
