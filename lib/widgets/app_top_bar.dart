import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartCount;
  final VoidCallback? onCartTap;

  const AppTopBar({super.key, this.cartCount = 0, this.onCartTap});

  @override
  Size get preferredSize => const Size.fromHeight(61);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textDark),
      title: const Text(
        'MODA PLUS',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          letterSpacing: 7,
          color: AppColors.textDark,
        ),
      ),
      actions: onCartTap == null
          ? null
          : [
              IconButton(
                onPressed: onCartTap,
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(width: 4),
            ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.panelBorder),
      ),
    );
  }
}