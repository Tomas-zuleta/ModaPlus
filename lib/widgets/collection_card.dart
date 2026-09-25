import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class CollectionCard extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final IconData icon;
  final String? assetPath;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.title,
    required this.colors,
    required this.icon,
    required this.onTap,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 330,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (assetPath != null)
              Image.asset(assetPath!, fit: BoxFit.cover)
            else ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.35),
                child: Icon(icon, size: 130, color: Colors.white24),
              ),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                  stops: const [0.5, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      color: Colors.white,
                      child: const Text(
                        'EXPLORAR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}