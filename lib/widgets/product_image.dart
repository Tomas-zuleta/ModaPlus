import 'package:flutter/material.dart';
import '../data/catalog_data.dart';
import '../data/demo_images.dart';
import '../models/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final double? height;
  final double iconSize;
  const ProductImage({super.key, required this.product, this.height, this.iconSize = 64});

  @override
  Widget build(BuildContext context) {
    // Prioridad a las imágenes del catálogo real. Las imágenes de prueba
    // solo se utilizan en productos locales sin variante de Supabase.
    final candidate = product.variantId == null
        ? DemoImages.products[product.id]
        : product.imageUrl;
    final uri = candidate == null ? null : Uri.tryParse(candidate);
    final url = uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? candidate
        : null;
    return Container(
      height: height,
      width: double.infinity,
      color: product.tone,
      child: url == null
          ? _placeholder()
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
              semanticLabel: 'Imagen de ${product.name}',
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Stack(fit: StackFit.expand, children: [
                      _placeholder(),
                      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ]),
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() => Container(
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [product.tone, Color.lerp(product.tone, Colors.white, .55)!],
    )),
    child: Center(child: Icon(categoryIcon(product.category),
      size: iconSize, color: Colors.white.withValues(alpha: .75))),
  );
}
