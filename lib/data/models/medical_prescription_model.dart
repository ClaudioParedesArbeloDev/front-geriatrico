import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/models/medication_model.dart';

class MedicalPrescription {
  final int id;

  final String dose;
  final String frequency;

  final String? route;
  final String? instructions;

  final Medication? medication;
  final Employee? professional;

  const MedicalPrescription({
    required this.id,
    required this.dose,
    required this.frequency,
    this.route,
    this.instructions,
    this.medication,
    this.professional,
  });

  factory MedicalPrescription.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicalPrescription(
      id: json['id'],

      dose:
          json['dose'] ?? '',

      frequency:
          json['frequency'] ?? '',

      route:
          json['route'],

      instructions:
          json['instructions'],

      medication:
          json['medication'] != null
              ? Medication.fromJson(
                  json[
                      'medication'],
                )
              : null,

      professional:
          json['professional'] != null
              ? Employee.fromJson(
                  json[
                      'professional'],
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dose': dose,
      'frequency': frequency,
      'route': route,
      'instructions': instructions,
    };
  }
}