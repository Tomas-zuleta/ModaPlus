import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/cart_item.dart';
import '../models/color_producto.dart';
import '../models/product.dart';
import '../models/talla.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/sans_scope.dart';
import '../widgets/status_chip.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Talla? _talla;
  ColorProducto? _color;
  int _qty = 1;

  List<ColorProducto> get _colorsForTalla =>
      _talla == null ? const [] : widget.product.colorsForSize(_talla!.id);

  int get _maxStock {
    final v = _talla != null && _color != null
        ? widget.product.variantFor(_talla!.id, _color!.id)
        : null;
    return v?.stockActual ?? 1;
  }

  int get _unitPrice {
    final v = _talla != null && _color != null
        ? widget.product.variantFor(_talla!.id, _color!.id)
        : null;
    return v?.precioVenta ?? widget.product.price;
  }

  void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _selectTalla(Talla t) {
    setState(() {
      _talla = t;
      _color = null;
      _qty = 1;
    });
  }

  void _selectColor(ColorProducto c) {
    setState(() {
      _color = c;
      _qty = 1;
    });
  }

  void _add() {
    if (_talla == null || _color == null) {
      _showToast(
        context,
        message: 'Selecciona la talla y el color',
        icon: Icons.error_outline,
        color: AppColors.error,
      );
      return;
    }

    final variant = widget.product.variantFor(_talla!.id, _color!.id);
    if (variant == null || !variant.hasStock) {
      _showToast(
        context,
        message: 'Sin stock disponible para esta combinación',
        icon: Icons.error_outline,
        color: AppColors.error,
      );
      return;
    }

    AppStore.instance.addToCart(
      CartItem(
        product: widget.product,
        variant: variant,
        quantity: _qty,
      ),
    );

    _showToast(
      context,
      message: 'Se agregó "${widget.product.name}" al carrito',
      icon: Icons.check_circle,
      color: AppColors.primary,
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

    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        appBar: const DetailAppBar(title: 'PRODUCTO'),
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
                      formatCop(_unitPrice * _qty),
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
                  child: ProductImage(product: p, height: 320, iconSize: 110),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusChip(label: p.category, color: AppColors.primary),
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
                            'Referencia: ${p.referencia}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: AppColors.slate,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            formatCop(_unitPrice),
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
                              for (final t in p.availableSizes)
                                _SizeChip(
                                  label: t.nombre,
                                  selected: t.id == _talla?.id,
                                  onTap: () => _selectTalla(t),
                                ),
                            ],
                          ),
                        ],
                      ).stagger(1),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(_color == null
                              ? 'COLOR'
                              : 'COLOR · ${_color!.nombre.toUpperCase()}'),
                          const SizedBox(height: 10),
                          if (_talla == null)
                            const Text(
                              'Selecciona primero la talla',
                              style: TextStyle(fontSize: 13, color: AppColors.slate),
                            )
                          else
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final c in _colorsForTalla)
                                  _ColorDot(
                                    color: c,
                                    selected: _color?.id == c.id,
                                    onTap: () => _selectColor(c),
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
                                max: _maxStock,
                                onChanged: (v) => setState(() => _qty = v),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _talla != null && _color != null
                                    ? '$_maxStock disponibles'
                                    : 'Elige talla y color',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.slate),
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
  final ColorProducto color;
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