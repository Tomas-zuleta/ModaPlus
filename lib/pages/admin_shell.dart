import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/user_role.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/sans_scope.dart';
import 'dashboard_view.dart';
import 'suppliers_view.dart';
import 'catalog_admin_page.dart';
import 'orders_view.dart';
import 'plan_separe_view.dart';
import 'profile_view.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const List<NavItemData> _items = [
    NavItemData(Icons.bar_chart_outlined, Icons.bar_chart, 'DASHBOARD'),
    NavItemData(Icons.bookmark_border, Icons.bookmark, 'SEPARE'),
    NavItemData(Icons.receipt_long_outlined, Icons.receipt_long, 'PEDIDOS'),
    NavItemData(Icons.local_shipping_outlined, Icons.local_shipping, 'GESTIÓN'),
    NavItemData(Icons.person_outline, Icons.person, 'PERFIL'),
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardView();
      case 1:
        return const PlanSepareView();
      case 2:
        return const OrdersView();
      case 3:
        return const CatalogAdminPage();
      default:
        return const ProfileView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final name = store.session?.name ?? 'Administrador';
        return SansScope(
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: const AppTopBar(),
            drawer: AppDrawer(name: name, role: UserRole.admin),
            bottomNavigationBar: AppBottomNav(
              items: _items,
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: _page(_index),
              ),
            ),
          ),
        );
      },
    );
  }
}