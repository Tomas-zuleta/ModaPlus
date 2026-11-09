import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/cart_item.dart';
import '../utils/app_colors.dart';
import '../utils/fade_route.dart';
import '../utils/format.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/sans_scope.dart';
import 'order_success_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _sending = false;

  Future<void> _request() async {
    // Nunca confirmar una compra únicamente en memoria.
    // Falta integrar el RPC transaccional de ventas e inventario existente.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Los pedidos reales aún no están habilitados. '
        'Estamos validando la conexión segura con Supabase.'),
      duration: Duration(seconds: 5),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cart = store.cart;

        return SansScope(
          child: Scaffold(
            backgroundColor: AppColors.dashboardBg,
            appBar: const DetailAppBar(title: 'MI CARRITO'),
            bottomNavigationBar: cart.isEmpty
                ? null
                : Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(top: BorderSide(color: AppColors.panelBorder)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: AppColors.slate,
                                ),
                              ),
                              Text(
                                formatCop(store.cartTotal),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'El pago y el retiro se hacen en la tienda. '
                            'El pedido tiene vigencia de 1 semana.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.slate),
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            text: 'Solicitar pedido',
                            isLoading: _sending,
                            onPressed: _request,
                          ),
                        ],
                      ),
                    ),
                  ),
            body: cart.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EmptyState(
                            icon: Icons.shopping_bag_outlined,
                            message: 'Tu carrito está vacío',
                          ),
                          PrimaryButton(
                            text: 'Explorar catálogo',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        children: [
                          const Text('TU SELECCIÓN', style: TextStyle(
                            fontSize: 27, fontWeight: FontWeight.w900,
                            letterSpacing: 1.4, color: AppColors.textDark)),
                          const SizedBox(height: 5),
                          Text('${store.cartCount} artículo(s) en tu carrito',
                            style: const TextStyle(color: AppColors.slate)),
                          const SizedBox(height: 23),
                          for (final item in cart) ...[
                            _CartRow(key: ValueKey('${item.product.id}-${item.size}-${item.color.name}'), item: item),
                            const SizedBox(height: 13),
                          ],
                          const SizedBox(height: 10),
                          TextButton.icon(onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('SEGUIR COMPRANDO')),
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

class _CartRow extends StatelessWidget {
  final CartItem item;
  const _CartRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.panelBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(
            width: 100,
            height: 130,
            child: ProductImage(product: item.product, iconSize: 34),
          )),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  'Talla ${item.size} · ${item.color.name}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCop(item.subtotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                QuantityStepper(
                  value: item.quantity,
                  min: 1,
                  max: item.product.stock,
                  size: 32,
                  onChanged: (v) => store.setCartQuantity(item, v),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => store.removeFromCart(item),
            tooltip: 'Eliminar producto',
            icon: const Icon(Icons.close_rounded, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}