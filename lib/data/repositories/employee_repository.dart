import 'dart:convert';
import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/models/role_model.dart';
import 'package:app_geriatrico/data/models/specialty_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class EmployeeRepository {
  final ApiService api;

  EmployeeRepository(this.api);

  Future<List<Employee>> getAll() async {
    final response = await api.get('/employees');
    final List data = jsonDecode(response.body);
    return data.map((e) => Employee.fromJson(e)).toList();
  }

  Future<Employee> getOne(int id) async {
    final response = await api.get('/employees/$id');
    return Employee.fromJson(jsonDecode(response.body));
  }

  Future<List<Role>> getRoles() async {
    final response = await api.get('/roles');
    final List data = jsonDecode(response.body);
    return data.map((r) => Role.fromJson(r)).toList();
  }

  Future<List<Specialty>> getSpecialties() async {
    final response = await api.get('/specialties');
    final List data = jsonDecode(response.body);
    return data.map((s) => Specialty.fromJson(s)).toList();
  }

  Future<Employee> create(Map<String, dynamic> data) async {
    final response = await api.post('/employees', data);
    final body = jsonDecode(response.body);
    return Employee.fromJson(body['user']);
  }

  Future<Employee> update(
    int id,
    Map<String, dynamic> data,
    List<int> roleIds,
  ) async {
    final response = await api.put('/employees/$id', {
      ...data,
      'roles': roleIds,
    });
    final body = jsonDecode(response.body);
    return Employee.fromJson(body['user']);
  }

  Future<void> assignSpecialties(int userId, List<int> specialtyIds) async {
    await api.post('/users/$userId/specialties', {
      'specialty_ids': specialtyIds,
    });
  }

  Future<void> replaceSpecialties(int userId, List<int> specialtyIds) async {
    await api.put('/users/$userId/specialties', {
      'specialty_ids': specialtyIds,
    });
  }

  Future<void> removeSpecialty(int userId, int specialtyId) async {
    await api.delete('/users/$userId/specialties/$specialtyId');
  }

  Future<void> delete(int id) async {
    await api.delete('/employees/$id');
  }
}
