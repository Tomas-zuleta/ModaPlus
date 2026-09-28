import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/order.dart';
import '../models/plan_separe.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/primary_button.dart';
import '../widgets/sans_scope.dart';

class PaymentsView extends StatelessWidget {
  final Order? order;
  final PlanSepare? plan;

  const PaymentsView({super.key, this.order, this.plan})
      : assert(order != null || plan != null);

  @override
  Widget build(BuildContext context) {
    final isPlan = plan != null;
    final id = isPlan ? plan!.id : order!.id;
    final client = isPlan ? plan!.clientName : order!.clientName;
    final date = isPlan ? plan!.createdAt : order!.createdAt;
    final total = isPlan ? plan!.total : order!.total;
    final paidNow = isPlan ? plan!.abonos.first.amount : order!.paid;
    final method = isPlan ? plan!.abonos.first.method : order!.paymentMethod;
    final balance = isPlan ? plan!.balance : order!.balance;

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
                    const Icon(Icons.check_circle_outline, size: 76, color: AppColors.primary)
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 300.ms),
                    const SizedBox(height: 18),
                    Text(
                      isPlan ? '¡Plan separe registrado!' : '¡Pago realizado!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 24),
                    _Receipt(
                      id: id,
                      client: client,
                      date: date,
                      items: isPlan
                          ? plan!.items
                              .map((i) => _ReceiptLine(i.name, '${i.size} · ${i.color} · x${i.quantity}', i.subtotal))
                              .toList()
                          : order!.items
                              .map((i) => _ReceiptLine(i.name, '${i.size} · ${i.color} · x${i.quantity}', i.subtotal))
                              .toList(),
                      total: total,
                      paidNow: paidNow,
                      balance: balance,
                      method: method,
                      isPlan: isPlan,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Volver al inicio',
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
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

class _ReceiptLine {
  final String name;
  final String detail;
  final int amount;
  const _ReceiptLine(this.name, this.detail, this.amount);
}

class _Receipt extends StatelessWidget {
  final String id, client, method;
  final DateTime date;
  final List<_ReceiptLine> items;
  final int total, paidNow, balance;
  final bool isPlan;

  const _Receipt({
    required this.id,
    required this.client,
    required this.date,
    required this.items,
    required this.total,
    required this.paidNow,
    required this.balance,
    required this.method,
    required this.isPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.panelBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'MODA PLUS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, letterSpacing: 5, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              isPlan ? 'COMPROBANTE PLAN SEPARE' : 'FACTURA DE VENTA',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.slate),
            ),
          ),
          const SizedBox(height: 16),
          const _Divider(),
          const SizedBox(height: 12),
          _row('N.º', id),
          _row('Cliente', client),
          _row('Fecha', formatDate(date)),
          _row('Método', method),
          const SizedBox(height: 12),
          const _Divider(),
          const SizedBox(height: 12),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.name, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                        Text(it.detail, style: const TextStyle(fontSize: 11, color: AppColors.slate)),
                      ],
                    ),
                  ),
                  Text(formatCop(it.amount), style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const _Divider(),
          const SizedBox(height: 12),
          _row('Total', formatCop(total), bold: true),
          _row(isPlan ? 'Abono de hoy' : 'Pagado', formatCop(paidNow), highlight: true),
          if (isPlan) _row('Saldo pendiente', formatCop(balance)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold || highlight ? 15 : 13,
              fontWeight: bold || highlight ? FontWeight.w700 : FontWeight.w400,
              color: highlight ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(height: 1, color: AppColors.panelBorder);
}