import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/app_colors.dart';

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'MODA PLUS',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w300,
        letterSpacing: 8,
        color: AppColors.textDark,
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: -0.5, end: 0, duration: 700.ms, curve: Curves.easeOutCubic)
        .then(delay: 200.ms)
        .shimmer(duration: 1200.ms, color: AppColors.primary.withValues(alpha: 0.5));
  }
}