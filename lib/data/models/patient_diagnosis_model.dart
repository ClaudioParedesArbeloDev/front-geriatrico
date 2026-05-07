import 'package:app_geriatrico/data/models/employee_model.dart';

class PatientDiagnosis {
  final int id;
  final String diagnosis;
  final String? cie10Code;
  final String? cie10Label;
  final String? notes;
  final String? diagnosedAt;
  final Employee? professional;

  const PatientDiagnosis({
    required this.id,
    required this.diagnosis,
    this.cie10Code,
    this.cie10Label,
    this.notes,
    this.diagnosedAt,
    this.professional,
  });

  /// Muestra el código CIE-10 y descripción juntos si existen.
  String? get cie10Display {
    if (cie10Code == null) return null;
    if (cie10Label != null) return '$cie10Code — $cie10Label';
    return cie10Code;
  }

  factory PatientDiagnosis.fromJson(Map<String, dynamic> json) {
    return PatientDiagnosis(
      id:          json['id'],
      diagnosis:   json['diagnosis'] ?? '',
      cie10Code:   json['cie10_code'],
      cie10Label:  json['cie10_label'],
      notes:       json['notes'],
      diagnosedAt: json['diagnosed_at'],
      professional: json['professional'] != null
          ? Employee.fromJson(json['professional'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'diagnosis': diagnosis,
        if (cie10Code != null)  'cie10_code':  cie10Code,
        if (cie10Label != null) 'cie10_label': cie10Label,
        if (notes != null)      'notes':       notes,
        if (diagnosedAt != null) 'diagnosed_at': diagnosedAt,
      };
}
