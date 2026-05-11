import 'package:app_geriatrico/data/models/employee_model.dart';

class MedicalStudy {
  final int id;
  final String studyType;
  final String? conclusion; 
  final String? filePath;
  final String? performedAt;
  final Employee? professional;

  const MedicalStudy({
    required this.id,
    required this.studyType,
    this.conclusion,
    this.filePath,
    this.performedAt,
    this.professional,
  });

  bool get hasFile => filePath != null && filePath!.isNotEmpty;

  factory MedicalStudy.fromJson(Map<String, dynamic> json) {
    return MedicalStudy(
      id:          json['id'],
      studyType:   json['study_type'] ?? '',
      conclusion:  json['conclusion'],
      filePath:    json['file_path'],
      performedAt: json['performed_at'],
      professional: json['professional'] != null
          ? Employee.fromJson(json['professional'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'study_type':  studyType,
        if (conclusion != null)  'conclusion':  conclusion,
        if (performedAt != null) 'performed_at': performedAt,
      };
}
