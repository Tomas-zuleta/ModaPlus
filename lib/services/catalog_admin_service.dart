import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_permissions.dart';

/// Operaciones sobre tablas maestras, nunca sobre movimientos financieros.
class CatalogAdminService {
  CatalogAdminService._();
  static final instance = CatalogAdminService._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list(String module) async {
    await AdminPermissions.instance.require(module, 'view');
    final table = switch (module) {
      'categorias' => 'categorias',
      'colores' => 'colores',
      _ => throw ArgumentError('Módulo no admitido'),
    };
    final rows = await _db.from(table).select('*').limit(300);
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> save(String module, {int? id, required String name,
    String? hex, required String status}) async {
    await AdminPermissions.instance.require(module, id == null ? 'create' : 'edit');
    if (name.trim().isEmpty) throw ArgumentError('Nombre obligatorio');
    if (status != 'ACTIVO' && status != 'INACTIVO') {
      throw ArgumentError('Estado inválido');
    }
    final table = module == 'categorias' ? 'categorias' :
      module == 'colores' ? 'colores' : throw ArgumentError('Módulo inválido');
    final data = module == 'categorias'
      ? <String, dynamic>{'nombre_categoria': name.trim(), 'estado': status}
      : <String, dynamic>{
          'nombre_color': name.trim(),
          'codigo_hex': hex,
          'codigos_hex': [hex],
          'estado': status,
        };
    if (module == 'colores' &&
        !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex ?? '')) {
      throw ArgumentError('Color HEX inválido (ejemplo: #112233)');
    }
    if (id == null) {
      await _db.from(table).insert(data);
    } else {
      await _db.from(table).update(data).eq(
        module == 'categorias' ? 'id_categoria' : 'id_color', id);
    }
  }

  Future<void> delete(String module, int id) async {
    await AdminPermissions.instance.require(module, 'delete');
    final table = module == 'categorias' ? 'categorias' :
      module == 'colores' ? 'colores' : throw ArgumentError('Módulo inválido');
    await _db.from(table).delete().eq(
      module == 'categorias' ? 'id_categoria' : 'id_color', id);
  }
}
