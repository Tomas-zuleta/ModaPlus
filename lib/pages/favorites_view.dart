import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'catalog_view.dart';

/// Favoritos pendientes de persistencia por usuario.
class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(30),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.favorite_border_rounded, size: 72, color: AppColors.primary),
      const SizedBox(height: 18),
      const Text('TUS FAVORITOS', style: TextStyle(fontSize: 25,
        fontWeight: FontWeight.w900, color: AppColors.textDark)),
      const SizedBox(height: 12),
      const Text('Aquí podrás guardar las prendas que más te gusten. '
        'Próximamente se sincronizarán con tu cuenta.',
        textAlign: TextAlign.center),
      const SizedBox(height: 22),
      FilledButton(onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const Scaffold(
          appBar: _CatalogHeader(), body: CatalogView()))),
        child: const Text('EXPLORAR CATÁLOGO')),
    ]),
  ));
}
class _CatalogHeader extends StatelessWidget implements PreferredSizeWidget {
  const _CatalogHeader();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(title: const Text('CATÁLOGO'));
}
