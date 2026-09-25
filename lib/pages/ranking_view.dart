import 'package:flutter/material.dart';

import '../data/ranking_data.dart';
import '../utils/app_colors.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/filter_chips.dart';
import '../widgets/product_ranking_card.dart';
import '../widgets/sans_scope.dart';

class RankingView extends StatefulWidget {
  const RankingView({super.key});

  @override
  State<RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<RankingView> {
  RankPeriod _period = RankPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        appBar: const DetailAppBar(title: 'RANKING DE PRODUCTOS'),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                FilterChipsRow<RankPeriod>(
                  values: RankPeriod.values,
                  selected: _period,
                  labelOf: (p) => p == RankPeriod.monthly ? 'Mensual' : 'Anual',
                  onSelected: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 20),
                ProductRankingCard(
                  title: 'TOP 10 MÁS VENDIDOS',
                  icon: Icons.keyboard_double_arrow_up,
                  products: topProducts(_period),
                  indexColor: AppColors.slate,
                  highlightUnits: true,
                ),
                const SizedBox(height: 16),
                ProductRankingCard(
                  title: 'TOP 10 MENOS VENDIDOS',
                  icon: Icons.keyboard_double_arrow_down,
                  products: lowProducts(_period),
                  indexColor: AppColors.redAccent,
                  highlightUnits: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}