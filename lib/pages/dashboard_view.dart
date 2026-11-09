import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../data/catalog_data.dart';
import '../models/order.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';

/// Panel demostrativo calculado desde AppStore. NO son datos del servidor.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ListenableBuilder(listenable: store, builder: (context, _) {
      final now = DateTime.now();
      final orders = store.orders;
      final pending = orders.where((o) => o.status == OrderStatus.pending).toList();
      final paid = orders.where((o) => o.status == OrderStatus.paid ||
          o.status == OrderStatus.delivered).toList();
      final monthSales = paid.where((o) => o.createdAt.year == now.year &&
          o.createdAt.month == now.month).fold<int>(0, (s, o) => s + o.total);
      final todaySales = paid.where((o) => o.createdAt.year == now.year &&
          o.createdAt.month == now.month && o.createdAt.day == now.day)
          .fold<int>(0, (s, o) => s + o.total);
      final lowStock = catalogProducts.where((p) => p.stock <= 5).toList();
      final stock = catalogProducts.fold<int>(0, (s, p) => s + p.stock);
      final months = List.generate(6, (i) {
        final date = DateTime(now.year, now.month - 5 + i);
        final total = paid.where((o) => o.createdAt.year == date.year &&
            o.createdAt.month == date.month).fold<int>(0, (s, o) => s + o.total);
        return (date, total);
      });
      final maxSales = months.fold<int>(1, (max, row) => row.$2 > max ? row.$2 : max);
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('DASHBOARD', style: TextStyle(fontSize: 31,
          fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        const Text('Vista de demostración · datos locales, no sincronizados',
          style: TextStyle(color: AppColors.slate, fontSize: 12)),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Metric('VENTAS DEL DÍA', formatCop(todaySales), Icons.today_rounded),
          _Metric('VENTAS DEL MES', formatCop(monthSales), Icons.trending_up_rounded),
          _Metric('STOCK ACTUAL', '$stock uds.', Icons.inventory_2_outlined),
          _Metric('PEDIDOS PENDIENTES', '${pending.length}', Icons.pending_actions_rounded),
          _Metric('PLANES SEPARE', '${store.activePlansCount}', Icons.bookmark_outline_rounded),
          _Metric('STOCK BAJO', '${lowStock.length}', Icons.warning_amber_rounded),
        ]),
        const SizedBox(height: 24),
        _Panel(title: 'VENTAS · ÚLTIMOS 6 MESES', child: SizedBox(
          height: 175,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((entry) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(entry.$2 == 0 ? '0' : '${(entry.$2 / 1000000).toStringAsFixed(1)}M',
                  style: const TextStyle(fontSize: 10, color: AppColors.slate)),
                const SizedBox(height: 5),
                AnimatedContainer(duration: const Duration(milliseconds: 500),
                  height: 12 + (entry.$2 / maxSales) * 105,
                  decoration: BoxDecoration(color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 7),
                Text('${entry.$1.month}/${entry.$1.year % 100}',
                  style: const TextStyle(fontSize: 10, color: AppColors.slate)),
              ]),
            ))).toList(),
          ),
        )),
        const SizedBox(height: 15),
        _Panel(title: 'ALERTAS DEL SISTEMA', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isEmpty && lowStock.isEmpty)
              const ListTile(leading: Icon(Icons.check_circle_outline, color: AppColors.primary),
                title: Text('Sin alertas pendientes')),
            for (final order in pending.take(5))
              ListTile(dense: true, leading: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.primary), title: Text('Pedido ${order.id} pendiente'),
                subtitle: Text('${order.clientName} · ${formatCop(order.total)}')),
            for (final product in lowStock.take(5))
              ListTile(dense: true, leading: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange), title: Text('Stock bajo: ${product.name}'),
                subtitle: Text('${product.stock} unidades disponibles')),
          ],
        )),
        const SizedBox(height: 15),
        _Panel(title: 'ÚLTIMOS PEDIDOS', child: Column(children: [
          for (final order in orders.take(5))
            ListTile(dense: true,
              title: Text('${order.id} · ${order.clientName}'),
              subtitle: Text(order.status.label),
              trailing: Text(formatCop(order.total),
                style: const TextStyle(fontWeight: FontWeight.bold))),
        ])),
      ]);
    });
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    width: (MediaQuery.sizeOf(context).width - 50) / 2,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.panelBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(label, maxLines: 2,
        style: const TextStyle(fontSize: 10, letterSpacing: .8,
          color: AppColors.slate, fontWeight: FontWeight.bold))),
        Icon(icon, size: 18, color: AppColors.primary)]),
      const SizedBox(height: 12),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
        child: Text(value, style: const TextStyle(fontSize: 20,
          fontWeight: FontWeight.w900, color: AppColors.textDark))),
    ]),
  );
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  const _Panel({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.panelBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900,
        fontSize: 13, letterSpacing: .7, color: AppColors.textDark)),
      const SizedBox(height: 17),
      child,
    ]),
  );
}
