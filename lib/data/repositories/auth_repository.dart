import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/auth_response.dart';

class AuthRepository {
  Future<AuthResponse> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/login'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'email': email, 'password': password}),
  );

  Map<String, dynamic> body;
  try {
    body = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    throw Exception('El servidor devolvió una respuesta inesperada (${response.statusCode}). Verificá la URL del backend.');
  }

  if (response.statusCode == 200) {
    return AuthResponse.fromJson(body);
  }

  throw Exception(body['message'] ?? 'Credenciales incorrectas');
}

  Future<bool> logout(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/logout'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}
