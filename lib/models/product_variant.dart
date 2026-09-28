import 'color_producto.dart';
import 'talla.dart';

enum VarianteEstado { activo, noActivo }

class ProductVariant {
  final String id;
  final String productId;
  final Talla talla;
  final ColorProducto color;
  final int precioVenta;
  final int stockActual;
  final int stockMinimo;
  final int stockMaximo;
  final VarianteEstado estado;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.talla,
    required this.color,
    required this.precioVenta,
    required this.stockActual,
    this.stockMinimo = 3,
    this.stockMaximo = 50,
    this.estado = VarianteEstado.activo,
  });

  bool get isActive => estado == VarianteEstado.activo;
  bool get hasStock => stockActual > 0;
  bool get isLowStock => stockActual <= stockMinimo;
}