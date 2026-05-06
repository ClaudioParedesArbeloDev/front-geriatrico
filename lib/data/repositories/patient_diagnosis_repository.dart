import 'dart:convert';
import 'package:app_geriatrico/data/models/patient_diagnosis_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientDiagnosisRepository {
  final ApiService api;
  PatientDiagnosisRepository(this.api);

  Future<List<PatientDiagnosis>> getByPatient(int patientId) async {
    final response = await api.get('/patient-diagnoses?patient_id=$patientId');
    final List data = jsonDecode(response.body);
    return data.map((e) => PatientDiagnosis.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.post('/patient-diagnoses', data);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.put('/patient-diagnoses/$id', data);
  }

  Future<void> delete(int id) async {
    await api.delete('/patient-diagnoses/$id');
  }
}