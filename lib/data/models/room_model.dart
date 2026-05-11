class Room {
  final int id;
  final String number; 
  final String? name;   
  final String? floor;  
  final int capacity;
  final String type;   
  final String status;  
  final List<RoomBedSummary> beds;

  const Room({
    required this.id,
    required this.number,
    this.name,
    this.floor,
    this.capacity = 1,
    this.type = 'shared',
    this.status = 'available',
    this.beds = const [],
  });

  
  int get totalBeds      => beds.length;
  int get availableBeds  => beds.where((b) => b.status == 'available').length;
  int get occupiedBeds   => beds.where((b) => b.status == 'occupied').length;
  int get maintenanceBeds => beds.where((b) => b.status == 'maintenance').length;

 
  factory Room.fromJson(Map<String, dynamic> json) {
    final rawBeds = json['beds'] as List<dynamic>? ?? [];
    return Room(
      id:       json['id'] as int,
      number:   json['number']?.toString() ?? '',
      name:     json['name'] as String?,
      floor:    json['floor']?.toString(),
      capacity: json['capacity'] as int? ?? 1,
      type:     json['type'] as String? ?? 'shared',
      status:   json['status'] as String? ?? 'available',
      beds:     rawBeds
          .map((b) => RoomBedSummary.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'number':   number,
        if (name != null && name!.isNotEmpty) 'name': name,
        if (floor != null && floor!.isNotEmpty) 'floor': floor,
        'capacity': capacity,
        'type':     type,
        'status':   status,
      };
}


class RoomBedSummary {
  final int id;
  final String number;
  final String status;

  const RoomBedSummary({
    required this.id,
    required this.number,
    required this.status,
  });

  factory RoomBedSummary.fromJson(Map<String, dynamic> json) =>
      RoomBedSummary(
        id:     json['id'] as int,
        number: json['bed_number']?.toString() ??
                json['number']?.toString() ?? '',
        status: json['status'] as String? ?? 'available',
      );
}