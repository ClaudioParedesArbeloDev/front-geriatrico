import 'dart:convert';
import 'package:app_geriatrico/data/models/patient_contact_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientContactRepository {
  final ApiService api;

  PatientContactRepository(this.api);

  Future<List<PatientContact>> getByPatient(int patientId) async {
    // CORRECCIÓN: era /patientcontacts, la ruta correcta es /patient-contacts
    final response = await api.get('/patient-contacts?patient_id=$patientId');
    final List data = jsonDecode(response.body);
    return data.map((e) => PatientContact.fromJson(e)).toList();
  }

  Future<PatientContact> create(Map<String, dynamic> data) async {
    final response = await api.post('/patient-contacts', data);
    final body = jsonDecode(response.body);
    return PatientContact.fromJson(body['data']);
  }

  Future<PatientContact> update(int id, Map<String, dynamic> data) async {
    final response = await api.put('/patient-contacts/$id', data);
    final body = jsonDecode(response.body);
    return PatientContact.fromJson(body['data']);
  }

  /// Marca este contacto como responsable principal del paciente.
  Future<void> setPrimary(int id) async {
    await api.patch('/patient-contacts/$id/set-primary', {});
  }

  Future<void> delete(int id) async {
    await api.delete('/patient-contacts/$id');
  }
}
