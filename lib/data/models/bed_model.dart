import 'package:app_geriatrico/data/models/room_model.dart';

class Bed {
  final int id;
  final int roomId;
  final String bedNumber; 
  final String status;   
  final Room? room;

  const Bed({
    required this.id,
    required this.roomId,
    required this.bedNumber,
    this.status = 'available',
    this.room,
  });

  bool get isOccupied => status == 'occupied';

  factory Bed.fromJson(Map<String, dynamic> json) {
    return Bed(
      id: json['id'],
      roomId: json['room_id'],
      bedNumber: json['bed_number'] ?? json['code'] ?? '',
      status: json['status'] ?? 'available',
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'bed_number': bedNumber,
      'status': status,
    };
  }

  Bed copyWith({
    int? id,
    int? roomId,
    String? bedNumber,
    String? status,
    Room? room,
  }) {
    return Bed(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      bedNumber: bedNumber ?? this.bedNumber,
      status: status ?? this.status,
      room: room ?? this.room,
    );
  }
}