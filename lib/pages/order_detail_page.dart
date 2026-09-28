import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/order.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/info_row.dart';
import '../widgets/line_item_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/sans_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;
  final bool isAdmin;

  const OrderDetailPage({super.key, required this.order, required this.isAdmin});

   bool get _open =>
      order.status == OrderStatus.requested ||
      order.status == OrderStatus.verification ||
      order.status == OrderStatus.partial;

  String get _vigencia =>
      order.daysLeft < 0 ? 'Vencido' : '${order.daysLeft} día(s) restantes';

  Future<int?> _askAbono(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valor abonado'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            hintText: 'Máx. ${formatCop(order.total - 1)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v > 0 && v < order.total) Navigator.pop(ctx, v);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context) async {
    final selected = await showModalBottomSheet<OrderStatus>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'CAMBIAR ESTADO A',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.slate,
                ),
              ),
            ),
            for (final s in order.status.next)
              ListTile(
                leading: CircleAvatar(radius: 6, backgroundColor: s.color),
                title: Text(s.label),
                onTap: () => Navigator.pop(ctx, s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;

    int? paid;
    if (selected == OrderStatus.partial) {
      paid = await _askAbono(context);
      if (paid == null || !context.mounted) return;
    }

    AppStore.instance.changeOrderStatus(order, selected, paid: paid);
    if (selected == OrderStatus.paid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El cliente ha pagado el pedido ${order.id}. '
            'Notificación enviada al cliente.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido ${order.id}: ${selected.label}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        appBar: DetailAppBar(title: order.id),
        body: ListenableBuilder(
          listenable: AppStore.instance,
          builder: (context, _) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.clientName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: order.status.label,
                          color: order.status.color,
                        ),
                      ],
                    ).stagger(0),
                    const SizedBox(height: 4),
                    Text(order.clientEmail,
                        style: const TextStyle(color: AppColors.slate)),
                    const SizedBox(height: 20),
                    SectionCard(
                      title: 'PRODUCTOS DEL PEDIDO',
                      child: Column(
                        children: [
                          for (final it in order.items)
                            LineItemRow(
                              name: it.name,
                              detail:
                                  'Talla ${it.size} · ${it.color} · x${it.quantity}',
                              price: formatCop(it.subtotal),
                            ),
                        ],
                      ),
                    ).stagger(1),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'PAGOS',
                      child: Column(
                        children: [
                          InfoRow(label: 'Total', value: formatCop(order.total)),
                          InfoRow(label: 'Pagado', value: formatCop(order.paid)),
                          InfoRow(
                            label: 'Saldo pendiente',
                            value: formatCop(order.balance),
                            bold: true,
                          ),
                        ],
                      ),
                    ).stagger(2),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'INFORMACIÓN',
                      child: Column(
                        children: [
                          InfoRow(label: 'Canal', value: order.channel),
                          InfoRow(
                            label: 'Fecha',
                            value: formatDate(order.createdAt),
                          ),
                          InfoRow(
                            label: 'Vigencia (1 semana)',
                            value: _open
                                ? '${formatDate(order.expiresAt)} · $_vigencia'
                                : formatDate(order.expiresAt),
                          ),
                        ],
                      ),
                    ).stagger(3),
                    if (order.status == OrderStatus.cancelled &&
                        order.paid > 0) ...[
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'NOTA',
                        child: Text(
                          'El abono de ${formatCop(order.paid)} queda a favor '
                          'del cliente por 2 semanas adicionales. Si no se '
                          'presenta en ese lapso, pasa a favor de la tienda.',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textDark),
                        ),
                      ).stagger(4),
                    ],
                    if (isAdmin && order.status.next.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Cambiar estado',
                        onPressed: () => _changeStatus(context),
                      ).stagger(4),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}