import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension StaggerX on Widget {
  /// Entrada escalonada: cada índice aparece 90 ms después del anterior.
  Widget stagger(int index) {
    return animate(delay: (120 + index * 90).ms)
        .fadeIn(duration: 450.ms)
        .slideY(
          begin: 0.25,
          end: 0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }
}