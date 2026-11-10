import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../models/order.dart';
import '../utils/app_colors.dart';
import 'orders_view.dart';
import 'client_plans_page.dart';
import 'profile_view.dart';

class AccountOverviewPage extends StatelessWidget {
  const AccountOverviewPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(appBar: AppBar(title: const Text('MI CUENTA')),
      body: ListenableBuilder(listenable: store, builder: (context, _) {
        final email = store.session?.email.toLowerCase() ?? '';
        final mine = store.orders.where((o) => o.clientEmail.toLowerCase() == email).toList();
        final pending = mine.where((o) => o.status == OrderStatus.pending).length;
        return ListView(padding: const EdgeInsets.all(22), children: [
          Text('HOLA, ${store.session?.name.toUpperCase() ?? 'CLIENTE'}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
              color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Resumen de tus compras y tu cuenta'),
          const SizedBox(height: 22),
          _SummaryTile(icon: Icons.shopping_bag_outlined, title: 'MIS COMPRAS',
            subtitle: '${mine.length} pedidos · $pending pendientes',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const Scaffold(
                appBar: _AccountHeader(title: 'MIS COMPRAS'),
                body: OrdersView(onlyMine: true))))),
          _SummaryTile(icon: Icons.bookmark_outline, title: 'PLAN SEPARE Y ABONOS',
            subtitle: 'Reservas, abonos y saldos',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ClientPlansPage()))),
          _SummaryTile(icon: Icons.person_outline, title: 'MIS DATOS',
            subtitle: 'Información personal y contacto',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const Scaffold(
                appBar: _AccountHeader(title: 'MIS DATOS'),
                body: ProfileView())))),
        ]);
      }),
    );
  }
}
class _AccountHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _AccountHeader({required this.title});
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SummaryTile({required this.icon, required this.title,
    required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Card(child: ListTile(contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon, color: AppColors.primary, size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
      onTap: onTap)),
  );
}
