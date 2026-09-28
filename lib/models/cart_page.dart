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
import '../pages/order_success_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _sending = false;

  Future<void> _request() async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final order = AppStore.instance.placeOrder();
    Navigator.of(context).pushReplacement(
      fadeRoute(OrderSuccessPage(order: order)),
    );
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
            appBar: const DetailAppBar(title: 'CARRITO'),
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
                          const SizedBox(height: 6),
                          const Text(
                            'El pago y el retiro se hacen en la tienda. '
                            'El pedido tiene vigencia de 1 semana.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.slate),
                          ),
                          const SizedBox(height: 12),
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
                      child: ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: cart.length,
                        separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                        itemBuilder: (context, i) => _CartRow(item: cart[i]),
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
  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: ProductImage(product: item.product, iconSize: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  'Talla ${item.variant.talla.nombre} · ${item.variant.color.nombre}',
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
                  max: item.variant.stockActual,
                  size: 32,
                  onChanged: (v) => store.setCartQuantity(item, v),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => store.removeFromCart(item),
            icon: const Icon(Icons.delete_outline, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}