import 'package:flutter/material.dart';

class ProductColor {
  final String name;
  final Color color;
  const ProductColor(this.name, this.color);
}

class Product {
  final String id;
  final String name;
  final String sku;
  final String category;
  final int price;
  final int stock;
  final String description;
  final List<String> sizes;
  final List<ProductColor> colors;
  final Color tone;
  final String? assetPath;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    required this.sizes,
    required this.colors,
    required this.tone,
    this.assetPath,
  });
}