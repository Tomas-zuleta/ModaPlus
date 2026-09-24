import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

enum SalesPeriod { monthly, yearly, daily }

class _SalesData {
  final String amount;
  final String change;
  final List<double> bars;
  const _SalesData(this.amount, this.change, this.bars);
}

class SalesCard extends StatefulWidget {
  const SalesCard({super.key});

  @override
  State<SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<SalesCard> {
  SalesPeriod _period = SalesPeriod.monthly;

  static const Map<SalesPeriod, String> _labels = {
    SalesPeriod.monthly: 'MENSUAL',
    SalesPeriod.yearly: 'ANUAL',
    SalesPeriod.daily: 'DIARIO',
  };

  static const Map<SalesPeriod, _SalesData> _data = {
    SalesPeriod.monthly: _SalesData(
      '\$428.5M',
      '+12.4% vs mes anterior',
      [0.45, 0.62, 0.32, 0.80, 0.50, 1.0],
    ),
    SalesPeriod.yearly: _SalesData(
      '\$5.1B',
      '+8.7% vs año anterior',
      [0.40, 0.55, 0.70, 0.62, 0.85, 1.0],
    ),
    SalesPeriod.daily: _SalesData(
      '\$14.2M',
      '+3.1% vs ayer',
      [0.70, 0.50, 0.85, 0.60, 0.40, 0.95],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final data = _data[_period]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'COMPORTAMIENTO DE VENTAS (COP)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.mutedLabel,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: SalesPeriod.values.map((p) {
                  return _PeriodTab(
                    label: _labels[p]!,
                    selected: p == _period,
                    onTap: () => setState(() => _period = p),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              data.amount,
              key: ValueKey(_period),
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w500,
                letterSpacing: -1.5,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                data.change,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.bars.length, (i) {
                final isLast = i == data.bars.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: data.bars[i]),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Container(
                        height: 110 * v,
                        color: isLast ? AppColors.primary : AppColors.bar,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.panelBorder),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 14),
        padding: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: selected ? AppColors.primary : AppColors.mutedLabel,
          ),
        ),
      ),
    );
  }
}