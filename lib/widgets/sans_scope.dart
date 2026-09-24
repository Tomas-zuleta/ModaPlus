import 'package:flutter/material.dart';

class SansScope extends StatelessWidget {
  final Widget child;
  const SansScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: 'Inter',
          fontFamilyFallback: const ['Roboto', 'Arial', 'Helvetica', 'sans-serif'],
        ),
      ),
      child: child,
    );
  }
}