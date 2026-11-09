import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// Catálogo real: cada producto mostrado corresponde a UNA variante existente.
class RealCatalogService {
  RealCatalogService._();
  static final instance = RealCatalogService._();
  final _client = Supabase.instance.client;

  Future<List<Product>> load() async {
    final responses = await Future.wait([
      _client.from('productos').select('id_producto,id_categoria,referencia,nombre_producto,descripcion,estado').eq('estado','ACTIVO').limit(1000),
      _client.from('variantes_producto').select('id_variante,id_producto,id_talla,id_color,imagen_url,precio_venta,stock_actual,estado').eq('estado','ACTIVO').gt('stock_actual',0).limit(1000),
      _client.from('tallas').select('id_talla,nombre_talla').limit(500),
      _client.from('colores').select('id_color,nombre_color,codigo_hex').limit(500),
      _client.from('categorias').select('id_categoria,nombre_categoria,estado').eq('estado','ACTIVO').limit(500),
    ]);
    Map<int, Map<String,dynamic>> index(int response, String key) => {
      for (final row in responses[response])
        if (row[key] is num) (row[key] as num).toInt(): Map<String,dynamic>.from(row),
    };
    final products = index(0,'id_producto');
    final sizes = index(2,'id_talla');
    final colors = index(3,'id_color');
    final categories = index(4,'id_categoria');
    final result = <Product>[];
    for (final raw in responses[1]) {
      final variant = Map<String,dynamic>.from(raw);
      final product = products[(variant['id_producto'] as num?)?.toInt()];
      if (product == null) continue;
      final category = categories[(product['id_categoria'] as num?)?.toInt()];
      if (category == null) continue;
      final size = sizes[(variant['id_talla'] as num?)?.toInt()];
      final color = colors[(variant['id_color'] as num?)?.toInt()];
      if (size == null || color == null) continue;
      final id = (variant['id_variante'] as num).toInt();
      final stock = (variant['stock_actual'] as num?)?.toInt() ?? 0;
      final price = (variant['precio_venta'] as num?)?.toInt() ?? 0;
      if (stock <= 0 || price <= 0) continue;
      final hex = (color['codigo_hex'] ?? '').toString().replaceAll('#','');
      final parsed = int.tryParse(hex,radix:16);
      final swatch = parsed != null && hex.length == 6
        ? Color(0xFF000000 | parsed) : const Color(0xFF64748B);
      final sizeName = (size['nombre_talla'] ?? '').toString();
      final colorName = (color['nombre_color'] ?? '').toString();
      if (sizeName.isEmpty || colorName.isEmpty) continue;
      result.add(Product(
        id: 'variante-$id',
        variantId: id,
        name: (product['nombre_producto'] ?? 'Producto').toString(),
        sku: '${product['referencia'] ?? id} · $sizeName / $colorName',
        category: (category['nombre_categoria'] ?? 'General').toString(),
        price: price,
        stock: stock,
        description: (product['descripcion'] ?? '').toString(),
        sizes: [sizeName],
        colors: [ProductColor(colorName, swatch)],
        tone: swatch,
        imageUrl: variant['imagen_url']?.toString(),
      ));
    }
    return result;
  }
}
