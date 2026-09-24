import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/user_role.dart';
import '../utils/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/sans_scope.dart';
import 'cart_page.dart';
import 'catalog_view.dart';
import 'explore_view.dart';
import 'orders_view.dart';
import 'profile_view.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;
  String? _category;

  static const List<NavItemData> _items = [
    NavItemData(Icons.explore_outlined, Icons.explore, 'EXPLORAR'),
    NavItemData(Icons.grid_view_outlined, Icons.grid_view, 'CATÁLOGO'),
    NavItemData(Icons.receipt_long_outlined, Icons.receipt_long, 'PEDIDOS'),
    NavItemData(Icons.person_outline, Icons.person, 'PERFIL'),
  ];

  void _openCategory(String? category) {
    setState(() {
      _category = category;
      _index = 1;
    });
  }

  Widget _page() {
    switch (_index) {
      case 0:
        return ExploreView(onOpenCategory: _openCategory);
      case 1:
        return CatalogView(
          key: ValueKey('catalog-$_category'),
          initialCategory: _category,
        );
      case 2:
        return const OrdersView(onlyMine: true);
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
        return SansScope(
          child: Scaffold(
            backgroundColor: AppColors.dashboardBg,
            appBar: AppTopBar(
              cartCount: store.cartCount,
              onCartTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartPage()),
              ),
            ),
            drawer: AppDrawer(
              name: store.session?.name ?? 'Cliente',
              role: UserRole.client,
            ),
            bottomNavigationBar: AppBottomNav(
              items: _items,
              currentIndex: _index,
              onTap: (i) => setState(() {
                if (i == 1) _category = null;
                _index = i;
              }),
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey('$_index-$_category'),
                child: _page(),
              ),
            ),
          ),
        );
      },
    );
  }
}