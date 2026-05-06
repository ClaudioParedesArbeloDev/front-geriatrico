import 'dart:convert';
import 'package:app_geriatrico/data/models/patient_contact_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientContactRepository {
  final ApiService api;
  PatientContactRepository(this.api);

  Future<List<PatientContact>> getByPatient(int patientId) async {

    final response = await api.get('/patientcontacts?patient_id=$patientId');
    final List data = jsonDecode(response.body);
    return data.map((e) => PatientContact.fromJson(e)).toList();
  }
}