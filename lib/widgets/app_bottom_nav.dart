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
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap, this.items = clientItems});
  static const List<NavItemData> clientItems = [
    NavItemData(Icons.home_outlined, Icons.home, 'HOME'),
    NavItemData(Icons.explore_outlined, Icons.explore, 'EXPLORE'),
    NavItemData(Icons.favorite_border, Icons.favorite, 'FAVORITOS'),
    NavItemData(Icons.person_outline, Icons.person, 'PERFIL'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.panelBorder))),
    child: SafeArea(top: false, child: SizedBox(height: 70, child: Row(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final selected = i == currentIndex;
        return Expanded(child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: () => onTap(i),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? AppColors.primary : Colors.transparent),
                  child: Icon(selected ? item.activeIcon : item.icon, size: 20,
                    color: selected ? Colors.white : AppColors.slate),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: selected ? .7 : 1.1,
                  color: selected ? AppColors.primary : AppColors.slate),
                child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ));
      }),
    ))),
  );
}
