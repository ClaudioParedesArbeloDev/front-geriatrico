class Allergy {
  final int id;
  final String name;
  final String? description;

  
  final String? severity; 
  final String? reaction;

  const Allergy({
    required this.id,
    required this.name,
    this.description,
    this.severity,
    this.reaction,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>?;
    return Allergy(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      severity: pivot?['severity'],
      reaction: pivot?['reaction'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
      };

  String get severityLabel => switch (severity) {
        'mild'     => 'Leve',
        'moderate' => 'Moderada',
        'severe'   => 'Grave',
        _          => severity ?? '',
      };
}
