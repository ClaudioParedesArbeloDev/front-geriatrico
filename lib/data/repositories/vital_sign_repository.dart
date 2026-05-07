import 'dart:convert';
import 'package:app_geriatrico/data/models/vital_sign_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class VitalSignRepository {
  final ApiService api;

  VitalSignRepository(this.api);

  Future<List<VitalSign>> getByPatient(int patientId, {int? limit}) async {
    var endpoint = '/vital-signs?patient_id=$patientId';
    if (limit != null) endpoint += '&limit=$limit';
    final response = await api.get(endpoint);
    final List data = jsonDecode(response.body);
    return data.map((e) => VitalSign.fromJson(e)).toList();
  }

  Future<VitalSign> create(Map<String, dynamic> data) async {
    final response = await api.post('/vital-signs', data);
    final body = jsonDecode(response.body);
    return VitalSign.fromJson(body['data']);
  }

  Future<VitalSign> update(int id, Map<String, dynamic> data) async {
    final response = await api.put('/vital-signs/$id', data);
    final body = jsonDecode(response.body);
    return VitalSign.fromJson(body['data']);
  }

  Future<void> delete(int id) async {
    await api.delete('/vital-signs/$id');
  }
}
