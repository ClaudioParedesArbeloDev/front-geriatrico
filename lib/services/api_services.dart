import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiService {
  final String baseUrl;
  final String? token;

  const ApiService({required this.baseUrl, this.token});

  // Cliente HTTP que acepta certificados SSL con cadena incompleta
  http.Client get _client {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

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
    final client = _client;
    try {
      final response = await client.get(_uri(endpoint), headers: _headers);
      _handleErrors(response);
      return response;
    } finally {
      client.close();
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final client = _client;
    try {
      final response = await client.post(
        _uri(endpoint),
        headers: _headers,
        body: jsonEncode(body),
      );
      _handleErrors(response);
      return response;
    } finally {
      client.close();
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final client = _client;
    try {
      final response = await client.put(
        _uri(endpoint),
        headers: _headers,
        body: jsonEncode(body),
      );
      _handleErrors(response);
      return response;
    } finally {
      client.close();
    }
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final client = _client;
    try {
      final response = await client.patch(
        _uri(endpoint),
        headers: _headers,
        body: jsonEncode(body),
      );
      _handleErrors(response);
      return response;
    } finally {
      client.close();
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final client = _client;
    try {
      final response = await client.delete(_uri(endpoint), headers: _headers);
      _handleErrors(response);
      return response;
    } finally {
      client.close();
    }
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