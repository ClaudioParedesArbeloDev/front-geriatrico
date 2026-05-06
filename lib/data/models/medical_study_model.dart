import 'package:app_geriatrico/data/models/employee_model.dart';

class MedicalStudy {
  final int id;

  final String studyType;
  final String conclusion;

  final String? performedAt;

  final Employee? professional;

  const MedicalStudy({
    required this.id,
    required this.studyType,
    required this.conclusion,
    this.performedAt,
    this.professional,
  });

  factory MedicalStudy.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalStudy(
      id: json['id'],

      studyType:
          json['study_type'] ?? '',

      conclusion:
          json['conclusion'] ?? '',

      performedAt:
          json['performed_at'],

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