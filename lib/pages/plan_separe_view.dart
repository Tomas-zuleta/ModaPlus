import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/plan_separe.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/page_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_chip.dart';
import 'abonos_view.dart';
import 'plan_separe_create_page.dart';
import 'plan_separe_detail_page.dart';

enum _PlanFilter { all, active, closed }

class PlanSepareView extends StatefulWidget {
  final bool onlyMine;

  const PlanSepareView({super.key, this.onlyMine = false});

  @override
  State<PlanSepareView> createState() => _PlanSepareViewState();
}

class _PlanSepareViewState extends State<PlanSepareView> {
  _PlanFilter _filter = _PlanFilter.all;

  String _label(_PlanFilter filter) => switch (filter) {
    _PlanFilter.all => 'Todos',
    _PlanFilter.active => 'Activos',
    _PlanFilter.closed => 'Finalizados',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final email = (AppStore.instance.session?.email ?? '').toLowerCase();
        final plans = AppStore.instance.plans.where((plan) {
          final mine = !widget.onlyMine || plan.clientEmail.toLowerCase() == email;
          final matches = switch (_filter) {
            _PlanFilter.all => true,
            _PlanFilter.active => plan.isActive,
            _PlanFilter.closed => !plan.isActive,
          };
          return mine && matches;
        }).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                PageHeader(
                  title: widget.onlyMine ? 'Mis planes' : 'Plan Separe',
                  subtitle: widget.onlyMine
                      ? 'Tus productos apartados'
                      : 'Reservas realizadas por los clientes',
                ).stagger(0),
                if (!widget.onlyMine) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AbonosView()),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Ver abonos'),
                  ),
                ],
                if (widget.onlyMine) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Apartar productos del carrito',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PlanSepareCreatePage(),
                      ),
                    ),
                  ).stagger(1),
                ],
                const SizedBox(height: 14),
                FilterChipsRow<_PlanFilter>(
                  values: _PlanFilter.values,
                  selected: _filter,
                  labelOf: _label,
                  onSelected: (filter) => setState(() => _filter = filter),
                ).stagger(2),
                const SizedBox(height: 16),
                if (plans.isEmpty)
                  const EmptyState(
                    icon: Icons.bookmark_border,
                    message: 'No hay planes en esta categoría',
                  )
                else
                  for (var i = 0; i < plans.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(
                        plan: plans[i],
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

class _PlanCard extends StatelessWidget {
  final PlanSepare plan;
  final bool isAdmin;

  const _PlanCard({required this.plan, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlanSepareDetailPage(plan: plan, isAdmin: isAdmin),
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
                Text(plan.id),
                const Spacer(),
                StatusChip(
                  label: plan.isActive ? 'Activo' : 'Finalizado',
                  color: plan.isActive ? AppColors.primary : AppColors.slate,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plan.clientName,
              style: const TextStyle(fontSize: 18, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.items.length} producto(s) · Vence ${formatDate(plan.dueDate)}',
              style: const TextStyle(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 14),
            ProgressBar(value: plan.progress),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Abonado ${formatCop(plan.paid)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Total ${formatCop(plan.total)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}