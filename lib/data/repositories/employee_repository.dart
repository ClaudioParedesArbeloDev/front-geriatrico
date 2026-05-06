import 'package:dio/dio.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/models/role_model.dart';

class EmployeeRepository {
  final Dio _dio;

  EmployeeRepository(String token)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));

  Future<List<Employee>> getAll() async {
    try {
      final res = await _dio.get('/employees');
      return (res.data as List)
          .map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error al obtener empleados');
    }
  }

  Future<List<Role>> getRoles() async {
    try {
      final res = await _dio.get('/roles');
      return (res.data as List)
          .map((r) => Role.fromJson(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error al obtener roles');
    }
  }

  Future<Employee> update(
      int id, Map<String, dynamic> data, List<int> roleIds) async {
    try {
      final res = await _dio.put(
        '/employees/$id',
        data: {...data, 'roles': roleIds},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      return Employee.fromJson(res.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error al actualizar empleado');
    }
  }
  Future<Employee> create(Map<String, dynamic> data) async {
  try {
    final res = await _dio.post('/employees', data: data);
    return Employee.fromJson(res.data['user'] as Map<String, dynamic>);
  } on DioException catch (e) {
    throw Exception(e.response?.data['message'] ?? 'Error al crear empleado');
  }
}
  Future<void> delete(int id) async {
    try {
      await _dio.delete('/employees/$id');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Error al eliminar empleado');
    }
  }
}