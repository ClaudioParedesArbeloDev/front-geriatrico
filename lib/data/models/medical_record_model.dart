class MedicalRecord {
  final int id;
  final int patientId;

  const MedicalRecord({
    required this.id,
    required this.patientId,
  });

  factory MedicalRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patient_id'],
    );
  }
}