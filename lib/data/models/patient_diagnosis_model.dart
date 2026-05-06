import 'package:app_geriatrico/data/models/employee_model.dart';

class PatientDiagnosis {
  final int id;

  final String diagnosis;
  final String? notes;

  final String? diagnosedAt;

  final Employee? professional;

  const PatientDiagnosis({
    required this.id,
    required this.diagnosis,
    this.notes,
    this.diagnosedAt,
    this.professional,
  });

  factory PatientDiagnosis.fromJson(
    Map<String, dynamic> json,
  ) {
    return PatientDiagnosis(
      id: json['id'],

      diagnosis:
          json['diagnosis'] ?? '',

      notes:
          json['notes'],

      diagnosedAt:
          json['diagnosed_at'],

      professional:
          json['professional'] != null
              ? Employee.fromJson(
                  json[
                      'professional'],
                )
              : null,
    );
  }
}