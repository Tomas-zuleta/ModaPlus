import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_permissions.dart';

/// Adaptadores de RPC usados también por ModaPlus web.
/// No llaman al servidor sin una acción explícita del administrador.
class AdministrativeTransactions {
  AdministrativeTransactions._();
  static final instance = AdministrativeTransactions._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<int> savePurchase(Map<String, dynamic> purchase,
      List<Map<String, dynamic>> details) async {
    await AdminPermissions.instance.require('compras',
      (purchase['id_compra'] as num? ?? 0) > 0 ? 'edit' : 'create');
    if (details.isEmpty) throw ArgumentError('La compra requiere productos');
    final result = await _db.rpc('guardar_compra', params: {
      'p_compra': purchase, 'p_detalles': details,
    });
    return (result as num).toInt();
  }

  Future<int> saveSale(Map<String, dynamic> sale,
      List<Map<String, dynamic>> details) async {
    await AdminPermissions.instance.require('ventas',
      (sale['id_venta'] as num? ?? 0) > 0 ? 'edit' : 'create');
    if (details.isEmpty) throw ArgumentError('La venta requiere productos');
    final result = await _db.rpc('guardar_venta', params: {
      'p_venta': sale, 'p_detalles': details,
    });
    return (result as num).toInt();
  }

  Future<int> saveLayaway(Map<String, dynamic> plan,
      List<Map<String, dynamic>> details) async {
    await AdminPermissions.instance.require('separe',
      (plan['id_plan_separe'] as num? ?? 0) > 0 ? 'edit' : 'create');
    if (details.isEmpty) throw ArgumentError('El plan requiere productos');
    final result = await _db.rpc('guardar_plan_separe', params: {
      'p_plan': plan, 'p_detalles': details,
    });
    return (result as num).toInt();
  }

  Future<int> saveReturn(Map<String, dynamic> refund,
      List<Map<String, dynamic>> details) async {
    await AdminPermissions.instance.require('devoluciones', 'create');
    if (details.isEmpty) throw ArgumentError('La devolución requiere productos');
    final result = await _db.rpc('guardar_devolucion', params: {
      'p_devolucion': refund, 'p_detalles': details,
    });
    return (result as num).toInt();
  }

  Future<void> assignRoles(int userId, List<int> roleIds) async {
    await AdminPermissions.instance.require('usuarios', 'edit');
    if (userId <= 0 || roleIds.isEmpty) throw ArgumentError('Roles inválidos');
    await _db.rpc('actualizar_roles_usuario', params: {
      'p_usuario': userId, 'p_roles': roleIds,
    });
  }
}
