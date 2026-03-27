class ProfessionalReviewRequest {
  final String patientName;
  final String contact;
  final String concern;
  final String? preferredHospital;
  final String urgency;

  const ProfessionalReviewRequest({
    required this.patientName,
    required this.contact,
    required this.concern,
    required this.urgency,
    this.preferredHospital,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientName': patientName,
      'contact': contact,
      'concern': concern,
      'preferredHospital': preferredHospital,
      'urgency': urgency,
    };
  }
}


