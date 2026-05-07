import 'dart:convert';
import 'package:app_geriatrico/data/models/medical_prescription_model.dart';
import 'package:app_geriatrico/data/models/prescription_schedule_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class MedicalPrescriptionRepository {
  final ApiService api;

  MedicalPrescriptionRepository(this.api);

  Future<List<MedicalPrescription>> getByPatient(
    int patientId, {
    bool? activeOnly,
  }) async {
    var endpoint = '/medical-prescriptions?patient_id=$patientId';
    if (activeOnly == true) endpoint += '&active=1';
    final response = await api.get(endpoint);
    final List data = jsonDecode(response.body);
    return data.map((e) => MedicalPrescription.fromJson(e)).toList();
  }

  Future<MedicalPrescription> create(Map<String, dynamic> data) async {
    final response = await api.post('/medical-prescriptions', data);
    final body = jsonDecode(response.body);
    return MedicalPrescription.fromJson(body['data']);
  }

  Future<MedicalPrescription> update(int id, Map<String, dynamic> data) async {
    final response = await api.put('/medical-prescriptions/$id', data);
    final body = jsonDecode(response.body);
    return MedicalPrescription.fromJson(body['data']);
  }

  Future<void> suspend(int id) async {
    await api.patch('/medical-prescriptions/$id/suspend', {});
  }

  Future<void> reactivate(int id) async {
    await api.patch('/medical-prescriptions/$id/reactivate', {});
  }

  Future<void> delete(int id) async {
    await api.delete('/medical-prescriptions/$id');
  }

  // -----------------------------------------------------------------------
  // Horarios de una prescripción
  // -----------------------------------------------------------------------

  Future<List<PrescriptionSchedule>> getSchedules(int prescriptionId) async {
    final response = await api.get(
      '/medical-prescriptions/$prescriptionId/schedules',
    );
    final List data = jsonDecode(response.body);
    return data.map((e) => PrescriptionSchedule.fromJson(e)).toList();
  }

  Future<PrescriptionSchedule> addSchedule(
    int prescriptionId,
    String time, {
    String? label,
  }) async {
    final response = await api.post(
      '/medical-prescriptions/$prescriptionId/schedules',
      {'scheduled_time': time, if (label != null) 'label': label},
    );
    final body = jsonDecode(response.body);
    return PrescriptionSchedule.fromJson(body['data']);
  }

  /// Reemplaza todos los horarios de una prescripción de una vez.
  Future<void> syncSchedules(
    int prescriptionId,
    List<Map<String, dynamic>> schedules,
  ) async {
    await api.put(
      '/medical-prescriptions/$prescriptionId/schedules',
      {'schedules': schedules},
    );
  }

  Future<void> deleteSchedule(int prescriptionId, int scheduleId) async {
    await api.delete(
      '/medical-prescriptions/$prescriptionId/schedules/$scheduleId',
    );
  }
}
