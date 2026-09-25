import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/plan_separe.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/progress_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';
import 'plan_separe_create_page.dart';
import 'plan_separe_detail_page.dart';

enum PlanFilter { all, active, completed, cancelled }

class PlanSepareView extends StatefulWidget {
  const PlanSepareView({super.key});

  @override
  State<PlanSepareView> createState() => _PlanSepareViewState();
}

class _PlanSepareViewState extends State<PlanSepareView> {
  PlanFilter _filter = PlanFilter.all;

  String _label(PlanFilter f) => switch (f) {
    PlanFilter.all => 'Todos',
    PlanFilter.active => 'Activos',
    PlanFilter.completed => 'Pagados',
    PlanFilter.cancelled => 'Anulados',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final plans = AppStore.instance.plans.where((p) {
          switch (_filter) {
            case PlanFilter.all:
              return true;
            case PlanFilter.active:
              return p.isActive;
            case PlanFilter.completed:
              return p.status == PlanStatus.completed;
            case PlanFilter.cancelled:
              return p.status == PlanStatus.cancelled;
          }
        }).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                const Text(
                  'Plan Separe',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).stagger(0),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.panelBorder),
                    ),
                  ),
                  child: const Text(
                    'Reservas realizadas por los clientes',
                    style: TextStyle(fontSize: 17, color: AppColors.textDark),
                  ),
                ).stagger(1),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Nuevo plan separe',
                  onPressed: () async {
                    final plan = await Navigator.of(context).push<PlanSepare>(
                      MaterialPageRoute(
                        builder: (_) => const PlanSepareCreatePage(),
                      ),
                    );
                    if (plan != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlanSepareDetailPage(plan: plan),
                        ),
                      );
                    }
                  },
                ).stagger(2),
                const SizedBox(height: 20),
                FilterChipsRow<PlanFilter>(
                  values: PlanFilter.values,
                  selected: _filter,
                  labelOf: _label,
                  onSelected: (f) => setState(() => _filter = f),
                ).stagger(3),
                const SizedBox(height: 16),
                if (plans.isEmpty)
                  const EmptyState(
                    icon: Icons.bookmark_border,
                    message: 'No hay planes separe en esta categoría',
                  )
                else
                  for (int i = 0; i < plans.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(
                        plan: plans[i],
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
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlanSepareDetailPage(plan: plan)),
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
                  plan.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.slate,
                  ),
                ),
                const Spacer(),
                StatusChip(
                  label: plan.status.label,
                  color: switch (plan.status) {
                    PlanStatus.active => AppColors.primary,
                    PlanStatus.completed => AppColors.navy,
                    PlanStatus.cancelled => AppColors.redAccent,
                  },
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
                  'Saldo ${formatCop(plan.balance)}',
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
