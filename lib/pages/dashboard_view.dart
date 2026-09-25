import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/ranking_data.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/filter_chips.dart';
import '../widgets/page_header.dart';
import '../widgets/product_ranking_card.dart';
import '../widgets/sales_card.dart';
import '../widgets/stat_tile.dart';
import 'ranking_view.dart';

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
        final top5 = topProducts(_period).take(5).toList();

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                const PageHeader(
                  title: 'Dashboard',
                  subtitle: 'Resumen del desempeño del negocio',
                ).stagger(0),
                const SizedBox(height: 20),
                const SalesCard().stagger(1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.bookmark_border,
                        label: 'Plan separe retenido',
                        value: formatCop(store.retainedAmount),
                      ).stagger(2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.event_repeat,
                        label: 'Planes activos',
                        value: '${store.activePlansCount}',
                      ).stagger(2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.hourglass_top,
                        label: 'Pedidos por atender',
                        value: '${store.pendingOrdersCount}',
                        color: AppColors.redAccent,
                      ).stagger(3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total de pedidos',
                        value: '${store.orders.length}',
                      ).stagger(3),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'TOP 5 PRODUCTOS',
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
                  title: 'MÁS VENDIDOS',
                  icon: Icons.keyboard_double_arrow_up,
                  products: top5,
                  indexColor: AppColors.slate,
                  highlightUnits: true,
                ).stagger(5),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RankingView()),
                    ),
                    icon: const Icon(Icons.arrow_forward,
                        size: 16, color: AppColors.primary),
                    label: const Text(
                      'VER MÁS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ).stagger(5),
              ],
            ),
          ),
        );
      },
    );
  }
}