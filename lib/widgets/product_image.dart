import 'package:flutter/material.dart';

import '../data/catalog_data.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final double? height;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.product,
    this.height,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            product.tone,
            Color.lerp(product.tone, Colors.white, 0.55)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          categoryIcon(product.category),
          size: iconSize,
          color: Colors.white.withOpacity(0.75),
        ),
      ),
    );
  }
}