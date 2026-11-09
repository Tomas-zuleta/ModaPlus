import 'package:flutter/material.dart';
import '../services/supabase_data_service.dart';

/// Dashboard real de solo lectura. Nunca sustituye errores por cifras ficticias.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}
class _DashboardViewState extends State<DashboardView> {
  late Future<List<Map<String, dynamic>>> _sales;
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() => _sales = SupabaseDataService.instance.recentSalesForAdmin();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sales,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No se pudo cargar el dashboard desde Supabase.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(_reload),
              child: const Text('Reintentar')),
          ]));
        }
        final rows = snapshot.data ?? [];
        final now = DateTime.now();
        final month = rows.where((r) {
          final d = DateTime.tryParse((r['fecha_venta'] ?? '').toString());
          return d != null && d.year == now.year && d.month == now.month;
        }).toList();
        final today = month.where((r) {
          final d = DateTime.tryParse((r['fecha_venta'] ?? '').toString());
          return d != null && d.day == now.day;
        }).toList();
        int total(Iterable<Map<String, dynamic>> list) => list.fold(0,
          (sum, r) => sum + ((r['total_venta'] as num?)?.toInt() ?? 0));
        final pending = rows.where((r) =>
          ['PENDIENTE', 'PENDIENTE_APROBACION'].contains(
            (r['estado'] ?? '').toString().toUpperCase())).toList();
        Widget metric(String title, String value, IconData icon) => SizedBox(
          width: (MediaQuery.sizeOf(context).width - 52) / 2,
          child: Card(child: Padding(padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(title,
                style: theme.textTheme.labelSmall)),
                Icon(icon, color: theme.colorScheme.primary)]),
              const SizedBox(height: 14),
              FittedBox(child: Text(value, style: theme.textTheme.titleLarge)),
            ]))));
        return RefreshIndicator(onRefresh: () async {
          setState(_reload);
          await _sales;
        }, child: ListView(padding: const EdgeInsets.all(18), children: [
          Text('PANEL PRINCIPAL', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text('Datos reales · últimos ${rows.length} registros consultados',
            style: theme.textTheme.bodySmall),
          const SizedBox(height: 18),
          Wrap(spacing: 10, runSpacing: 10, children: [
            metric('VENTAS DEL DÍA', '$ ${total(today)}', Icons.today),
            metric('VENTAS DEL MES', '$ ${total(month)}', Icons.trending_up),
            metric('REGISTROS CONSULTADOS', '${rows.length}', Icons.receipt_long),
            metric('PENDIENTES', '${pending.length}', Icons.pending_actions),
          ]),
          const SizedBox(height: 18),
          Card(child: Padding(padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ALERTAS DE PEDIDOS', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              if (pending.isEmpty) const Text('Sin pedidos pendientes en los registros consultados'),
              for (final r in pending.take(10))
                ListTile(leading: const Icon(Icons.notifications_active_outlined),
                  title: Text('Pedido #${r['id_venta']} pendiente'),
                  subtitle: Text('Estado: ${r['estado']}')),
            ]))),
          const SizedBox(height: 15),
          Card(child: Padding(padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ÚLTIMAS VENTAS', style: theme.textTheme.titleMedium),
              for (final r in rows.take(8))
                ListTile(title: Text('Factura #${r['id_venta']}'),
                  subtitle: Text('${r['estado']} · ${r['fecha_venta']}'),
                  trailing: Text('$ ${r['total_venta'] ?? 0}')),
            ]))),
          const SizedBox(height: 12),
          Text('Vista parcial (máximo 100 ventas). Las cifras no representan '
            'necesariamente el total contable. Los pagos y el inventario '
            'requieren validación del servidor.',
            style: theme.textTheme.bodySmall),
        ]));
      },
    );
  }
}
