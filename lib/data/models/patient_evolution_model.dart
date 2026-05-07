import 'package:app_geriatrico/data/models/employee_model.dart';

class PatientEvolution {
  final int id;
  final String type;
  final String evolution;
  final String? recordedAt;
  final Employee? professional;

  const PatientEvolution({
    required this.id,
    required this.type,
    required this.evolution,
    this.recordedAt,
    this.professional,
  });

  String get typeLabel => switch (type) {
        'medical'      => 'Médica',
        'nursing'      => 'Enfermería',
        'kinesiology'  => 'Kinesiología',
        'nutrition'    => 'Nutrición',
        'social'       => 'Social',
        'general'      => 'General',
        _              => type,
      };

  factory PatientEvolution.fromJson(Map<String, dynamic> json) {
    return PatientEvolution(
      id:         json['id'],
      type:       json['type'] ?? 'general',
      evolution:  json['evolution'] ?? '',
      recordedAt: json['recorded_at'],
      professional: json['professional'] != null
          ? Employee.fromJson(json['professional'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type':      type,
        'evolution': evolution,
        if (recordedAt != null) 'recorded_at': recordedAt,
      };
}
