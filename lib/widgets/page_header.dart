import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.panelBorder)),
          ),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.slate),
          ),
        ),
      ],
    );
  }
}