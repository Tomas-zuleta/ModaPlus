import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../services/supabase_auth_service.dart';
import '../models/user_role.dart';
import '../pages/account_overview_page.dart';
import '../pages/orders_view.dart';
import '../pages/client_plans_page.dart';
import '../pages/profile_view.dart';
import '../pages/settings_page.dart';
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
    final admin = role == UserRole.admin;
    final items = <({String title, IconData icon, Widget page})>[
      if (!admin) ...[
        (title: 'RESUMEN DE MI CUENTA', icon: Icons.space_dashboard_outlined,
          page: const AccountOverviewPage()),
        (title: 'MIS COMPRAS', icon: Icons.shopping_bag_outlined,
          page: const Scaffold(appBar: _DrawerHeader(title: 'MIS COMPRAS'),
            body: OrdersView(onlyMine: true))),
        (title: 'MIS PLANES SEPARE', icon: Icons.bookmark_outline,
          page: const ClientPlansPage()),
        (title: 'MIS DATOS', icon: Icons.badge_outlined,
          page: const Scaffold(appBar: _DrawerHeader(title: 'MIS DATOS'),
            body: ProfileView())),
      ] else ...[
        (title: 'PEDIDOS', icon: Icons.receipt_long_outlined,
          page: const Scaffold(appBar: _DrawerHeader(title: 'PEDIDOS'),
            body: OrdersView())),
      ],
      (title: 'CONFIGURACIÓN', icon: Icons.settings_outlined,
        page: const SettingsPage()),
    ];
    return Drawer(width: MediaQuery.sizeOf(context).width * .9,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 25, 24, 25),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('MODA PLUS', style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.w800))),
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded)),
          ]),
          const SizedBox(height: 25),
          Text('HOLA, ${name.toUpperCase()}', maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.primary,
              fontSize: 12, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
          const SizedBox(height: 28),
          Expanded(child: ListView(children: [
            for (var i = 0; i < items.length; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 220 + i * 75),
                builder: (context, value, child) => Opacity(opacity: value,
                  child: Transform.translate(offset: Offset(18 * (1 - value), 0),
                    child: child)),
                child: Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: Material(color: Colors.transparent,
                    child: InkWell(borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(MaterialPageRoute(builder: (_) => items[i].page));
                      },
                      child: Padding(padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(children: [
                          Expanded(child: Text(items[i].title,
                            style: TextStyle(fontSize: 21,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w900, letterSpacing: .7))),
                          Icon(items[i].icon, size: 21, color: AppColors.primary),
                        ]))))),
              ),
          ])),
          Divider(color: Theme.of(context).dividerColor),
          TextButton.icon(onPressed: () async {
            await SupabaseAuthService.instance.signOut();
            if (!context.mounted) return;
            AppStore.instance.endSession();
            Navigator.of(context).pushAndRemoveUntil(
              fadeRoute(const AuthPage()), (route) => false);
          }, icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
            label: const Text('CERRAR SESIÓN')),
        ]),
      )),
    );
  }
}
class _DrawerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _DrawerHeader({required this.title});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}
