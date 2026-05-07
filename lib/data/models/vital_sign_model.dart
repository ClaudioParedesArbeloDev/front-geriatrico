import 'package:app_geriatrico/data/models/employee_model.dart';

class VitalSign {
  final int id;
  final int patientId;

  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final double? temperature;
  final double? oxygenSaturation;
  final int? bloodGlucose;
  final double? weight;
  final int? respiratoryRate;

  final String? notes;
  final String? recordedAt;

  final Employee? registeredBy;

  const VitalSign({
    required this.id,
    required this.patientId,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperature,
    this.oxygenSaturation,
    this.bloodGlucose,
    this.weight,
    this.respiratoryRate,
    this.notes,
    this.recordedAt,
    this.registeredBy,
  });

  /// Devuelve "120/80" o null si no hay presión cargada.
  String? get bloodPressure {
    if (bloodPressureSystolic != null && bloodPressureDiastolic != null) {
      return '$bloodPressureSystolic/$bloodPressureDiastolic';
    }
    return null;
  }

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'],
      patientId: json['patient_id'],
      bloodPressureSystolic:  json['blood_pressure_systolic'],
      bloodPressureDiastolic: json['blood_pressure_diastolic'],
      heartRate:         json['heart_rate'],
      temperature:       (json['temperature'] as num?)?.toDouble(),
      oxygenSaturation:  (json['oxygen_saturation'] as num?)?.toDouble(),
      bloodGlucose:      json['blood_glucose'],
      weight:            (json['weight'] as num?)?.toDouble(),
      respiratoryRate:   json['respiratory_rate'],
      notes:             json['notes'],
      recordedAt:        json['recorded_at'],
      registeredBy: json['registered_by'] != null
          ? Employee.fromJson(json['registered_by'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        if (bloodPressureSystolic != null)
          'blood_pressure_systolic': bloodPressureSystolic,
        if (bloodPressureDiastolic != null)
          'blood_pressure_diastolic': bloodPressureDiastolic,
        if (heartRate != null)        'heart_rate': heartRate,
        if (temperature != null)      'temperature': temperature,
        if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
        if (bloodGlucose != null)     'blood_glucose': bloodGlucose,
        if (weight != null)           'weight': weight,
        if (respiratoryRate != null)  'respiratory_rate': respiratoryRate,
        if (notes != null)            'notes': notes,
        if (recordedAt != null)       'recorded_at': recordedAt,
      };
}
