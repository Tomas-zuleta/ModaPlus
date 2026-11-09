import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class CheckoutException implements Exception {
  final String message;
  const CheckoutException(this.message);
  @override
  String toString() => message;
}

/// Reutiliza guardar_venta y el bucket privado de la web.
/// El servidor sigue siendo la autoridad sobre stock, precios y permisos.
class SupabaseCheckoutService {
  SupabaseCheckoutService._();
  static final instance = SupabaseCheckoutService._();
  SupabaseClient get _db => Supabase.instance.client;
  static const enabled = bool.fromEnvironment('ENABLE_REAL_CHECKOUT', defaultValue: false);

  Future<int> submit({
    required List<CartItem> cart,
    required Uint8List receipt,
    required String filename,
    required String mimeType,
  }) async {
    if (!enabled) {
      throw const CheckoutException(
        'El checkout real aún requiere validación de seguridad.');
    }
    final user = _db.auth.currentUser;
    if (user == null) throw const CheckoutException('Debes iniciar sesión.');
    if (cart.isEmpty || cart.any((x) => x.variantId == null || x.quantity < 1)) {
      throw const CheckoutException('Carrito sin variantes reales.');
    }
    if (receipt.isEmpty || receipt.length > 1024 * 1024 ||
        !['image/png','image/jpeg','application/pdf'].contains(mimeType)) {
      throw const CheckoutException('Comprobante inválido o mayor a 1 MB.');
    }
    final account = await _db.from('usuarios').select('id_cliente,estado')
      .eq('auth_user_id', user.id).maybeSingle();
    if (account == null || account['estado'] != 'ACTIVO' ||
        account['id_cliente'] is! num) {
      throw const CheckoutException('Cuenta sin perfil de cliente activo.');
    }
    // Se revalidan todas las variantes antes de intentar guardar la venta.
    final ids = cart.map((x) => x.variantId!).toSet().toList();
    final variants = await _db.from('variantes_producto')
      .select('id_variante,precio_venta,stock_actual,estado')
      .inFilter('id_variante', ids);
    final byId = {for (final v in variants) (v['id_variante'] as num).toInt(): v};
    final details = <Map<String, dynamic>>[];
    var total = 0;
    for (final line in cart) {
      final variant = byId[line.variantId];
      if (variant == null || variant['estado'] != 'ACTIVO') {
        throw const CheckoutException('Una variante ya no está disponible.');
      }
      final price = (variant['precio_venta'] as num?)?.toInt() ?? 0;
      final stock = (variant['stock_actual'] as num?)?.toInt() ?? 0;
      if (price <= 0 || stock < line.quantity) {
        throw const CheckoutException('Precio o inventario cambió. Actualiza tu carrito.');
      }
      final lineTotal = price * line.quantity;
      total += lineTotal;
      details.add({'id_venta': 0, 'id_variante': line.variantId,
        'cantidad': line.quantity, 'precio_unitario': price, 'subtotal': lineTotal});
    }
    if (total <= 0) throw const CheckoutException('Importe inválido.');
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${user.id}/venta/${DateTime.now().microsecondsSinceEpoch}-$safeName';
    var uploaded = false;
    try {
      await _db.storage.from('comprobantes').uploadBinary(path, receipt,
        fileOptions: FileOptions(contentType: mimeType, upsert: false));
      uploaded = true;
      final date = DateTime.now();
      final today = '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final result = await _db.rpc('guardar_venta', params: {
        'p_venta': {
          'id_venta': 0,
          'id_cliente': account['id_cliente'],
          'fecha_venta': today,
          'metodo_pago': 'TRANSFERENCIA / QR',
          'subtotal': total / 1.19,
          'descuento': 0,
          'total_venta': total,
          'saldo_aplicado': 0,
          'estado': 'PENDIENTE',
          'origen': 'TIENDA_ONLINE',
          'comprobante_url': path,
          'comprobante_nombre': filename,
        },
        'p_detalles': details,
      });
      final id = result is num ? result.toInt() : int.tryParse('$result');
      if (id == null || id <= 0) {
        // RPC podría haber confirmado el pedido: no borrar su comprobante.
        throw const CheckoutException('Respuesta incierta. Revisa Mis compras antes de reintentar.');
      }
      return id;
    } on PostgrestException catch (e) {
      // No reintentar automáticamente: el RPC no ha demostrado idempotencia.
      if (uploaded) {
        // Un error SQL confirmado permite limpiar el archivo sin venta.
        try { await _db.storage.from('comprobantes').remove([path]); } catch (_) {}
      }
      throw CheckoutException('Supabase rechazó el pedido: ${e.message}');
    } on StorageException catch (e) {
      throw CheckoutException('No se pudo subir el comprobante: ${e.message}');
    }
  }
}
