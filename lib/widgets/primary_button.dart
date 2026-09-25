import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: AppColors.primary.withOpacity(0.22),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
