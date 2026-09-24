import 'package:flutter/material.dart';

Route<void> fadeRoute(
  Widget page, {
  Duration duration = const Duration(milliseconds: 600),
}) {
  return PageRouteBuilder<void>(
    transitionDuration: duration,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}