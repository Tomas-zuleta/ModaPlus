import 'package:supabase_flutter/supabase_flutter.dart';

/// Consultas reales de solo lectura. RLS se aplica con el JWT del usuario.
class SupabaseDataService {
  SupabaseDataService._();
  static final instance = SupabaseDataService._();
  SupabaseClient get _db => Supabase.instance.client;

  /// RPC compartido con la web; la autorización la aplica Supabase.
  Future<void> rejectOnlineSale(int id, String reason) async {
    if (_db.auth.currentUser == null) throw StateError('Sesión requerida');
    if (id <= 0 || reason.trim().isEmpty) {
      throw ArgumentError('Venta y motivo obligatorios');
    }
    await _db.rpc('rechazar_venta_online',
      params: {'p_id_venta': id, 'p_motivo': reason.trim()});
  }

  Future<int> _clientId() async {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Sesión requerida');
    final account = await _db.from('usuarios').select('id_cliente,estado')
      .eq('auth_user_id', user.id).maybeSingle();
    if (account == null || account['estado'] != 'ACTIVO' ||
        account['id_cliente'] == null) {
      throw StateError('Cuenta sin cliente activo');
    }
    return (account['id_cliente'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> inventoryForAdmin() async {
    final rows = await _db.from('variantes_producto')
      .select('id_variante,id_producto,stock_actual,estado')
      .order('id_variante', ascending: false).limit(500);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> salesForAdmin({int limit = 500}) async {
    final rows = await _db.from('ventas')
      .select('id_venta,id_cliente,fecha_venta,total_venta,estado,origen')
      .order('fecha_venta', ascending: false).limit(limit);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> plansForAdmin() async {
    final rows = await _db.from('planes_separe')
      .select('id_plan_separe,id_cliente,fecha_inicio,fecha_vencimiento,estado')
      .order('fecha_inicio', ascending: false).limit(500);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  /// El acceso al comprobante depende de RLS y Storage policies.
  /// Nunca se construyen URLs públicas ni se devuelve una service_role key.
  Future<Map<String, dynamic>> saleDetail(int id) async {
    if (_db.auth.currentUser == null) throw StateError('Sesión requerida');
    final row = await _db.from('ventas')
      .select('id_venta,id_cliente,fecha_venta,metodo_pago,total_venta,estado,origen,comprobante_url,comprobante_nombre,motivo_rechazo')
      .eq('id_venta', id).single();
    return Map<String, dynamic>.from(row);
  }

  Future<String?> receiptSignedUrl(String path) async {
    if (_db.auth.currentUser == null) throw StateError('Sesión requerida');
    if (path.isEmpty || path.startsWith('/') || path.contains('..') ||
        path.contains('://')) throw StateError('Ruta de comprobante inválida');
    return _db.storage.from('comprobantes').createSignedUrl(path, 120);
  }

  Future<List<Map<String, dynamic>>> myOrders() async {
    final id = await _clientId();
    final rows = await _db.from('ventas')
      .select('id_venta,fecha_venta,metodo_pago,subtotal,total_venta,estado,origen,motivo_rechazo,fecha_limite_pago,fecha_entrega')
      .eq('id_cliente', id).order('fecha_venta', ascending: false).limit(100);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> myPlans() async {
    final id = await _clientId();
    final rows = await _db.from('planes_separe')
      .select('id_plan_separe,fecha_inicio,fecha_vencimiento,estado,fecha_estado')
      .eq('id_cliente', id).order('fecha_inicio', ascending: false).limit(100);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<List<Map<String, dynamic>>> recentSalesForAdmin() =>
      salesForAdmin(limit: 100);
}
