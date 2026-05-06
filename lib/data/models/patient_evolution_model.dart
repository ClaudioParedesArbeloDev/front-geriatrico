import 'employee_model.dart';

class PatientEvolution {
  final int id;

  final String evolution;

  final String? recordedAt;

  final Employee? professional;

  const PatientEvolution({
    required this.id,
    required this.evolution,
    this.recordedAt,
    this.professional,
  });

  factory PatientEvolution.fromJson(
    Map<String, dynamic> json,
  ) {
    return PatientEvolution(
      id: json['id'],
      evolution:
          json['evolution'] ?? '',
      recordedAt:
          json['recorded_at'],
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