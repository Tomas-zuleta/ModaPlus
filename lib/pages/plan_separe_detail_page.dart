import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/plan_separe.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/info_row.dart';
import '../widgets/line_item_row.dart';
import '../widgets/progress_bar.dart';
import '../widgets/sans_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';

class PlanSepareDetailPage extends StatelessWidget {
  final PlanSepare plan;
  const PlanSepareDetailPage({super.key, required this.plan});

  String get _dueText =>
      plan.daysLeft < 0 ? 'Vencido' : '${plan.daysLeft} días restantes';

  Future<void> _confirmAnnul(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular plan separe'),
        content: Text(
          'Se anulará ${plan.id} de ${plan.clientName}.\n\n${plan.annulOutcome}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular',
                style: TextStyle(color: AppColors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    AppStore.instance.annulPlan(plan);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan separe anulado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        appBar: DetailAppBar(title: plan.id),
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
                            plan.clientName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: plan.isActive ? 'Activo' : 'Anulado',
                          color: plan.isActive
                              ? AppColors.primary
                              : AppColors.redAccent,
                        ),
                      ],
                    ).stagger(0),
                    const SizedBox(height: 4),
                    Text('Documento: ${plan.clientDoc}',
                        style: const TextStyle(color: AppColors.slate)),
                    const SizedBox(height: 20),
                    SectionCard(
                      title: 'PRODUCTOS RESERVADOS',
                      child: Column(
                        children: [
                          for (final it in plan.items)
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
                      title: 'RESUMEN DE PAGOS',
                      child: Column(
                        children: [
                          InfoRow(label: 'Total', value: formatCop(plan.total)),
                          InfoRow(label: 'Abonado', value: formatCop(plan.paid)),
                          InfoRow(
                            label: 'Saldo pendiente',
                            value: formatCop(plan.balance),
                            bold: true,
                          ),
                          const SizedBox(height: 8),
                          ProgressBar(value: plan.progress),
                          const SizedBox(height: 8),
                          InfoRow(
                            label: 'Progreso',
                            value: '${(plan.progress * 100).round()}%',
                          ),
                          InfoRow(
                            label: 'Creado',
                            value: formatDate(plan.createdAt),
                          ),
                          InfoRow(
                            label: 'Vence',
                            value: '${formatDate(plan.dueDate)}'
                                '${plan.isActive ? ' · $_dueText' : ''}',
                          ),
                        ],
                      ),
                    ).stagger(2),
                    const SizedBox(height: 16),
                    SectionCard(
                      title: 'HISTORIAL DE ABONOS',
                      child: Column(
                        children: [
                          for (final a in plan.abonos)
                            InfoRow(
                              label: formatDate(a.date),
                              value: formatCop(a.amount),
                            ),
                        ],
                      ),
                    ).stagger(3),
                    if (!plan.isActive && plan.annulNote != null) ...[
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'RESULTADO DE LA ANULACIÓN',
                        child: Text(
                          plan.annulNote!,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textDark),
                        ),
                      ).stagger(4),
                    ],
                    if (plan.isActive) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => _confirmAnnul(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.redAccent,
                            side: const BorderSide(color: AppColors.redAccent),
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: const Text(
                            'ANULAR PLAN SEPARE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
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