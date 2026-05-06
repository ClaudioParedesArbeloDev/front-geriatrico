import 'package:app_geriatrico/data/models/role_model.dart';
import 'package:app_geriatrico/data/models/specialty_model.dart';

class Employee {
  final int id;
  final String name;
  final String? lastName;
  final String? dni;
  final String? birthDate;
  final String email;
  final String? phone;
  final String? address;
  final String? employeeCode;
  final String? licenseNumber;
  final String? hireDate;
  final String? avatar;
  final bool isActive;
  final List<Role> roles;
  final List<Specialty> specialties;

  const Employee({
    required this.id,
    required this.name,
    this.lastName,
    this.dni,
    this.birthDate,
    required this.email,
    this.phone,
    this.address,
    this.employeeCode,
    this.licenseNumber,
    this.hireDate,
    this.avatar,
    required this.isActive,
    required this.roles,
    required this.specialties,
  });

  String get fullName => '$name $lastName';

  String get initials {
    final f = name.isNotEmpty ? name[0].toUpperCase() : '';
    final l = (lastName?.isNotEmpty ?? false) ? lastName![0].toUpperCase() : '';
    return '$f$l';
  }

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as int,
        name: (json['name'] as String?) ?? '',
        lastName: (json['last_name'] as String?) ?? '',
        dni: json['dni'] as String?,
        birthDate: json['birth_date'] as String?,
        email: (json['email'] as String?) ?? '',
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        employeeCode: json['employee_code'] as String?,
        licenseNumber: json['license_number'] as String?,
        hireDate: json['hire_date'] as String?,
        avatar: json['avatar'] as String?,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((r) => Role.fromJson(r as Map<String, dynamic>))
            .toList(),
        specialties: (json['specialties'] as List<dynamic>? ?? [])
            .map((s) => Specialty.fromJson(s as Map<String, dynamic>,),)
            .toList(),
      );

 Employee copyWith({
  String? name,
  String? lastName,
  String? dni,
  String? birthDate,
  String? email,
  String? phone,
  String? address,
  String? employeeCode,
  String? licenseNumber,
  String? hireDate,
  String? avatar,
  bool? isActive,
  List<Role>? roles,
  List<Specialty>? specialties,
}) =>
    Employee(
      id: id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      dni: dni ?? this.dni,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      employeeCode: employeeCode ?? this.employeeCode,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      hireDate: hireDate ?? this.hireDate,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
      specialties: specialties ?? this.specialties,
    );

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'last_name': lastName,
        'dni': dni,
        'birth_date': birthDate,
        'email': email,
        'phone': phone,
        'address': address,
        'employee_code': employeeCode,
        'license_number': licenseNumber,
        'hire_date': hireDate,
        'is_active': isActive,
      };
}