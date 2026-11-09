import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final double size;
  final ValueChanged<int> onChanged;
  const QuantityStepper({super.key, required this.value, required this.onChanged,
    this.min = 1, this.max = 99, this.size = 40});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    _StepButton(icon: Icons.remove_rounded, size: size, enabled: value > min,
      onTap: () => onChanged(value - 1)),
    SizedBox(width: size + 8, child: Center(child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: Text('$value', key: ValueKey(value), style: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    ))),
    _StepButton(icon: Icons.add_rounded, size: size, enabled: value < max,
      onTap: () => onChanged(value + 1)),
  ]);
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.size, required this.enabled, required this.onTap});
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: enabled ? 1 : .35,
    duration: const Duration(milliseconds: 180),
    child: Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: SizedBox(width: size, height: size, child: Icon(icon, size: 19, color: AppColors.textDark)),
      ),
    ),
  );
}
