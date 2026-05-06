import 'package:dio/dio.dart';
import 'package:app_geriatrico/data/models/auth_response.dart';
import 'package:app_geriatrico/core/config.dart';

class AuthRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {'Accept': 'application/json'},
  ));

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Error en el servidor';
      throw Exception(message);
    }
  }
}