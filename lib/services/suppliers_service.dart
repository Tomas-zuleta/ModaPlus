import 'package:supabase_flutter/supabase_flutter.dart';

/// Proveedores: mismos campos de la web. RLS es la autoridad final.
class SuppliersService {
  SuppliersService._();
  static final instance = SuppliersService._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list() async {
    if (_db.auth.currentUser == null) throw StateError('Sesión requerida');
    final rows = await _db.from('proveedores')
      .select('id_proveedor,nit,razon_social,contacto,telefono,correo,direccion,estado')
      .order('razon_social').limit(300);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> save({
    int? id, required String nit, required String razonSocial,
    required String contacto, required String telefono,
    required String correo, required String direccion,
    required String estado,
  }) async {
    if (_db.auth.currentUser == null) throw StateError('Sesión requerida');
    if (nit.trim().isEmpty || razonSocial.trim().isEmpty) {
      throw ArgumentError('NIT y razón social son obligatorios');
    }
    final data = <String, dynamic>{
      'nit': nit.trim(), 'razon_social': razonSocial.trim(),
      'contacto': contacto.trim().isEmpty ? null : contacto.trim(),
      'telefono': telefono.trim().isEmpty ? null : telefono.trim(),
      'correo': correo.trim().isEmpty ? null : correo.trim().toLowerCase(),
      'direccion': direccion.trim().isEmpty ? null : direccion.trim(),
      'estado': estado,
    };
    if (id == null) {
      await _db.from('proveedores').insert(data);
    } else {
      await _db.from('proveedores').update(data).eq('id_proveedor', id);
    }
  }

  Future<void> deactivate(int id) async {
    if (_db.auth.currentUser == null) throw StateError('Sesión requerida');
    await _db.from('proveedores').update({'estado': 'INACTIVO'})
      .eq('id_proveedor', id);
  }
}
