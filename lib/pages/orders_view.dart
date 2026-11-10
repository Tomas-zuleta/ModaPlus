import 'package:flutter/material.dart';
import '../services/supabase_data_service.dart';
import 'sale_review_page.dart';
import 'transaction_entry_page.dart';
import '../services/admin_permissions.dart';

class OrdersView extends StatefulWidget {
  final bool onlyMine;
  const OrdersView({super.key, this.onlyMine = false});
  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  late Future<List<Map<String, dynamic>>> _orders;
  String? _status;
  @override
  void initState() { super.initState(); _reload(); }
  Future<void> _newSale() async {
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const TransactionEntryPage(module: 'ventas')));
    if (saved == true && mounted) setState(_reload);
  }
  void _reload() {
    _orders = widget.onlyMine
      ? SupabaseDataService.instance.myOrders()
      : SupabaseDataService.instance.recentSalesForAdmin();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _orders,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No fue posible cargar los pedidos desde Supabase.',
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton(onPressed: () => setState(_reload),
              child: const Text('Reintentar')),
          ])));
      }
      final all = snapshot.data ?? [];
      final statuses = all.map((o) => (o['estado'] ?? 'Sin estado').toString())
        .toSet().toList()..sort();
      final filtered = all.where((o) => _status == null ||
        (o['estado'] ?? 'Sin estado').toString() == _status).toList();
      return RefreshIndicator(onRefresh: () async {
        setState(_reload);
        await _orders;
      }, child: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Expanded(child: Text(widget.onlyMine ? 'Mis compras' : 'Pedidos y ventas',
            style: Theme.of(context).textTheme.headlineSmall)),
          IconButton(onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh)),
        ]),
        if (!widget.onlyMine) ...[
          const SizedBox(height: 14),
          FutureBuilder<bool>(
            future: AdminPermissions.instance.can('ventas', 'create'),
            builder: (context, allowed) => allowed.data == true
              ? FilledButton.icon(
                  onPressed: _newSale,
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Nueva venta · Elegir cliente y productos'))
              : const SizedBox.shrink(),
          ),
        ],
        const SizedBox(height: 8),
        Text('${all.length} registros consultados en Supabase',
          style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 15),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [
            ChoiceChip(label: const Text('Todos'), showCheckmark: false, selected: _status == null,
              onSelected: (_) => setState(() => _status = null)),
            const SizedBox(width: 8),
            for (final status in statuses) ...[
              ChoiceChip(label: Text(status), showCheckmark: false, selected: _status == status,
                onSelected: (_) => setState(() => _status = status)),
              const SizedBox(width: 8),
            ],
          ])),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24),
            child: Column(children: [
              Icon(Icons.receipt_long_outlined, size: 48),
              SizedBox(height: 12),
              Text('Aún no hay ventas en esta categoría.'),
              Text('Para comenzar, toca Nueva venta y elige un cliente y sus productos.'),
            ]))),
        for (final order in filtered)
          Card(child: ListTile(
            onTap: () {
              final id = (order['id_venta'] as num?)?.toInt();
              if (id != null) Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SaleReviewPage(saleId: id,
                  isAdmin: !widget.onlyMine)));
            },
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text('Factura #${order['id_venta']}'),
            subtitle: Text('${order['fecha_venta'] ?? '-'} · '
              '${order['estado'] ?? 'Sin estado'}'),
            trailing: Text('\$ ${order['total_venta'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
      ]));
    },
  );
}
