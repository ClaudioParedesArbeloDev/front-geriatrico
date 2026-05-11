import 'dart:convert';
import 'package:app_geriatrico/data/models/patient_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientRepository {
  final ApiService api;
  PatientRepository(this.api);

  Future<List<Patient>> getPatients() async {
    final response = await api.get('/patients');
    final List data = jsonDecode(response.body);
    return data.map((e) => Patient.fromJson(e)).toList();
  }

  Future<List<Patient>> searchByDni(String dni) async {
    final response = await api.get('/patients?dni=${Uri.encodeComponent(dni)}');
    final List data = jsonDecode(response.body);
    return data.map((e) => Patient.fromJson(e)).toList();
  }

  Future<List<Patient>> search(String query) async {
    final response = await api.get('/patients?search=${Uri.encodeComponent(query)}');
    final List data = jsonDecode(response.body);
    return data.map((e) => Patient.fromJson(e)).toList();
  }

  Future<Patient> getPatient(int id) async {
    final response = await api.get('/patients/$id');
    final data = jsonDecode(response.body);
    return Patient.fromJson(data);
  }

  
  Future<Patient> createPatient(Patient patient) async {
    final response = await api.post('/patients', patient.toJson());
    final body = jsonDecode(response.body);
    return Patient.fromJson(body['patient']);
  }

  Future<void> updatePatient(Patient patient) async {
    await api.put('/patients/${patient.id}', patient.toJson());
  }

  Future<void> deletePatient(int id) async {
    await api.delete('/patients/$id');
  }
}