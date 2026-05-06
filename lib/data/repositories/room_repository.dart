import 'dart:convert';

import 'package:app_geriatrico/data/models/room_model.dart';
import 'package:app_geriatrico/services/api_services.dart';


class RoomRepository {
  final ApiService api;

  RoomRepository(
    this.api,
  );

  Future<List<Room>> getAll() async {
    final response =
        await api.get('/rooms');

    final List data =
        jsonDecode(response.body);

    return data
        .map(
          (e) => Room.fromJson(e),
        )
        .toList();
  }

  Future<void> create(
    Room room,
  ) async {
    await api.post(
      '/rooms',
      room.toJson(),
    );
  }

  Future<void> update(
    Room room,
  ) async {
    await api.put(
      '/rooms/${room.id}',
      room.toJson(),
    );
  }

  Future<void> delete(
    int id,
  ) async {
    await api.delete(
      '/rooms/$id',
    );
  }
}