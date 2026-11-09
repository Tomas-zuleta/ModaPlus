import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/user_role.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AuthAccount {
  final String name;
  final String email;
  final UserRole role;
  const AuthAccount(this.name, this.email, this.role);
}

/// Inicio de sesión real. No se permite autenticación de demostración.
class SupabaseAuthService {
  SupabaseAuthService._();
  static final instance = SupabaseAuthService._();
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const apiUrl = String.fromEnvironment('MODAPLUS_API_URL');
  static const _storage = FlutterSecureStorage();

  Uri _uri(String base, String path) {
    final uri = Uri.tryParse(base);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const AuthException('Configura una URL HTTPS válida para la conexión.');
    }
    return uri.replace(path: '${uri.path.replaceFirst(RegExp(r"/+$"), "")}$path');
  }

  Future<Map<String, dynamic>> _getApi(String path, String token) async {
    final response = await http.get(_uri(apiUrl, path),
      headers: {'Authorization': 'Bearer $token'})
      .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Tu cuenta no tiene acceso o no está activa.');
    }
    if (response.statusCode != 200) {
      throw const AuthException('No fue posible consultar tu cuenta.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<AuthAccount> signIn(String email, String password) async {
    if (supabaseUrl.isEmpty || publishableKey.isEmpty || apiUrl.isEmpty) {
      throw const AuthException('Falta configurar Supabase o la API móvil.');
    }
    final response = await http.post(
      _uri(supabaseUrl, '/auth/v1/token?grant_type=password'),
      headers: {'apikey': publishableKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const AuthException('Correo o contraseña incorrectos, o cuenta sin confirmar.');
    }
    final session = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final token = session['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const AuthException('No se pudo validar la sesión.');
    }
    // Primero verificamos el perfil y los permisos en nuestro servidor.
    final profile = await _getApi('/api/v1/me', token);
    final roleResult = await _getApi('/api/v1/me/role', token);
    final user = profile['account'] as Map<String, dynamic>;
    final client = (user['nombres'] ?? '').toString().trim();
    final surname = (user['apellidos'] ?? '').toString().trim();
    final role = roleResult['role'] == 'admin' ? UserRole.admin : UserRole.client;
    await _storage.write(key: 'modaplus_access_token', value: token);
    final refresh = session['refresh_token'] as String?;
    if (refresh != null) {
      await _storage.write(key: 'modaplus_refresh_token', value: refresh);
    }
    return AuthAccount('$client $surname'.trim(),
      (user['correo'] ?? email).toString(), role);
  }

  Future<String?> accessToken() => _storage.read(key: 'modaplus_access_token');

  Future<void> signOut() async {
    final token = await accessToken();
    if (token != null && supabaseUrl.isNotEmpty && publishableKey.isNotEmpty) {
      try {
        await http.post(_uri(supabaseUrl, '/auth/v1/logout'),
          headers: {'apikey': publishableKey, 'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('No se pudo cerrar sesión remota: $error');
      }
    }
    await _storage.delete(key: 'modaplus_access_token');
    await _storage.delete(key: 'modaplus_refresh_token');
  }
}
