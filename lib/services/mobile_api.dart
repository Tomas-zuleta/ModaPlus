import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// URL del backend móvil: --dart-define=MODAPLUS_API_URL=https://servidor
class MobileApi {
  MobileApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const baseUrl = String.fromEnvironment('MODAPLUS_API_URL');
  static const _timeout = Duration(seconds: 12);

  Uri _endpoint(String path) {
    if (baseUrl.isEmpty) throw StateError('Configura MODAPLUS_API_URL');
    final uri = Uri.parse(baseUrl);
    if (!uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException('MODAPLUS_API_URL debe ser una URL válida');
    }
    return uri.replace(path: '${uri.path.replaceFirst(RegExp(r"/+$"), "")}$path');
  }

  Future<bool> isAvailable() async {
    if (baseUrl.isEmpty) return false;
    try {
      final response = await _client.get(_endpoint('/api/v1/health')).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _client.get(_endpoint('/api/v1/products')).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Error al consultar el catálogo: HTTP ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void dispose() => _client.close();
}
