import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class DetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int cartCount;
  final VoidCallback? onCartTap;
  final GlobalKey? cartKey;

  const DetailAppBar({
    super.key,
    required this.title,
    this.cartCount = 0,
    this.onCartTap,
    this.cartKey,
  });

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
      actions: onCartTap == null
          ? null
          : [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      key: cartKey,
                      onPressed: onCartTap,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 26),
                    ),
                    if (cartCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.panelBorder),
      ),
    );
  }
}
