import 'dart:convert';

import 'package:app_geriatrico/data/models/bed_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class BedRepository {
  final ApiService api;

  BedRepository(
    this.api,
  );

  Future<List<Bed>> getAll() async {
    final response =
        await api.get('/beds');

    final List data =
        jsonDecode(response.body);

    return data
        .map(
          (e) => Bed.fromJson(e),
        )
        .toList();
  }

  Future<void> create(
    Bed bed,
  ) async {
    await api.post(
      '/beds',
      bed.toJson(),
    );
  }

  Future<void> update(
    Bed bed,
  ) async {
    await api.put(
      '/beds/${bed.id}',
      bed.toJson(),
    );
  }

  Future<void> delete(
    int id,
  ) async {
    await api.delete(
      '/beds/$id',
    );
  }
}