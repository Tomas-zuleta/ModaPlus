import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/app_colors.dart';

/// Muestra una animación de "datáfono virtual" mientras se procesa el pago.
/// Se cierra sola cuando termina.
Future<void> runPaymentTerminal(BuildContext context, {required String label}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => _TerminalOverlay(label: label),
    transitionBuilder: (_, anim, _, child) =>
      FadeTransition(opacity: anim, child: child),
  );
}

class _TerminalOverlay extends StatefulWidget {
  final String label;
  const _TerminalOverlay({required this.label});

  @override
  State<_TerminalOverlay> createState() => _TerminalOverlayState();
}

class _TerminalOverlayState extends State<_TerminalOverlay> {
  bool _success = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _success = true);
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              child: _success
                  ? const Icon(Icons.check_circle, size: 72, color: AppColors.primary)
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                  : const _CardSlideGraphic(),
            ),
            const SizedBox(height: 18),
            Text(
              _success ? '¡Pago registrado!' : widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (!_success) ...[
              const SizedBox(height: 10),
              const _PulsingDots(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardSlideGraphic extends StatelessWidget {
  const _CardSlideGraphic();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.point_of_sale, size: 88, color: AppColors.panelBorder),
        const Icon(Icons.credit_card, size: 40, color: AppColors.primary)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .slideX(begin: -0.6, end: 0.6, duration: 750.ms, curve: Curves.easeInOut),
      ],
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots();

  @override
  Widget build(BuildContext context) {
    Widget dot(int i) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 400.ms, delay: (i * 150).ms)
            .then()
            .fadeOut(duration: 400.ms);

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [dot(0), dot(1), dot(2)]);
  }
}