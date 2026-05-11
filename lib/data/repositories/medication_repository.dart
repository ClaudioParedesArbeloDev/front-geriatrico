import 'dart:convert';
import 'package:app_geriatrico/data/models/medication_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class MedicationRepository {
  final ApiService api;

  MedicationRepository(this.api);

  
  Future<List<Medication>> getAll({String? search}) async {
    final params = <String>[];
    if (search != null && search.isNotEmpty) {
     
      params.add('q=${Uri.encodeComponent(search)}');
    }
   
    params.add('per_page=100');

    final query = '?${params.join('&')}';
    final response = await api.get('/medications$query');

    
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> data = body['data'] as List<dynamic>;

    return data.map((e) => Medication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Medication> create(Map<String, dynamic> data) async {
    final response = await api.post('/medications', data);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Medication.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Medication> update(int id, Map<String, dynamic> data) async {
    final response = await api.put('/medications/$id', data);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Medication.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await api.delete('/medications/$id');
  }
}