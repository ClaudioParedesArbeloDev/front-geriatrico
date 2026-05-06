import 'dart:convert';
import 'package:app_geriatrico/data/models/patient_evolution_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientEvolutionRepository {
  final ApiService api;
  PatientEvolutionRepository(this.api);

  Future<List<PatientEvolution>> getByPatient(int patientId) async {
    final response = await api.get('/patient-evolutions?patient_id=$patientId');
    final List data = jsonDecode(response.body);
    return data.map((e) => PatientEvolution.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.post('/patient-evolutions', data);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.put('/patient-evolutions/$id', data);
  }

  Future<void> delete(int id) async {
    await api.delete('/patient-evolutions/$id');
  }
}