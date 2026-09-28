import 'package:flutter/material.dart';

import 'color_producto.dart';
import 'product_variant.dart';
import 'talla.dart';

enum ProductoEstado { activo, noActivo }

class Product {
  final String id;
  final String idCategoria;
  final String category;
  final String referencia;
  final String name;
  final String description;
  final ProductoEstado estado;
  final Color tone;
  final List<String> photos;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.idCategoria,
    required this.category,
    required this.referencia,
    required this.name,
    required this.description,
    required this.tone,
    required this.variants,
    this.estado = ProductoEstado.activo,
    this.photos = const [],
  });

  /// Compatibilidad: antes se llamaba "sku".
  String get sku => referencia;

  String? get mainPhoto => photos.isEmpty ? null : photos.first;

  List<ProductVariant> get activeVariants =>
      variants.where((v) => v.isActive).toList();

  List<Talla> get availableSizes {
    final seen = <String>{};
    final list = <Talla>[];
    for (final v in activeVariants) {
      if (seen.add(v.talla.id)) list.add(v.talla);
    }
    return list;
  }

  List<ColorProducto> colorsForSize(String tallaId) {
    final seen = <String>{};
    final list = <ColorProducto>[];
    for (final v in activeVariants.where((v) => v.talla.id == tallaId)) {
      if (seen.add(v.color.id)) list.add(v.color);
    }
    return list;
  }

  ProductVariant? variantFor(String tallaId, String colorId) {
    for (final v in activeVariants) {
      if (v.talla.id == tallaId && v.color.id == colorId) return v;
    }
    return null;
  }

  int get totalStock =>
      activeVariants.fold<int>(0, (s, v) => s + v.stockActual);

  /// Precio base para mostrar en tarjetas (el menor entre las variantes).
  int get price {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.precioVenta).reduce((a, b) => a < b ? a : b);
  }
}