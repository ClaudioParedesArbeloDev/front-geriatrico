class Role {
  final int id;
  final String name;
  final String displayName;

  const Role({
    required this.id,
    required this.name,
    required this.displayName,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: json['id'] as int,
        name: json['name'] as String,
        displayName: (json['display_name'] as String?) ?? json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'display_name': displayName,
      };

  @override
  bool operator ==(Object other) => other is Role && other.id == id;

  @override
  int get hashCode => id.hashCode;
}