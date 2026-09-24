import 'package:flutter/material.dart';

import '../data/catalog_data.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/product_tile.dart';

class CatalogView extends StatefulWidget {
  final String? initialCategory;
  const CatalogView({super.key, this.initialCategory});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  late String? _category = widget.initialCategory;

  @override
  Widget build(BuildContext context) {
    final list = catalogProducts
        .where((p) => _category == null || p.category == _category)
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            const Text(
              'Catálogo',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ).stagger(0),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.panelBorder)),
              ),
              child: Text(
                '${list.length} producto(s) disponibles',
                style: const TextStyle(fontSize: 17, color: AppColors.textDark),
              ),
            ).stagger(1),
            const SizedBox(height: 20),
            FilterChipsRow<String?>(
              values: <String?>[null, ...categories],
              selected: _category,
              labelOf: (c) => c ?? 'Todos',
              onSelected: (c) => setState(() => _category = c),
            ).stagger(2),
            const SizedBox(height: 20),
            if (list.isEmpty)
              const EmptyState(
                icon: Icons.checkroom,
                message: 'No hay productos en esta categoría',
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 16,
                childAspectRatio: 0.62,
                children: [
                  for (int i = 0; i < list.length; i++)
                    KeyedSubtree(
                      key: ValueKey(list[i].id),
                      child: ProductTile(product: list[i])
                          .stagger(i > 6 ? 6 : i),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}