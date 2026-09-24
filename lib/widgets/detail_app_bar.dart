import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const DetailAppBar({super.key, required this.title});

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
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
          color: AppColors.textDark,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.panelBorder),
      ),
    );
  }
}