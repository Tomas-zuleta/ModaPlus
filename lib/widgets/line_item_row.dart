import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class LineItemRow extends StatelessWidget {
  final String name;
  final String detail;
  final String price;

  const LineItemRow({
    super.key,
    required this.name,
    required this.detail,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
        ],
      ),
    );
  }
}