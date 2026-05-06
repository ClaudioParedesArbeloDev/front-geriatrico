import 'dart:convert';
import 'package:app_geriatrico/data/models/medical_study_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class MedicalStudyRepository {
  final ApiService api;
  MedicalStudyRepository(this.api);

  Future<List<MedicalStudy>> getByPatient(int patientId) async {
    final response = await api.get('/medical-studies?patient_id=$patientId');
    final List data = jsonDecode(response.body);
    return data.map((e) => MedicalStudy.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.post('/medical-studies', data);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.put('/medical-studies/$id', data);
  }

  Future<void> delete(int id) async {
    await api.delete('/medical-studies/$id');
  }
}