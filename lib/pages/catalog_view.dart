import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/real_catalog_service.dart';
import '../widgets/product_tile.dart';

class CatalogView extends StatefulWidget {
  final String? initialCategory;
  const CatalogView({super.key, this.initialCategory});
  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  late String? _category = widget.initialCategory;
  late Future<List<Product>> _products;
  @override
  void initState() { super.initState(); _refresh(); }
  void _refresh() => _products = RealCatalogService.instance.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Product>>(
    future: _products,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 46),
            const SizedBox(height: 12),
            const Text('No fue posible consultar el catálogo real de ModaPlus.',
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(_refresh),
              child: const Text('Reintentar')),
          ])));
      }
      final products = snapshot.data ?? [];
      final categories = products.map((p) => p.category).toSet().toList()..sort();
      final list = products.where((p) =>
        _category == null || p.category == _category).toList();
      return RefreshIndicator(onRefresh: () async {
        setState(_refresh);
        await _products;
      }, child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Catálogo', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('${list.length} variantes disponibles · Datos de Supabase'),
        const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          ChoiceChip(label: const Text('Todos'), selected: _category == null,
            onSelected: (_) => setState(() => _category = null)),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(label: Text(category), selected: _category == category,
              onSelected: (_) => setState(() => _category = category)),
            const SizedBox(width: 8),
          ],
        ])),
        const SizedBox(height: 18),
        if (list.isEmpty) const Padding(padding: EdgeInsets.all(40),
          child: Center(child: Text('No hay productos disponibles'))),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 16,
            childAspectRatio: .62),
          itemBuilder: (context, i) => ProductTile(
            key: ValueKey(list[i].id), product: list[i])),
      ]));
    },
  );
}
