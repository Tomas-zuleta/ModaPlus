import 'product.dart';

class CartItem {
  final Product product;
  final String size;
  final ProductColor color;
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    required this.color,
    required this.quantity,
  });

  int get subtotal => product.price * quantity;

  /// Misma línea = mismo producto, talla y color.
  bool sameLine(CartItem other) =>
      other.product.id == product.id &&
      other.size == size &&
      other.color.name == color.name;
}