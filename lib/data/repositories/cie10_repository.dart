import 'dart:convert';
import 'package:app_geriatrico/data/models/cie10_model.dart';
import 'package:app_geriatrico/services/api_services.dart';

class Cie10Repository {
  final ApiService api;
  Cie10Repository(this.api);

  
  Future<List<Cie10Code>> search(String q) async {
    final res = await api.get('/cie10?q=${Uri.encodeComponent(q)}');
    final List data = jsonDecode(res.body);
    return data.map((e) => Cie10Code.fromJson(e)).toList();
  }


  Future<Cie10Code> create(String code, String description) async {
    final res = await api.post('/cie10', {
      'code':        code.toUpperCase().trim(),
      'description': description.trim(),
    });
    final body = jsonDecode(res.body);
    return Cie10Code.fromJson(body['data']);
  }


  Future<Cie10Code> update(int id, {String? code, String? description}) async {
    final res = await api.put('/cie10/$id', {
      if (code != null)        'code':        code.toUpperCase().trim(),
      if (description != null) 'description': description.trim(),
    });
    final body = jsonDecode(res.body);
    return Cie10Code.fromJson(body['data']);
  }


  Future<void> delete(int id) async {
    await api.delete('/cie10/$id');
  }
}
