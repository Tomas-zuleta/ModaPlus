import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/user_role.dart';
import '../utils/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/brand_title.dart';
import '../widgets/progress_bar.dart';
import 'admin_shell.dart';
import 'client_shell.dart';

class LoadingPage extends StatefulWidget {
  final String name;
  final UserRole role;

  const LoadingPage({super.key, required this.name, required this.role});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  List<String> get _phrases => widget.role == UserRole.admin
      ? const [
          'Preparando tu panel de control…',
          'Analizando las ventas del mes…',
          'Sincronizando inventario y planes separe…',
          'Todo listo. ¡Bienvenido de vuelta!',
        ]
      : const [
          'Personalizando tu catálogo…',
          'Seleccionando prendas para tu estilo…',
          'Ajustando tallas y colores a tu medida…',
          'Todo listo. ¡Bienvenida a Moda Plus!',
        ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70000),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward().then((_) => _goNext());
  }

  void _goNext() {
    if (!mounted) return;
    final Widget next = widget.role == UserRole.admin
    ? const AdminShell()
    : const ClientShell();
    Navigator.of(context).pushReplacement(fadeRoute(next));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrases = _phrases;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const BrandTitle(),
              const Spacer(),
              const Text(
                'HOLA,',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 4,
                  color: AppColors.textMuted,
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 10),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 40,
                  color: AppColors.textDark,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 10),
              Text(
                widget.role == UserRole.admin ? 'ADMINISTRADOR' : 'CLIENTE',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: AppColors.primary,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: 56),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final v = _progress.value;
                  final index = (v * phrases.length)
                      .floor()
                      .clamp(0, phrases.length - 1)
                      .toInt();

                  return Column(
                    children: [
                      SizedBox(
                        height: 28,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            phrases[index],
                            key: ValueKey(index),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ProgressBar(value: v),
                      const SizedBox(height: 12),
                      Text(
                        '${(v * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}