import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/ranking_data.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../widgets/filter_chips.dart';
import '../widgets/plan_separe_card.dart';
import '../widgets/product_ranking_card.dart';
import '../widgets/sales_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  RankPeriod _period = RankPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                const Text(
                  'Dashboard Administrativo',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
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
                    'Visión general del desempeño comercial',
                    style: TextStyle(fontSize: 17, color: AppColors.textDark),
                  ),
                ).stagger(1),
                const SizedBox(height: 24),
                const SalesCard().stagger(2),
                const SizedBox(height: 16),
                PlanSepareCard(
                  amount: store.retainedAmount,
                  count: store.activePlansCount,
                ).stagger(3),
                const SizedBox(height: 28),
                const Text(
                  'RANKING DE PRODUCTOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                    color: AppColors.mutedLabel,
                  ),
                ).stagger(4),
                const SizedBox(height: 12),
                FilterChipsRow<RankPeriod>(
                  values: RankPeriod.values,
                  selected: _period,
                  labelOf: (p) => p == RankPeriod.monthly ? 'Mensual' : 'Anual',
                  onSelected: (p) => setState(() => _period = p),
                ).stagger(4),
                const SizedBox(height: 16),
                ProductRankingCard(
                  title: 'TOP 10 MÁS VENDIDOS',
                  icon: Icons.keyboard_double_arrow_up,
                  products: topProducts(_period),
                  indexColor: AppColors.slate,
                  highlightUnits: true,
                ).stagger(5),
                const SizedBox(height: 16),
                ProductRankingCard(
                  title: 'TOP 10 MENOS VENDIDOS',
                  icon: Icons.keyboard_double_arrow_down,
                  products: lowProducts(_period),
                  indexColor: AppColors.redAccent,
                  highlightUnits: false,
                ).stagger(5),
              ],
            ),
          ),
        );
      },
    );
  }
}