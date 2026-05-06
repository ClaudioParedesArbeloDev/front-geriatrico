import 'dart:convert';
import 'package:app_geriatrico/data/models/medical_prescription_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class MedicalPrescriptionRepository {
  final ApiService api;
  MedicalPrescriptionRepository(this.api);

  Future<List<MedicalPrescription>> getByPatient(int patientId) async {
    final response = await api.get('/medical-prescriptions?patient_id=$patientId');
    final List data = jsonDecode(response.body);
    return data.map((e) => MedicalPrescription.fromJson(e)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.post('/medical-prescriptions', data);
  }

  Future<void> update(int id, Map<String, dynamic> data) async {
    await api.put('/medical-prescriptions/$id', data);
  }

  Future<void> delete(int id) async {
    await api.delete('/medical-prescriptions/$id');
  }
}