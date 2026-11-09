import 'package:flutter/material.dart';
import '../models/product.dart';
import '../pages/product_detail_page.dart';
import '../utils/format.dart';
import 'product_image.dart';

class ProductTile extends StatefulWidget {
  final Product product;
  const ProductTile({super.key, required this.product});
  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Semantics(
      button: true,
      label: 'Ver ${p.name}, ${formatCop(p.price)}',
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? .965 : 1,
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductDetailPage(product: p),
              )),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(tag: 'product-${p.id}', child: ProductImage(product: p)),
                    )),
                    const SizedBox(height: 10),
                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 5),
                    Text(formatCop(p.price),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
