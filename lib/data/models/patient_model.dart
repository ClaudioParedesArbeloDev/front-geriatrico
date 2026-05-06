import 'package:app_geriatrico/data/models/patient_contact_model.dart';

class Patient {
  final int id;
  final String firstName;
  final String lastName;
  final String dni;
  final String? birthDate;
  final String gender;
  final String? bloodType;
  final String? admissionDate;

  final String mobilityStatus;
  final String dependencyLevel;

  final String? emergencyPhone;
  final String? notes;
  final String status;

  final List<PatientContact> contacts;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dni,
    this.birthDate,
    required this.gender,
    this.bloodType,
    this.admissionDate,
    required this.mobilityStatus,
    required this.dependencyLevel,
    this.emergencyPhone,
    this.notes,
    required this.status,
    required this.contacts,
  });

  String get fullName =>
      '$firstName $lastName';

  factory Patient.fromJson(
    Map<String, dynamic> json,
  ) {
    return Patient(
      id: json['id'],
      firstName:
          json['first_name'] ?? '',
      lastName:
          json['last_name'] ?? '',
      dni: json['dni'] ?? '',
      birthDate:
          json['birth_date'],
      gender:
          json['gender'] ?? '',
      bloodType:
          json['blood_type'],
      admissionDate:
          json['admission_date'],
      mobilityStatus:
          json['mobility_status'] ?? '',
      dependencyLevel:
          json['dependency_level'] ?? '',
      emergencyPhone:
          json['emergency_phone'],
      notes:
          json['notes'],
      status:
          json['status'] ?? '',
      contacts:
          (json['contacts']
                      as List<dynamic>? ??
                  [])
              .map(
                (c) =>
                    PatientContact
                        .fromJson(c),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'dni': dni,
      'birth_date': birthDate,
      'gender': gender,
      'blood_type': bloodType,
      'admission_date':
          admissionDate,
      'mobility_status':
          mobilityStatus,
      'dependency_level':
          dependencyLevel,
      'emergency_phone':
          emergencyPhone,
      'notes': notes,
      'status': status,
    };
  }
}