import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.text, required this.onPressed, this.isLoading = false});
  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading && widget.onPressed != null;
    return AnimatedScale(
      scale: _pressed && enabled ? .975 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Listener(
          onPointerDown: (_) { if (enabled) setState(() => _pressed = true); },
          onPointerUp: (_) { if (_pressed) setState(() => _pressed = false); },
          onPointerCancel: (_) { if (_pressed) setState(() => _pressed = false); },
          child: ElevatedButton(
            onPressed: enabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: .65),
              foregroundColor: Colors.white,
              elevation: _pressed ? 1 : 7,
              shadowColor: AppColors.primary.withValues(alpha: .25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: widget.isLoading
                  ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(key: const ValueKey('text'), mainAxisAlignment: MainAxisAlignment.center, children: [
                      Flexible(child: Text(widget.text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.6))),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}
