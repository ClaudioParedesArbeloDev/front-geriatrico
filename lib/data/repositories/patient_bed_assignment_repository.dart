import 'dart:convert';
import 'package:app_geriatrico/data/models/patient_bed_assignment_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientBedAssignmentRepository {
  final ApiService api;
  PatientBedAssignmentRepository(this.api);

  
  Future<List<PatientBedAssignment>> getAll() async {
    final res = await api.get('/patient-bed-assignments');
    final List data = jsonDecode(res.body);
    return data.map((e) => PatientBedAssignment.fromJson(e)).toList();
  }

 
  Future<PatientBedAssignment> assign(int patientId, int bedId) async {
    final res = await api.post('/patient-bed-assignments', {
      'patient_id': patientId,
      'bed_id': bedId,
    });
    final body = jsonDecode(res.body);
    return PatientBedAssignment.fromJson(body['data']);
  }

 
  Future<void> release(int assignmentId) async {
    await api.delete('/patient-bed-assignments/$assignmentId');
  }
}
