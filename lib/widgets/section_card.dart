import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({super.key, required this.title, required this.child});

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.panelBorder),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}