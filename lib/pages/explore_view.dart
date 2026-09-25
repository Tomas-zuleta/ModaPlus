import 'package:flutter/material.dart';

import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../widgets/collection_card.dart';
import '../widgets/primary_button.dart';

class ExploreView extends StatelessWidget {
  final ValueChanged<String?> onOpenCategory;
  const ExploreView({super.key, required this.onOpenCategory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            const Text(
              'Explorar Colecciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: AppColors.textDark,
              ),
            ).stagger(0),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Descubre nuestra selección de prendas de alta costura, '
                'diseñadas para elevar tu estilo con una elegancia '
                'atemporal y un ajuste perfecto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: AppColors.slate,
                ),
              ),
            ).stagger(1),
            const SizedBox(height: 40),
            CollectionCard(
              title: 'Camisas',
              icon: Icons.checkroom,
              colors: const [Color(0xFF2F6B4F), Color(0xFFA9D6BE)],
              // assetPath: 'assets/camisas.jpg',
              onTap: () => onOpenCategory('Camisas'),
            ).stagger(2),
            const SizedBox(height: 20),
            CollectionCard(
              title: 'Pantalones',
              icon: Icons.accessibility_new,
              colors: const [Color(0xFF1F4D3A), Color(0xFFC9CDD6)],
              // assetPath: 'assets/pantalones.jpg',
              onTap: () => onOpenCategory('Pantalones'),
            ).stagger(3),
            const SizedBox(height: 20),
            CollectionCard(
              title: 'Vestidos',
              icon: Icons.woman,
              colors: const [Color(0xFFB8BDD0), Color(0xFFB8BDD0)],
              // assetPath: 'assets/vestidos.jpg',
              onTap: () => onOpenCategory('Vestidos'),
            ).stagger(4),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PrimaryButton(
                text: 'Ver todas las categorías',
                onPressed: () => onOpenCategory(null),
              ),
            ).stagger(5),
          ],
        ),
      ),
    );
  }
}