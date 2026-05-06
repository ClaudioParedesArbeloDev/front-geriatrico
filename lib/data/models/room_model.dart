class Room {
  final int id;
  final String number;
  final String? name;
  final String? floor;
  final int capacity;
  final String type;   // 'private' | 'shared'
  final String status; // 'available' | 'maintenance' | 'inactive'

  const Room({
    required this.id,
    required this.number,
    this.name,
    this.floor,
    required this.capacity,
    this.type = 'shared',
    this.status = 'available',
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      number: json['number'] ?? '',
      name: json['name'],
      floor: json['floor']?.toString(),
      capacity: json['capacity'] ?? 1,
      type: json['type'] ?? 'shared',
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (floor != null && floor!.isNotEmpty) 'floor': int.tryParse(floor!),
      'capacity': capacity,
      'type': type,
      'status': status,
    };
  }

  Room copyWith({
    int? id,
    String? number,
    String? name,
    String? floor,
    int? capacity,
    String? type,
    String? status,
  }) {
    return Room(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}