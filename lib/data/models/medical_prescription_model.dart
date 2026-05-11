import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/models/medication_model.dart';
import 'package:app_geriatrico/data/models/prescription_schedule_model.dart';

class MedicalPrescription {
  final int id;
  final int patientId;
  final String dose;
  final String frequency;
  final String? route;
  final String? instructions;
  final String? startDate;
  final String? endDate;
  final bool isActive;

  final Medication? medication;
  final Employee? professional;
  final List<PrescriptionSchedule> schedules;

  const MedicalPrescription({
    required this.id,
    required this.patientId,
    required this.dose,
    required this.frequency,
    this.route,
    this.instructions,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.medication,
    this.professional,
    this.schedules = const [],
  });

  
  String get schedulesDisplay {
    if (schedules.isEmpty) return frequency;
    return schedules.map((s) => s.scheduledTime).join(' · ');
  }

  factory MedicalPrescription.fromJson(Map<String, dynamic> json) {
    return MedicalPrescription(
      id:           json['id'],
      patientId:    json['patient_id'] ?? 0,
      dose:         json['dose'] ?? '',
      frequency:    json['frequency'] ?? '',
      route:        json['route'],
      instructions: json['instructions'],
      startDate:    json['start_date'],
      endDate:      json['end_date'],
      isActive:     json['is_active'] == true || json['is_active'] == 1,
      medication: json['medication'] != null
          ? Medication.fromJson(json['medication'])
          : null,
      professional: json['professional'] != null
          ? Employee.fromJson(json['professional'])
          : null,
      schedules: (json['schedules'] as List<dynamic>? ?? [])
          .map((s) => PrescriptionSchedule.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'dose':      dose,
        'frequency': frequency,
        if (route != null)        'route':        route,
        if (instructions != null) 'instructions': instructions,
        if (startDate != null)    'start_date':   startDate,
        if (endDate != null)      'end_date':     endDate,
        'is_active': isActive,
      };
}
