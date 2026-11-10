import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_permissions.dart';
import '../services/administrative_transactions.dart';
import 'transaction_entry_page.dart';
import 'layaway_payment_sheet.dart';

/// Plan Separe del administrador: solo datos reales de Supabase.
/// No usa los ejemplos locales del AppStore.
class PlanSepareView extends StatefulWidget {
  const PlanSepareView({super.key});
  @override
  State<PlanSepareView> createState() => _PlanSepareViewState();
}

class _PlanSepareViewState extends State<PlanSepareView> {
  late Future<List<_PlanSummary>> _plans;
  String _filter = 'TODOS';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => _plans = _load();

  Future<List<_PlanSummary>> _load() async {
    await AdminPermissions.instance.require('separe', 'view');
    final db = Supabase.instance.client;
    final results = await Future.wait([
      db.from('planes_separe')
        .select('id_plan_separe,id_cliente,fecha_inicio,fecha_vencimiento,estado,abono_inicial,clientes(nombres,apellidos)')
        .order('id_plan_separe', ascending: false).limit(250),
      db.from('detalles_plan_separe')
        .select('id_plan_separe,cantidad,precio_unitario').limit(1500),
      db.from('abonos_separe')
        .select('id_plan_separe,valor_abono,estado').limit(1500),
    ]);
    final details = results[1];
    final payments = results[2];
    return results[0].map((row) {
      final id = (row['id_plan_separe'] as num).toInt();
      final clientRaw = row['clientes'];
      final client = clientRaw is List
        ? (clientRaw.isNotEmpty ? clientRaw.first : null) : clientRaw;
      final clientMap = client is Map ? client : <String, dynamic>{};
      final name = '${clientMap['nombres'] ?? ''} ${clientMap['apellidos'] ?? ''}'.trim();
      final total = details.where((line) => line['id_plan_separe'] == id)
        .fold<double>(0, (sum, line) => sum +
          ((line['cantidad'] as num?)?.toDouble() ?? 0) *
          ((line['precio_unitario'] as num?)?.toDouble() ?? 0));
      final paid = ((row['abono_inicial'] as num?)?.toDouble() ?? 0)
        + payments.where((p) => p['id_plan_separe'] == id
          && (p['estado'] ?? 'ACTIVO').toString().toUpperCase() == 'ACTIVO')
            .fold<double>(0, (sum, p) => sum +
              ((p['valor_abono'] as num?)?.toDouble() ?? 0));
      return _PlanSummary(
        id: id, name: name.isEmpty ? 'Cliente #${row['id_cliente']}' : name,
        state: row['estado']?.toString() ?? 'Sin estado',
        due: row['fecha_vencimiento']?.toString() ?? '-',
        total: total, paid: paid,
      );
    }).toList();
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const TransactionEntryPage(module: 'separe')));
    if (saved == true && mounted) setState(_refresh);
  }

  Future<void> _pay(_PlanSummary plan) async {
    final allowed = await AdminPermissions.instance.can('abonos', 'create');
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No tienes permiso para registrar abonos.')));
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      useSafeArea: true, showDragHandle: false,
      builder: (_) => LayawayPaymentSheet(
        planId: plan.id, balance: plan.balance),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Abono guardado correctamente.')));
      setState(_refresh);
    }
  }

  Future<void> _annul(_PlanSummary plan) async {
    final allowed = await AdminPermissions.instance.can('separe', 'annul');
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No tienes permiso para anular planes.')));
      return;
    }
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Anular Plan Separe'),
        content: Text('¿Anular el plan #${plan.id} de ${plan.name}? '
          'La reserva y los abonos se liquidarán según las reglas del servidor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar anulación')),
        ],
      ));
    if (yes != true || !mounted) return;
    try {
      await AdministrativeTransactions.instance.annulLayaway(plan.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan anulado por Supabase.')));
      setState(_refresh);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo anular: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PlanSummary>>(
      future: _plans,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async { setState(_refresh); await _plans; },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Plan Separe', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Consulta reservas, revisa cuánto han pagado '
                'y registra los abonos en un solo lugar.'),
              const SizedBox(height: 20),
              FutureBuilder<bool>(
                future: AdminPermissions.instance.can('separe', 'create'),
                builder: (context, result) => result.data == true
                  ? FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear un Plan Separe'))
                  : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              if (snapshot.hasError) ...[
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text('No pudimos cargar los planes. '
                  'Comprueba tu conexión y los permisos en Supabase.'),
                TextButton(onPressed: () => setState(_refresh),
                  child: const Text('Reintentar')),
              ] else ...[
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'TODOS', label: Text('Todos')),
                    ButtonSegment(value: 'ACTIVO', label: Text('Activos')),
                    ButtonSegment(value: 'ANULADO', label: Text('Anulados')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (choice) =>
                    setState(() => _filter = choice.first),
                ),
                const SizedBox(height: 16),
                if (snapshot.data!.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.bookmark_add_outlined, size: 52),
                      SizedBox(height: 12),
                      Text('Todavía no hay planes registrados.'),
                      Text('Usa el botón Crear un Plan Separe para empezar.'),
                    ]),
                  )),
                for (final plan in snapshot.data!.where((p) =>
                  _filter == 'TODOS' ||
                  (_filter == 'ACTIVO' && p.isActive) ||
                  (_filter == 'ANULADO' && !p.isActive)))
                  Card(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Plan #${plan.id} · ${plan.name}',
                          style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Estado: ${plan.state} · Vence: ${plan.due}'),
                        const SizedBox(height: 12),
                        Text('Total: COP ${plan.total.toStringAsFixed(0)}'),
                        Text('Abonado: COP ${plan.paid.toStringAsFixed(0)}'),
                        Text('Falta pagar: COP ${plan.balance.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: plan.total > 0
                          ? (plan.paid / plan.total).clamp(0.0, 1.0) : 0),
                        if (plan.isActive && plan.balance > 0) ...[
                          const SizedBox(height: 15),
                          FilledButton.icon(
                            onPressed: () => _pay(plan),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Registrar abono')),
                        ],
                        if (plan.isActive)
                          TextButton.icon(
                            onPressed: () => _annul(plan),
                            icon: const Icon(Icons.block_outlined),
                            label: const Text('Anular plan')),
                      ],
                    ),
                  )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlanSummary {
  final int id;
  final String name, state, due;
  final double total, paid;
  const _PlanSummary({required this.id, required this.name,
    required this.state, required this.due,
    required this.total, required this.paid});
  bool get isActive => state.toUpperCase() == 'ACTIVO';
  double get balance => (total - paid).clamp(0.0, double.infinity);
}
