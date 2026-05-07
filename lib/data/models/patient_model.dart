import 'package:app_geriatrico/data/models/allergy_model.dart';
import 'package:app_geriatrico/data/models/patient_bed_assignment_model.dart';
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
  final String? obraSocial;
  final String? numeroAfiliado;
  final String? notes;
  final String status;

  final List<PatientContact> contacts;
  final List<Allergy> allergies;
  final PatientBedAssignment? currentBedAssignment;

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
    this.obraSocial,
    this.numeroAfiliado,
    this.notes,
    required this.status,
    this.contacts = const [],
    this.allergies = const [],
    this.currentBedAssignment,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  String get mobilityStatusLabel => switch (mobilityStatus) {
        'normal'      => 'Normal',
        'reduced'     => 'Reducida',
        'wheelchair'  => 'Silla de ruedas',
        'bedridden'   => 'Postrado',
        _             => mobilityStatus,
      };

  String get dependencyLevelLabel => switch (dependencyLevel) {
        'low'    => 'Bajo',
        'medium' => 'Medio',
        'high'   => 'Alto',
        _        => dependencyLevel,
      };

  String get statusLabel => switch (status) {
        'active'   => 'Activo',
        'inactive' => 'Inactivo',
        'deceased' => 'Fallecido',
        _          => status,
      };

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id:               json['id'],
      firstName:        json['first_name'] ?? '',
      lastName:         json['last_name'] ?? '',
      dni:              json['dni'] ?? '',
      birthDate:        json['birth_date'],
      gender:           json['gender'] ?? '',
      bloodType:        json['blood_type'],
      admissionDate:    json['admission_date'],
      mobilityStatus:   json['mobility_status'] ?? 'normal',
      dependencyLevel:  json['dependency_level'] ?? 'low',
      emergencyPhone:   json['emergency_phone'],
      obraSocial:       json['obra_social'],
      numeroAfiliado:   json['numero_afiliado'],
      notes:            json['notes'],
      status:           json['status'] ?? 'active',
      contacts: (json['contacts'] as List<dynamic>? ?? [])
          .map((c) => PatientContact.fromJson(c))
          .toList(),
      allergies: (json['allergies'] as List<dynamic>? ?? [])
          .map((a) => Allergy.fromJson(a))
          .toList(),
      currentBedAssignment: json['current_bed_assignment'] != null
          ? PatientBedAssignment.fromJson(json['current_bed_assignment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name':       firstName,
        'last_name':        lastName,
        'dni':              dni,
        if (birthDate != null)       'birth_date':       birthDate,
        'gender':           gender,
        if (bloodType != null)       'blood_type':       bloodType,
        if (admissionDate != null)   'admission_date':   admissionDate,
        'mobility_status':  mobilityStatus,
        'dependency_level': dependencyLevel,
        if (emergencyPhone != null)  'emergency_phone':  emergencyPhone,
        if (obraSocial != null)      'obra_social':      obraSocial,
        if (numeroAfiliado != null)  'numero_afiliado':  numeroAfiliado,
        if (notes != null)           'notes':            notes,
        'status':           status,
      };
}
