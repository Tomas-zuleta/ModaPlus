import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItemData(this.icon, this.activeIcon, this.label);
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItemData> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = clientItems,
  });

  static const List<NavItemData> clientItems = [
    NavItemData(Icons.home_outlined, Icons.home, 'HOME'),
    NavItemData(Icons.explore_outlined, Icons.explore, 'EXPLORE'),
    NavItemData(Icons.favorite_border, Icons.favorite, 'FAVORITOS'),
    NavItemData(Icons.person_outline, Icons.person, 'PERFIL'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.panelBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? AppColors.primary : Colors.transparent,
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 20,
                          color: selected ? Colors.white : AppColors.slate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: selected ? AppColors.primary : AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}