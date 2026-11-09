import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(25, 30, 25, 27),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: const [BoxShadow(color: Color(0x160F172A), blurRadius: 38, offset: Offset(0, 16))],
    ),
    child: child,
  );
}
