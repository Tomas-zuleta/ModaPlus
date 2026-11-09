import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../models/user_role.dart';
import '../pages/auth_page.dart';
import '../utils/app_colors.dart';
import '../utils/fade_route.dart';

class AppDrawer extends StatelessWidget {
  final String name;
  final UserRole role;
  final ValueChanged<int>? onNavigate;
  const AppDrawer({super.key, required this.name, required this.role, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final entries = <({String label, IconData icon, int index})>[
      (label: 'EXPLORAR', icon: Icons.explore_outlined, index: 0),
      (label: 'CATÁLOGO', icon: Icons.grid_view_rounded, index: 1),
      (label: 'MIS PEDIDOS', icon: Icons.receipt_long_outlined, index: 2),
      (label: 'MI PERFIL', icon: Icons.person_outline_rounded, index: 3),
    ];
    return Drawer(
      width: MediaQuery.sizeOf(context).width * .9,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(27, 25, 25, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('MODA PLUS', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 20, letterSpacing: 5, fontWeight: FontWeight.w300))),
            IconButton(
              tooltip: 'Cerrar menú',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
          ]),
          const SizedBox(height: 30),
          Text('HOLA, ${name.toUpperCase()}', maxLines: 2,
            overflow: TextOverflow.ellipsis, style: const TextStyle(
              color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 36),
          ...entries.asMap().entries.map((entry) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 240 + entry.key * 85),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(22 * (1 - value), 0), child: child)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Material(color: Colors.transparent, child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pop();
                  onNavigate?.call(entry.value.index);
                },
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                  child: Row(children: [
                    Expanded(child: Text(entry.value.label, style: const TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, fontSize: 27, fontWeight: FontWeight.w800,
                      letterSpacing: 1.4))),
                    Icon(entry.value.icon, color: AppColors.primary, size: 22),
                  ])),
              )),
            ),
          )),
          const Spacer(),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 14),
          Text(role == UserRole.admin ? 'ADMINISTRADOR' : 'CUENTA DE CLIENTE',
            style: const TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              AppStore.instance.endSession();
              Navigator.of(context).pushAndRemoveUntil(
                fadeRoute(const AuthPage(), duration: const Duration(milliseconds: 500)),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            label: const Text('CERRAR SESIÓN', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ]),
      )),
    );
  }
}
