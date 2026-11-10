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

  /// Un abono es corto de registrar, pero debe verificarse en el servidor.
  /// Este RPC existe en el esquema provisional de pruebas. Producción debe
  /// adoptar un contrato equivalente antes de habilitar este flujo allí.
  Future<int> registerLayawayPayment({
    required int planId,
    required double amount,
    required String method,
    String observation = '',
  }) async {
    await AdminPermissions.instance.require('abonos', 'create');
    if (planId <= 0 || !amount.isFinite || amount <= 0) {
      throw ArgumentError('Selecciona un plan y un valor válido.');
    }
    if (!const ['EFECTIVO', 'TRANSFERENCIA', 'QR'].contains(method)) {
      throw ArgumentError('Selecciona un método de pago.');
    }
    final result = await _db.rpc('registrar_abono_separe', params: {
      'p_id_plan': planId,
      'p_valor': amount,
      'p_metodo': method,
      'p_observacion': observation.trim(),
    });
    if (result is! num || result <= 0) {
      throw StateError('No se confirmó el abono. Verifica el historial '
        'antes de volver a enviarlo.');
    }
    return result.toInt();
  }

  Future<void> annulLayaway(int id) async {
    if (id <= 0) throw ArgumentError('Plan inválido');
    await AdminPermissions.instance.require('separe', 'annul');
    await _db.rpc('anular_plan_separe', params: {'p_id': id});
  }

  Future<void> annulPayment(int id) async {
    if (id <= 0) throw ArgumentError('Abono inválido');
    await AdminPermissions.instance.require('abonos', 'annul');
    await _db.rpc('anular_abono', params: {'p_id': id});
  }

  Future<void> annulPurchase(int id) async {
    if (id <= 0) throw ArgumentError('Compra inválida');
    await AdminPermissions.instance.require('compras', 'annul');
    final existing = await _db.from('compras').select('*')
      .eq('id_compra', id).single();
    if (existing['estado']?.toString().toUpperCase() == 'ANULADA') {
      throw StateError('La compra ya está anulada');
    }
    final details = await _db.from('detalles_compra').select('*')
      .eq('id_compra', id);
    final purchase = <String, dynamic>{
      'id_compra': id, 'id_proveedor': existing['id_proveedor'],
      'fecha_compra': existing['fecha_compra'],
      'fecha_registro': existing['fecha_registro'],
      'factura': existing['numero_factura_proveedor'] ?? existing['factura'],
      'tipo_pago': existing['tipo_pago'], 'estado': 'ANULADA',
    };
    final lines = details.map((e) {
      final data = Map<String, dynamic>.from(e);
      data.remove('id_detalle_compra');
      return data;
    }).toList();
    await _db.rpc('guardar_compra', params: {
      'p_compra': purchase, 'p_detalles': lines,
    });
  }

  Future<void> manageLoss(String action, Map<String, dynamic> loss) async {
    const allowed = ['guardar', 'anular', 'eliminar'];
    if (!allowed.contains(action)) throw ArgumentError('Acción inválida');
    await AdminPermissions.instance.require('perdidas',
      action == 'anular' ? 'annul' : action == 'eliminar' ? 'delete' : 'create');
    await _db.rpc('gestionar_perdida', params: {
      'p_accion': action,
      'p_perdida': {
        'id_perdida': loss['id_perdida'],
        'id_devolucion': loss['id_devolucion'],
        'id_variante': loss['id_variante'],
        'cantidad': loss['cantidad'],
        'motivo': loss['motivo'],
        'descripcion': loss['descripcion'] ?? '',
        'estado': loss['estado'],
      },
    });
  }

  Future<void> assignRoles(int userId, List<int> roleIds) async {
    await AdminPermissions.instance.require('usuarios', 'edit');
    if (userId <= 0 || roleIds.isEmpty) throw ArgumentError('Roles inválidos');
    await _db.rpc('actualizar_roles_usuario', params: {
      'p_usuario': userId, 'p_roles': roleIds,
    });
  }
}
