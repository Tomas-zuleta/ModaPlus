import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../utils/app_colors.dart';
import '../utils/fade_route.dart';
import '../utils/format.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/product_image.dart';
import '../widgets/sans_scope.dart';
import 'payments_view.dart';
import 'plan_payment_dialog.dart';

class PlanSepareCreatePage extends StatefulWidget {
  const PlanSepareCreatePage({super.key});

  @override
  State<PlanSepareCreatePage> createState() => _PlanSepareCreatePageState();
}

class _PlanSepareCreatePageState extends State<PlanSepareCreatePage> {
  final _docCtrl = TextEditingController();
  double _percent = 0.3;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _docCtrl.text = AppStore.instance.session?.identificacion ?? '';
  }

  @override
  void dispose() {
    _docCtrl.dispose();
    super.dispose();
  }

  int get _total => AppStore.instance.cartTotal;
  int get _deposit => (_total * _percent).round();

  Future<void> _continue() async {
    if (_docCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu documento de identidad')),
      );
      return;
    }

    final selection = await showPlanPaymentDialog(
      context,
      amount: _deposit,
      title: 'Abono inicial del plan separe',
    );
    if (selection == null || !mounted) return;

    setState(() => _sending = true);
    final plan = AppStore.instance.createPlanFromCart(
      initialDeposit: _deposit,
      method: selection.method,
      voucherBytes: selection.voucherBytes,
      clientDoc: _docCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    Navigator.of(context).pushReplacement(fadeRoute(PaymentsView(plan: plan)));
  }

  @override
  Widget build(BuildContext context) {
    final cart = AppStore.instance.cart;

    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        appBar: const DetailAppBar(title: 'PLAN SEPARE'),
        body: cart.isEmpty
            ? const Center(
                child: EmptyState(
                  icon: Icons.bookmark_border,
                  message: 'Agrega productos a tu carrito para armar un plan separe',
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text(
                        'Aparta tus productos',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Paga un abono inicial hoy y completa el resto antes de la fecha de vencimiento.',
                        style: TextStyle(fontSize: 13, color: AppColors.slate),
                      ),
                      const SizedBox(height: 20),
                      for (final item in cart)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.panelBorder)),
                            child: Row(
                              children: [
                                SizedBox(width: 56, height: 56, child: ProductImage(product: item.product, iconSize: 24)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                                      Text(
                                        'Talla ${item.variant.talla.nombre} · ${item.variant.color.nombre} · x${item.quantity}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.slate),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(formatCop(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      AuthTextField(
                        label: 'Documento de identidad',
                        hint: '1234567890',
                        controller: _docCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'MONTO DEL ABONO INICIAL',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.mutedLabel),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final p in [0.3, 0.5, 1.0])
                            ChoiceChip(
                              label: Text(p == 1.0 ? '100%' : '${(p * 100).round()}%'),
                              selected: _percent == p,
                              onSelected: (_) => setState(() => _percent = p),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(color: _percent == p ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.panelBorder),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total del plan', style: TextStyle(fontSize: 13, color: AppColors.slate)),
                          Text(formatCop(_total), style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Abonas hoy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          Text(formatCop(_deposit), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(text: 'Continuar al pago', isLoading: _sending, onPressed: _continue),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}