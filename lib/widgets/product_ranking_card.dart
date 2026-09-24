import 'package:flutter/material.dart';

import '../models/ranked_product.dart';
import '../utils/app_colors.dart';

class ProductRankingCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<RankedProduct> products;
  final Color indexColor;
  final bool highlightUnits;

  const ProductRankingCard({
    super.key,
    required this.title,
    required this.icon,
    required this.products,
    required this.indexColor,
    required this.highlightUnits,
  });

  String _formatUnits(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(icon, size: 16, color: AppColors.textDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.panelBorder),
          for (int i = 0; i < products.length; i++) ...[
            _row(i, products[i]),
            if (i < products.length - 1)
              const Divider(height: 1, color: AppColors.panelBorder),
          ],
        ],
      ),
    );
  }

  Widget _row(int i, RankedProduct p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              (i + 1).toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: indexColor,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${p.sku}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_formatUnits(p.units)} und.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: highlightUnits ? FontWeight.w500 : FontWeight.w400,
              color: highlightUnits ? AppColors.textDark : AppColors.slate,
            ),
          ),
        ],
      ),
    );
  }
}