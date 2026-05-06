import 'dart:convert';

import 'package:app_geriatrico/data/models/medication_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class MedicationRepository {
  final ApiService api;

  MedicationRepository(
    this.api,
  );

  Future<List<Medication>>
      getAll() async {
    final response =
        await api.get(
      '/medications',
    );

    final List data =
        jsonDecode(response.body);

    return data
        .map(
          (e) =>
              Medication.fromJson(e),
        )
        .toList();
  }
}