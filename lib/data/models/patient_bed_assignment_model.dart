import 'package:app_geriatrico/data/models/bed_model.dart';

class PatientBedAssignment {
  final int id;
  final int patientId;
  final int bedId;
  final Bed? bed;
  final String? assignedAt;
  final String? releasedAt;

  const PatientBedAssignment({
    required this.id,
    required this.patientId,
    required this.bedId,
    this.bed,
    this.assignedAt,
    this.releasedAt,
  });

  bool get isActive => releasedAt == null;

  factory PatientBedAssignment.fromJson(Map<String, dynamic> json) {
    return PatientBedAssignment(
      id: json['id'],
      patientId: json['patient_id'],
      bedId: json['bed_id'],
      bed: json['bed'] != null ? Bed.fromJson(json['bed']) : null,
      assignedAt: json['assigned_at'],
      releasedAt: json['released_at'],
    );
  }
}
