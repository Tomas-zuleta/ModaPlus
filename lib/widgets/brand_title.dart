import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    const Text('MODA', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: AppColors.textDark)),
    Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppColors.acid, borderRadius: BorderRadius.circular(4)), child: const Text('+', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1, color: AppColors.textDark))),
    const Text('PLUS', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: AppColors.textDark)),
  ]).animate().fadeIn(duration: 450.ms).slideY(begin: -.2, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
}
