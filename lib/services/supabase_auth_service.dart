import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class CustomerRegistration {
  final String tipoDocumento, identificacion, nombres, apellidos, telefono, direccion;
  const CustomerRegistration({required this.tipoDocumento,
    required this.identificacion, required this.nombres,
    required this.apellidos, required this.telefono, required this.direccion});
  Map<String, dynamic> toJson() => {
    'tipoDocumento': tipoDocumento, 'identificacion': identificacion,
    'nombres': nombres, 'apellidos': apellidos, 'telefono': telefono,
    'direccion': direccion,
  };
}

class AuthAccount {
  final String name;
  final String email;
  final UserRole role;
  const AuthAccount(this.name, this.email, this.role);
}

/// Usa el mismo Supabase Auth y las políticas RLS de la aplicación web.
/// Nunca acepta el rol del cliente ni emplea claves service_role.
class SupabaseAuthService {
  SupabaseAuthService._();
  static final instance = SupabaseAuthService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<bool> register(String email, String password,
      CustomerRegistration customer) async {
    try {
      final response = await _db.auth.signUp(
        email: email.trim().toLowerCase(), password: password,
        data: {'customer': customer.toJson()});
      if (response.user == null) throw const AuthException('No se pudo crear la cuenta.');
      if (response.session != null) {
        await activateCustomer(customer);
        await _sendWelcomeBestEffort();
        return true;
      }
      return false;
    } on AuthApiException catch (e) {
      if (e.code == 'user_already_exists' || e.code == 'email_exists') {
        throw const AuthException('Ya existe una cuenta con ese correo.');
      }
      throw const AuthException('No se pudo registrar la cuenta. Verifica los datos.');
    } on PostgrestException {
      throw const AuthException('Cuenta creada, pero no se pudo activar el perfil. '
        'Confirma tu correo e inicia sesión para reintentar.');
    }
  }

  /// Reutiliza la función ya existente en Supabase. El fallo de correo
  /// no debe bloquear un registro válido.
  Future<void> _sendWelcomeBestEffort() async {
    if (_db.auth.currentSession == null) return;
    try {
      await _db.functions.invoke('send-account-registered');
    } catch (_) {
      // El envío puede fallar o la función no estar desplegada.
    }
  }

  Future<void> activateCustomer(CustomerRegistration customer) async {
    await _db.rpc('activar_cuenta_cliente', params: {
      'p_tipo_documento': customer.tipoDocumento,
      'p_identificacion': customer.identificacion,
      'p_nombres': customer.nombres,
      'p_apellidos': customer.apellidos,
      'p_telefono': customer.telefono,
      'p_direccion': customer.direccion.isEmpty ? null : customer.direccion,
    });
  }

  Future<void> _activateFromMetadata() async {
    final raw = _db.auth.currentUser?.userMetadata?['customer'];
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    await activateCustomer(CustomerRegistration(
      tipoDocumento: (data['tipoDocumento'] ?? 'CC').toString(),
      identificacion: (data['identificacion'] ?? '').toString(),
      nombres: (data['nombres'] ?? '').toString(),
      apellidos: (data['apellidos'] ?? '').toString(),
      telefono: (data['telefono'] ?? '').toString(),
      direccion: (data['direccion'] ?? '').toString(),
    ));
  }

  Future<AuthAccount> signIn(String email, String password) async {
    try {
      final response = await _db.auth.signInWithPassword(
        email: email.trim().toLowerCase(), password: password);
      if (response.user == null || response.session == null) {
        throw const AuthException('No se pudo verificar tu sesión.');
      }
      try {
        try {
          return await currentAccount();
        } on AuthException {
          await _activateFromMetadata();
          final account = await currentAccount();
          await _sendWelcomeBestEffort();
          return account;
        }
      } catch (_) {
        await _db.auth.signOut();
        rethrow;
      }
    } on AuthApiException catch (error) {
      if (error.code == 'email_not_confirmed') {
        throw const AuthException('Confirma tu correo antes de ingresar.');
      }
      throw const AuthException('Correo o contraseña incorrectos, o cuenta no confirmada.');
    } on PostgrestException {
      throw const AuthException('No fue posible consultar tu cuenta. Revisa tus permisos.');
    }
  }

  Future<AuthAccount> currentAccount() async {
    final user = _db.auth.currentUser;
    if (user == null) throw const AuthException('Inicia sesión para continuar.');
    final row = await _db.from('usuarios')
      .select('id_usuario,estado,clientes(*),usuarios_roles(id_rol)')
      .eq('auth_user_id', user.id).maybeSingle();
    if (row == null || row['estado'] != 'ACTIVO') {
      throw const AuthException('Tu cuenta aún no está activa.');
    }
    final rawClient = row['clientes'];
    final client = rawClient is List
      ? (rawClient.isNotEmpty ? Map<String, dynamic>.from(rawClient.first as Map) : null)
      : rawClient is Map ? Map<String, dynamic>.from(rawClient) : null;
    if (client == null) throw const AuthException('No existe un perfil vinculado a tu cuenta.');
    final assigned = (row['usuarios_roles'] as List<dynamic>? ?? [])
      .map((e) => (e as Map)['id_rol']).whereType<num>().map((e) => e.toInt()).toList();
    var admin = false;
    if (assigned.isNotEmpty) {
      final roles = await _db.from('roles')
        .select('id_rol,nombre_rol,estado,roles_permisos(modulos(codigo),permisos(codigo))')
        .inFilter('id_rol', assigned);
      for (final role in roles) {
        if (role['estado'] != 'ACTIVO') continue;
        final normalizedRole = (role['nombre_rol'] ?? '').toString()
          .toUpperCase().replaceAll(RegExp(r'[ _-]'), '');
        if ((role['id_rol'] as num?)?.toInt() == 1 ||
            normalizedRole == 'SUPERADMIN' ||
            normalizedRole == 'SUPERADMINISTRADOR') {
          admin = true;
          break;
        }
        final permissions = role['roles_permisos'] as List<dynamic>? ?? [];
        if (permissions.any((entry) {
          final p = entry as Map;
          final mod = p['modulos'];
          final perm = p['permisos'];
          final module = mod is List ? (mod.isEmpty ? null : mod.first) : mod;
          final permission = perm is List ? (perm.isEmpty ? null : perm.first) : perm;
          return module is Map && permission is Map &&
            permission['codigo'] == 'view' &&
            !['catalogo', 'perfil'].contains(module['codigo']);
        })) { admin = true; break; }
      }
    }
    final name = '${client['nombres'] ?? ''} ${client['apellidos'] ?? ''}'.trim();
    return AuthAccount(name.isEmpty ? 'Cliente' : name,
      (client['correo'] ?? user.email ?? '').toString(),
      admin ? UserRole.admin : UserRole.client);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _db.auth.resetPasswordForEmail(email.trim().toLowerCase());
    } on AuthException catch (_) {
      rethrow;
    } on AuthApiException {
      throw const AuthException('No fue posible enviar el correo. Inténtalo más tarde.');
    }
  }

  Future<void> signOut() async {
    await _db.auth.signOut();
  }
}
