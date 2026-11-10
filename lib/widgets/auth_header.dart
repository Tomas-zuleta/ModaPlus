import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 34, height: 4, decoration: BoxDecoration(color: AppColors.acid, borderRadius: BorderRadius.circular(4))),
    const SizedBox(height: 18),
    Text(title, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -1.1, color: AppColors.textDark)),
    const SizedBox(height: 7),
    Text(subtitle, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted)),
    const SizedBox(height: 28),
  ]);
}
