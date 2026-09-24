import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0.0 a 1.0
  const ProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.cardBorder),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}