import 'package:flutter/material.dart';
import '../data/app_store.dart';

import '../models/user_role.dart';
import '../pages/auth_page.dart';
import '../utils/app_colors.dart';
import '../utils/fade_route.dart';

class AppDrawer extends StatelessWidget {
  final String name;
  final UserRole role;

  const AppDrawer({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MODA PLUS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 6,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role == UserRole.admin ? 'Administrador' : 'Cliente',
                    style: const TextStyle(color: AppColors.slate),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.panelBorder),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textDark),
              title: const Text('Cerrar sesión'),
             onTap: () {
  AppStore.instance.endSession();
  Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const AuthPage(), duration: const Duration(milliseconds: 500)),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}