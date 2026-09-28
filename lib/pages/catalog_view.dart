import 'package:flutter/material.dart';

import '../data/catalog_data.dart';
import '../models/product.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/page_header.dart';
import '../widgets/product_tile.dart';

class CatalogView extends StatefulWidget {
  final String? initialCategory;
  const CatalogView({super.key, this.initialCategory});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  late String? _category = widget.initialCategory;

  List<Product> _byCategory(String category) =>
      catalogProducts.where((p) => p.category == category).toList();

  @override
  Widget build(BuildContext context) {
    // Sin categoría seleccionada: catálogo por secciones con "Ver más".
    if (_category == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, 32),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PageHeader(
                  title: 'Catálogo',
                  subtitle: '${catalogProducts.length} producto(s) disponibles',
                ),
              ).stagger(0),
              const SizedBox(height: 20),
              for (int i = 0; i < categories.length; i++)
                _CategorySection(
                  category: categories[i],
                  products: _byCategory(categories[i]),
                ).stagger(i > 5 ? 5 : i + 1),
            ],
          ),
        ),
      );
    }

    // Con categoría seleccionada: listado completo filtrado.
    final list = _byCategory(_category!);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => setState(() => _category = null),
                ),
                Expanded(
                  child: Text(
                    _category!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ).stagger(0),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.panelBorder)),
              ),
              child: Text(
                '${list.length} producto(s) disponibles',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.slate),
              ),
            ).stagger(0),
            const SizedBox(height: 20),
            FilterChipsRow<String?>(
              values: <String?>[null, ...categories],
              selected: _category,
              labelOf: (c) => c ?? 'Todos',
              onSelected: (c) => setState(() => _category = c),
            ).stagger(1),
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
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
                children: [
                  for (int i = 0; i < list.length; i++)
                    KeyedSubtree(
                      key: ValueKey(list[i].id),
                      child: ProductTile(product: list[i]).stagger(i > 6 ? 6 : i),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<Product> products;

  const _CategorySection({
    required this.category,
    required this.products,
  });

  static const double _cardWidth = 150;
  static const double _cardHeight = 220;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final preview = products.take(4).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${products.length} producto(s)',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _cardHeight,
            child: ListView.separated(
              key: PageStorageKey('row-$category'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: preview.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                return SizedBox(
                  width: _cardWidth,
                  height: _cardHeight,
                  child: ProductTile(product: preview[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

