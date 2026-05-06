class PatientContact {
  final int id;

  final String name;
  final String? lastName;

  final String? dni;
  final String? relationship;

  final String phone;
  final String? email;
  final String? address;

  const PatientContact({
    required this.id,
    required this.name,
    this.lastName,
    this.dni,
    this.relationship,
    required this.phone,
    this.email,
    this.address,
  });

  factory PatientContact.fromJson(
    Map<String, dynamic> json,
  ) {
    return PatientContact(
      id: json['id'],
      name: json['name'] ?? '',
      lastName:
          json['last_name'],
      dni: json['dni'],
      relationship:
          json['relationship'],
      phone:
          json['phone'] ?? '',
      email:
          json['email'],
      address:
          json['address'],
    );
  }
}