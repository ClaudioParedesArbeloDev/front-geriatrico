class Cie10Code {
  final int id;
  final String code;
  final String description;

  const Cie10Code({
    required this.id,
    required this.code,
    required this.description,
  });

  factory Cie10Code.fromJson(Map<String, dynamic> json) => Cie10Code(
        id:          json['id'] as int,
        code:        json['code'] as String,
        description: json['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'code':        code,
        'description': description,
      };

 
  String get display => '$code — $description';

  @override
  bool operator ==(Object other) => other is Cie10Code && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
