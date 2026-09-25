import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../widgets/brand_title.dart';
import '../widgets/primary_button.dart';
import 'auth_page.dart';

class HomePage extends StatelessWidget {
  final String name;
  final String email;

  const HomePage({super.key, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandTitle(),
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: AppColors.primary,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 24),
                  Text(
                    '¡Bienvenida, $name!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.textDark,
                    ),
                  ).stagger(3),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(color: AppColors.textMuted),
                  ).stagger(4),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Cerrar sesión',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (_, _, _) => const AuthPage(),
                          transitionsBuilder: (_, animation, _, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                  ).stagger(5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}