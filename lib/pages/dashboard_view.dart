import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_data_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<_DashboardData> _data;
  RealtimeChannel? _channel;
  @override
  void initState() {
    super.initState();
    _reload();
    if (Supabase.instance.client.auth.currentUser != null) {
      _channel = Supabase.instance.client.channel('mobile-dashboard-sales')
        .onPostgresChanges(event: PostgresChangeEvent.all,
          schema: 'public', table: 'ventas',
          callback: (_) { if (mounted) setState(_reload); })
        .subscribe();
    }
  }
  void _reload() => _data = _load();
  Future<_DashboardData> _load() async {
    final service = SupabaseDataService.instance;
    final results = await Future.wait([
      service.salesForAdmin(),
      service.inventoryForAdmin(),
      service.plansForAdmin(),
    ]);
    return _DashboardData(results[0], results[1], results[2]);
  }
  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<_DashboardData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No se pudo consultar el panel. Revisa permisos y conexión.'),
          TextButton(onPressed: () => setState(_reload), child: const Text('Reintentar')),
        ]));
      }
      final data = snapshot.data!;
      final theme = Theme.of(context);
      final now = DateTime.now();
      final completed = data.sales.where((s) =>
        ['APROBADA','COMPLETADA','COMPLETADO'].contains(
          (s['estado'] ?? '').toString().toUpperCase())).toList();
      final month = completed.where((s) {
        final d = DateTime.tryParse('${s['fecha_venta']}');
        return d != null && d.year == now.year && d.month == now.month;
      }).toList();
      final today = month.where((s) =>
        DateTime.tryParse('${s['fecha_venta']}')?.day == now.day).toList();
      double total(List<Map<String,dynamic>> list) => list.fold(0.0,
        (sum, s) => sum + (num.tryParse('${s['total_venta']}')?.toDouble() ?? 0));
      final pending = data.sales.where((s) =>
        (s['estado'] ?? '').toString().toUpperCase().contains('PENDIENTE')).toList();
      final low = data.stock.where((v) =>
        v['estado'] == 'ACTIVO' &&
        (num.tryParse('${v['stock_actual']}') ?? 0) <= 5).toList();
      final activePlans = data.plans.where((p) =>
        ['ACTIVO','ACTIVA'].contains((p['estado'] ?? '').toString().toUpperCase())).length;
      Widget metric(String title, String value, IconData icon) => SizedBox(
        width: (MediaQuery.sizeOf(context).width - 52) / 2,
        child: Card(child: Padding(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(title,
              style: theme.textTheme.labelSmall)),
              Icon(icon, color: theme.colorScheme.primary)]),
            const SizedBox(height: 12),
            FittedBox(child: Text(value, style: theme.textTheme.titleLarge)),
          ]))));
      return RefreshIndicator(onRefresh: () async {
        setState(_reload); await _data;
      }, child: ListView(padding: const EdgeInsets.all(18), children: [
        Text('PANEL PRINCIPAL', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Datos de Supabase · actualización manual y eventos de ventas'),
        const SizedBox(height: 15),
        Wrap(spacing: 8, runSpacing: 8, children: [
          metric('VENTAS HOY (APROBADAS)', '\$ ${total(today).toStringAsFixed(0)}', Icons.today),
          metric('VENTAS MES (APROBADAS)', '\$ ${total(month).toStringAsFixed(0)}', Icons.trending_up),
          metric('STOCK CONSULTADO', '${data.stock.fold<int>(0, (s, v) => s + ((v['stock_actual'] as num?)?.toInt() ?? 0))}', Icons.inventory_2_outlined),
          metric('PLANES ACTIVOS', '$activePlans', Icons.bookmark_outline),
          metric('PEDIDOS PENDIENTES', '${pending.length}', Icons.pending_actions),
          metric('STOCK BAJO (≤5)', '${low.length}', Icons.warning_amber_rounded),
        ]),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ALERTAS', style: theme.textTheme.titleLarge),
            if (pending.isEmpty && low.isEmpty)
              const ListTile(title: Text('Sin alertas en los registros consultados')),
            for (final s in pending.take(12))
              ListTile(leading: const Icon(Icons.receipt_long),
                title: Text('Pedido #${s['id_venta']} pendiente'),
                subtitle: Text('Revisar comprobante y estado de pago')),
            for (final v in low.take(12))
              ListTile(leading: const Icon(Icons.warning_amber_rounded),
                title: Text('Variante #${v['id_variante']} con stock bajo'),
                subtitle: Text('Unidades: ${v['stock_actual']}')),
          ]))),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VENTAS POR MES', style: theme.textTheme.titleLarge),
            for (var m = 1; m <= 12; m++) ...[
              Builder(builder: (context) {
                final amount = total(completed.where((s) {
                  final d = DateTime.tryParse('${s['fecha_venta']}');
                  return d != null && d.year == now.year && d.month == m;
                }).toList());
                final maxAmount = total(completed);
                return Padding(padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    SizedBox(width: 28, child: Text('$m')),
                    Expanded(child: LinearProgressIndicator(
                      value: maxAmount > 0 ? (amount / maxAmount).clamp(0, 1) : 0,
                      minHeight: 12, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 9),
                    SizedBox(width: 78, child: Text(amount.toStringAsFixed(0),
                      textAlign: TextAlign.right)),
                  ]));
              }),
            ],
          ]))),
        const SizedBox(height: 12),
        Text('Cifras parciales: máximo 500 ventas, 500 variantes y 500 planes. '
          'Stock bajo utiliza umbral visual de 5 unidades. '
          'No se considera el comprobante como pago aprobado.',
          style: theme.textTheme.bodySmall),
      ]));
    },
  );
}
class _DashboardData {
  final List<Map<String,dynamic>> sales;
  final List<Map<String,dynamic>> stock;
  final List<Map<String,dynamic>> plans;
  const _DashboardData(this.sales, this.stock, this.plans);
}
