import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String? token;

  const ApiService({required this.baseUrl, this.token});

  Map<String, String> get _headers {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String endpoint) => Uri.parse('$baseUrl$endpoint');

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(_uri(endpoint), headers: _headers);
    _handleErrors(response);
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    _handleErrors(response);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      _uri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    _handleErrors(response);
    return response;
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );
    _handleErrors(response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(_uri(endpoint), headers: _headers);
    _handleErrors(response);
    return response;
  }

  void _handleErrors(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

 
    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body.containsKey('message')) {
        message = body['message'] as String;
      } else if (body.containsKey('errors')) {
      
        final errors = body['errors'] as Map<String, dynamic>;
        message = errors.values
            .expand((v) => v is List ? v : [v])
            .take(2)
            .join(' • ');
      } else {
        message = 'Error ${response.statusCode}';
      }
    } catch (_) {
      message = 'Error ${response.statusCode}';
    }

    throw Exception(message);
  }
}