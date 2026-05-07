import 'dart:convert';
import 'package:app_geriatrico/data/models/medication_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class MedicationRepository {
  final ApiService api;

  MedicationRepository(this.api);

  Future<List<Medication>> getAll({String? search, bool? controlled}) async {
    final params = <String>[];
    if (search != null && search.isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search)}');
    }
    if (controlled != null) {
      params.add('controlled=${controlled ? 1 : 0}');
    }
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await api.get('/medications$query');
    final List data = jsonDecode(response.body);
    return data.map((e) => Medication.fromJson(e)).toList();
  }

  Future<Medication> create(Map<String, dynamic> data) async {
    final response = await api.post('/medications', data);
    final body = jsonDecode(response.body);
    return Medication.fromJson(body['data']);
  }

  Future<Medication> update(int id, Map<String, dynamic> data) async {
    final response = await api.put('/medications/$id', data);
    final body = jsonDecode(response.body);
    return Medication.fromJson(body['data']);
  }

  Future<void> delete(int id) async {
    await api.delete('/medications/$id');
  }
}
