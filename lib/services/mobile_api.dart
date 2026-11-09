import 'dart:convert';
import 'package:http/http.dart' as http;

/// Configura --dart-define=MODAPLUS_API_URL=https://tu-api
class MobileApi {
  MobileApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = String.fromEnvironment('MODAPLUS_API_URL');

  Future<List<Map<String, dynamic>>> getProducts() async {
    if (baseUrl.isEmpty) throw StateError('Configura MODAPLUS_API_URL');
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/products'));
    if (response.statusCode != 200) throw Exception('Error al consultar el catálogo');
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void dispose() => _client.close();
}
