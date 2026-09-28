import 'product.dart';
import 'product_variant.dart';

class CartItem {
  final Product product;
  final ProductVariant variant;
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  int get subtotal => variant.precioVenta * quantity;

  /// Misma línea = misma variante (mismo producto, talla y color).
  bool sameLine(CartItem other) =>
      other.product.id == product.id && other.variant.id == variant.id;
}