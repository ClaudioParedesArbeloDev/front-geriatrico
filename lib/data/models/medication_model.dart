class Medication {
  final int id;

  final String? code;
  final String name;

  final String? genericName;
  final String? laboratory;
  final String? presentation;

  const Medication({
    required this.id,
    this.code,
    required this.name,
    this.genericName,
    this.laboratory,
    this.presentation,
  });

  factory Medication.fromJson(
    Map<String, dynamic> json,
  ) {
    return Medication(
      id: json['id'],
      code: json['code'],
      name:
          json['name'] ?? '',
      genericName:
          json['generic_name'],
      laboratory:
          json['laboratory'],
      presentation:
          json['presentation'],
    );
  }
}