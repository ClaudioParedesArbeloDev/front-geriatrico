import 'package:http/http.dart' as http;
import 'package:app_geriatrico/core/config.dart';

class AuthService {

  static Future<bool> logout(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}