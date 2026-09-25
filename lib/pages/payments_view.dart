import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/plan_separe.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import 'plan_payment_dialog.dart';
import 'plan_separe_detail_page.dart';

class PaymentsView extends StatelessWidget {
  const PaymentsView({super.key});

  Future<void> _selectPlan(BuildContext context) async {
    final plans = AppStore.instance.plans
        .where((plan) => plan.canReceivePayments)
        .toList();
    final plan = await showModalBottomSheet<PlanSepare>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'SELECCIONA UN PLAN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.slate,
                ),
              ),
            ),
            if (plans.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text('No hay planes activos con saldo pendiente.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final plan in plans)
                      ListTile(
                        title: Text('${plan.id} · ${plan.clientName}'),
                        subtitle: Text('Saldo ${formatCop(plan.balance)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(sheetContext, plan),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (plan == null || !context.mounted) return;
    final saved = await showPlanPaymentDialog(context, plan);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Abono registrado en ${plan.id}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) {
        final records = [
          for (final plan in AppStore.instance.plans)
            for (final payment in plan.abonos) (plan: plan, payment: payment),
        ]..sort((a, b) => b.payment.date.compareTo(a.payment.date));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                const Text(
                  'Abonos',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ).stagger(0),
                const SizedBox(height: 8),
                const Text(
                  'Historial de pagos asociados a Plan Separe',
                  style: TextStyle(fontSize: 17, color: AppColors.textDark),
                ).stagger(1),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Registrar abono',
                  onPressed: () => _selectPlan(context),
                ).stagger(2),
                const SizedBox(height: 20),
                if (records.isEmpty)
                  const EmptyState(
                    icon: Icons.payments_outlined,
                    message: 'No hay abonos registrados',
                  )
                else
                  for (int i = 0; i < records.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlanSepareDetailPage(plan: records[i].plan),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.panel,
                            border: Border.all(color: AppColors.panelBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${records[i].plan.id} · ${records[i].plan.clientName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      '${formatDate(records[i].payment.date)} · Saldo ${formatCop(records[i].plan.balance)}',
                                      style: const TextStyle(
                                        color: AppColors.slate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCop(records[i].payment.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
