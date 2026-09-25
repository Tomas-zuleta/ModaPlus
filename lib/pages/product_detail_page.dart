import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/cart_fly_animation.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/sans_scope.dart';
import '../widgets/status_chip.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final GlobalKey? cartTargetKey;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.cartTargetKey,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final GlobalKey _addButtonKey = GlobalKey();
  String? _size;
  ProductColor? _color;
  int _qty = 1;

  void _add() {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    if (_size == null || _color == null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selecciona talla y color',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    if (_qty < 1 || _qty > widget.product.stock) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Máx. ${widget.product.stock} unidades',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    AppStore.instance.addToCart(
      CartItem(
        product: widget.product,
        size: _size!,
        color: _color!,
        quantity: _qty,
      ),
    );

    final targetKey = widget.cartTargetKey ?? CartFlyAnimation.cartTargetKey;
    if (_addButtonKey.currentContext != null) {
      CartFlyAnimation.play(
        context,
        sourceKey: _addButtonKey,
        targetKey: targetKey,
        child: const Icon(Icons.shopping_bag, color: Colors.white),
      );
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.panelBorder),
        ),
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Agregado al carrito',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartPage())),
              child: const Text(
                'VER',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppColors.mutedLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final cartCount = AppStore.instance.cartCount;

        return SansScope(
          child: Scaffold(
            backgroundColor: AppColors.dashboardBg,
            appBar: DetailAppBar(
              title: 'PRODUCTO',
              cartCount: cartCount,
              cartKey: CartFlyAnimation.cartTargetKey,
              onCartTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartPage())),
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.panelBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.slate,
                          ),
                        ),
                        Text(
                          formatCop(p.price * _qty),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: PrimaryButton(
                        key: _addButtonKey,
                        text: 'Agregar al carrito',
                        onPressed: _add,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  children: [
                    Hero(
                      tag: 'product-${p.id}',
                      child: ProductImage(
                        product: p,
                        height: 320,
                        iconSize: 110,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusChip(
                                label: p.category,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${p.sku}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.slate,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                formatCop(p.price),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                p.description,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ).stagger(0),
                          const SizedBox(height: 28),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('TALLA'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final s in p.sizes)
                                    _SizeChip(
                                      label: s,
                                      selected: s == _size,
                                      onTap: () => setState(() => _size = s),
                                    ),
                                ],
                              ),
                            ],
                          ).stagger(1),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(
                                _color == null
                                    ? 'COLOR'
                                    : 'COLOR · ${_color!.name.toUpperCase()}',
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final c in p.colors)
                                    _ColorDot(
                                      color: c,
                                      selected: _color?.name == c.name,
                                      onTap: () => setState(() => _color = c),
                                    ),
                                ],
                              ),
                            ],
                          ).stagger(2),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('CANTIDAD'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  QuantityStepper(
                                    value: _qty,
                                    min: 1,
                                    max: p.stock,
                                    onChanged: (v) => setState(() => _qty = v),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${p.stock} disponibles',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.slate,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ).stagger(3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.panelBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final ProductColor color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final light = color.color.computeLuminance() > 0.5;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.color,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.panelBorder,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 18,
                color: light ? AppColors.textDark : Colors.white,
              )
            : null,
      ),
    );
  }
}
