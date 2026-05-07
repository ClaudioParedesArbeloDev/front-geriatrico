class PatientContact {
  final int id;
  final int patientId;
  final String name;
  final String? lastName;
  final String? dni;
  final String? relationship;
  final String phone;
  final String? email;
  final String? address;
  final bool isPrimary;

  const PatientContact({
    required this.id,
    required this.patientId,
    required this.name,
    this.lastName,
    this.dni,
    this.relationship,
    required this.phone,
    this.email,
    this.address,
    this.isPrimary = false,
  });

  String get fullName => lastName != null ? '$name $lastName' : name;

  factory PatientContact.fromJson(Map<String, dynamic> json) {
    return PatientContact(
      id:           json['id'],
      patientId:    json['patient_id'] ?? 0,
      name:         json['name'] ?? '',
      lastName:     json['last_name'],
      dni:          json['dni'],
      relationship: json['relationship'],
      phone:        json['phone'] ?? '',
      email:        json['email'],
      address:      json['address'],
      isPrimary:    json['is_primary'] == true || json['is_primary'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id':   patientId,
        'name':         name,
        if (lastName != null)     'last_name':    lastName,
        if (dni != null)          'dni':          dni,
        if (relationship != null) 'relationship': relationship,
        'phone':        phone,
        if (email != null)        'email':        email,
        if (address != null)      'address':      address,
        'is_primary':   isPrimary,
      };
}
