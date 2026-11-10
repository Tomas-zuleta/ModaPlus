import 'package:supabase_flutter/supabase_flutter.dart';

/// Refleja el modelo de roles/permisos de ModaPlus web.
/// Es una comprobación de interfaz: RLS y RPC deben validar también en servidor.
class AdminPermissions {
  AdminPermissions._();
  static final instance = AdminPermissions._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<bool> can(String module, String action) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    final account = await _db.from('usuarios')
      .select('id_usuario,estado,usuarios_roles(id_rol)')
      .eq('auth_user_id', user.id).maybeSingle();
    if (account == null || account['estado'] != 'ACTIVO') return false;
    final assignments = account['usuarios_roles'] as List<dynamic>? ?? [];
    final ids = assignments.map((item) => (item as Map)['id_rol'])
      .whereType<num>().map((value) => value.toInt()).toList();
    if (ids.isEmpty) return false;
    final roles = await _db.from('roles')
      .select('id_rol,nombre_rol,estado,roles_permisos(modulos(codigo),permisos(codigo))')
      .inFilter('id_rol', ids);
    for (final role in roles) {
      if (role['estado']?.toString().toUpperCase() != 'ACTIVO') continue;
      final name = (role['nombre_rol'] ?? '').toString()
        .toUpperCase().replaceAll(' ', '').replaceAll('_', '');
      if ((role['id_rol'] as num?)?.toInt() == 1 ||
          name == 'SUPERADMIN' || name == 'SUPERADMINISTRADOR') {
        return true;
      }
      for (final entry in role['roles_permisos'] as List<dynamic>? ?? []) {
        final permission = entry as Map;
        final mod = permission['modulos'];
        final perm = permission['permisos'];
        final modRow = mod is List ? (mod.isEmpty ? null : mod.first) : mod;
        final permRow = perm is List ? (perm.isEmpty ? null : perm.first) : perm;
        if (modRow is Map && permRow is Map &&
            modRow['codigo'] == module && permRow['codigo'] == action) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> require(String module, String action) async {
    if (!await can(module, action)) {
      throw StateError('Tu cuenta no tiene permiso $action en $module');
    }
  }
}
