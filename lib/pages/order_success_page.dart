import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/order.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/sans_scope.dart';
import '../widgets/section_card.dart';
import 'order_detail_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final Order order;
  const OrderSuccessPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 84,
                      color: AppColors.primary,
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: 24),
                    const Text(
                      '¡Pedido solicitado!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ).stagger(2),
                    const SizedBox(height: 8),
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ).stagger(3),
                    const SizedBox(height: 24),
                    SectionCard(
                      title: 'RESUMEN',
                      child: Column(
                        children: [
                          InfoRow(
                              label: 'Productos', value: '${order.units} und.'),
                          InfoRow(
                            label: 'Total',
                            value: formatCop(order.total),
                            bold: true,
                          ),
                          InfoRow(
                            label: 'Vigente hasta',
                            value: formatDate(order.expiresAt),
                          ),
                        ],
                      ),
                    ).stagger(4),
                    const SizedBox(height: 14),
                    const Text(
                      'Acércate a la tienda para pagar y retirar tus '
                      'productos. Si no lo haces en 1 semana, el pedido se '
                      'anula automáticamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.slate,
                      ),
                    ).stagger(5),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: 'Ver mi pedido',
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailPage(order: order, isAdmin: false),
                        ),
                      ),
                    ).stagger(6),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text(
                        'SEGUIR COMPRANDO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.slate,
                        ),
                      ),
                    ).stagger(7),
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