import 'dart:convert';
import 'package:app_geriatrico/data/models/allergy_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class AllergyRepository {
  final ApiService api;
  AllergyRepository(this.api);

  Future<List<Allergy>> getAll() async {
    final response = await api.get('/allergies');
    final List data = jsonDecode(response.body);
    return data.map((e) => Allergy.fromJson(e)).toList();
  }

  Future<Allergy> create(Map<String, dynamic> data) async {
    final response = await api.post('/allergies', data);
    final body = jsonDecode(response.body);
    return Allergy.fromJson(body['data'] ?? body);
  }

  Future<Allergy> update(int id, Map<String, dynamic> data) async {
    final response = await api.put('/allergies/$id', data);
    final body = jsonDecode(response.body);
    return Allergy.fromJson(body['data'] ?? body);
  }

  Future<void> delete(int id) async {
    await api.delete('/allergies/$id');
  }

  Future<List<Allergy>> getByPatient(int patientId) async {
    final response = await api.get('/patients/$patientId/allergies');
    final List data = jsonDecode(response.body);
    return data.map((e) => Allergy.fromJson(e)).toList();
  }

  Future<void> assignToPatient(
    int patientId, {
    required int allergyId,
    required String severity,
    String? reaction,
  }) async {
    await api.post('/patients/$patientId/allergies', {
      'allergy_id': allergyId,
      'severity':   severity,
      if (reaction != null && reaction.isNotEmpty) 'reaction': reaction,
    });
  }

  Future<void> updatePatientAllergy(
    int patientId,
    int allergyId, {
    String? severity,
    String? reaction,
  }) async {
    await api.put('/patients/$patientId/allergies/$allergyId', {
      if (severity != null) 'severity': severity,
      if (reaction != null) 'reaction': reaction,
    });
  }

  Future<void> removeFromPatient(int patientId, int allergyId) async {
    await api.delete('/patients/$patientId/allergies/$allergyId');
  }
}