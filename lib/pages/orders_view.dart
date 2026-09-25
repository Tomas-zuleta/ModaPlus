import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/order.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/status_chip.dart';
import 'order_detail_page.dart';

class OrdersView extends StatefulWidget {
  final bool onlyMine;
  const OrdersView({super.key, this.onlyMine = false});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final email = (store.session?.email ?? '').toLowerCase();
        final orders = store.orders.where((o) {
          final mine = !widget.onlyMine || o.clientEmail.toLowerCase() == email;
          final byStatus = _filter == null || o.status == _filter;
          return mine && byStatus;
        }).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                Text(
                  widget.onlyMine ? 'Mis Pedidos' : 'Pedidos',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).stagger(0),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.panelBorder)),
                  ),
                  child: Text(
                    widget.onlyMine
                        ? 'Seguimiento de tus solicitudes'
                        : 'Pedidos de todos los canales de atención',
                    style: const TextStyle(fontSize: 17, color: AppColors.textDark),
                  ),
                ).stagger(1),
                const SizedBox(height: 20),
                FilterChipsRow<OrderStatus?>(
                  values: <OrderStatus?>[null, ...OrderStatus.values],
                  selected: _filter,
                  labelOf: (s) => s == null ? 'Todos' : s.label,
                  onSelected: (s) => setState(() => _filter = s),
                ).stagger(2),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No hay pedidos para mostrar',
                  )
                else
                  for (int i = 0; i < orders.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderCard(
                        order: orders[i],
                        isAdmin: !widget.onlyMine,
                      ).stagger(i > 5 ? 5 : i + 3),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isAdmin;
  const _OrderCard({required this.order, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(order: order, isAdmin: isAdmin),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.slate,
                  ),
                ),
                               const Spacer(),
                StatusChip(label: order.status.label, color: order.status.color),
                const SizedBox(width: 8),
                const Icon(Icons.visibility_outlined, size: 18, color: AppColors.slate),
              ],
            ),
            const SizedBox(height: 10),
            if (isAdmin) ...[
              Text(order.clientName,
                  style: const TextStyle(fontSize: 18, color: AppColors.textDark)),
              const SizedBox(height: 4),
            ],
            Text(
              '${formatDate(order.createdAt)} · ${order.units} und. · ${order.channel}',
              style: const TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 12),
            Text(
              formatCop(order.total),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}