import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ErrorMessage extends StatelessWidget {
  final String? message;
  const ErrorMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}