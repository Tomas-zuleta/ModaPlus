import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/catalog_data.dart';
import '../models/plan_separe.dart';
import '../models/product.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';
import '../widgets/detail_app_bar.dart';
import '../widgets/line_item_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/sans_scope.dart';
import '../widgets/section_card.dart';

class PlanSepareCreatePage extends StatefulWidget {
  const PlanSepareCreatePage({super.key});

  @override
  State<PlanSepareCreatePage> createState() => _PlanSepareCreatePageState();
}

class _PlanSepareCreatePageState extends State<PlanSepareCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _paymentController = TextEditingController();
  final List<PlanItem> _items = [];

  Product _product = catalogProducts.first;
  late String _size = _product.sizes.first;
  late ProductColor _color = _product.colors.first;
  int _quantity = 1;

  int get _total => _items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  void _selectProduct(Product? product) {
    if (product == null) return;
    setState(() {
      _product = product;
      _size = product.sizes.first;
      _color = product.colors.first;
      _quantity = 1;
    });
  }

  void _addItem() {
    setState(() {
      _items.add(
        PlanItem(
          name: _product.name,
          size: _size,
          color: _color.name,
          quantity: _quantity,
          unitPrice: _product.price,
        ),
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto al plan')),
      );
      return;
    }
    final initialPayment =
        int.tryParse(
          _paymentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (initialPayment > _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El abono inicial no puede superar ${formatCop(_total)}',
          ),
        ),
      );
      return;
    }

    final plan = AppStore.instance.createPlan(
      clientName: _nameController.text,
      clientDoc: _documentController.text,
      items: _items,
      initialPayment: initialPayment,
    );
    Navigator.pop(context, plan);
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return SansScope(
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        appBar: const DetailAppBar(title: 'Nuevo Plan Separe'),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  SectionCard(
                    title: 'CLIENTE',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoration('Nombre completo'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'El nombre es obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _documentController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration('Documento'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'El documento es obligatorio'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'PRODUCTOS',
                    child: Column(
                      children: [
                        DropdownButtonFormField<Product>(
                          initialValue: _product,
                          isExpanded: true,
                          decoration: _decoration('Producto'),
                          items: [
                            for (final product in catalogProducts)
                              DropdownMenuItem(
                                value: product,
                                child: Text(product.name),
                              ),
                          ],
                          onChanged: _selectProduct,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('size-${_product.id}'),
                                initialValue: _size,
                                decoration: _decoration('Talla'),
                                items: [
                                  for (final size in _product.sizes)
                                    DropdownMenuItem(
                                      value: size,
                                      child: Text(size),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _size = value!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<ProductColor>(
                                key: ValueKey('color-${_product.id}'),
                                initialValue: _color,
                                decoration: _decoration('Color'),
                                items: [
                                  for (final color in _product.colors)
                                    DropdownMenuItem(
                                      value: color,
                                      child: Text(color.name),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _color = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Cantidad'),
                            const Spacer(),
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text('$_quantity'),
                            IconButton(
                              onPressed: _quantity < _product.stock
                                  ? () => setState(() => _quantity++)
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar producto'),
                          ),
                        ),
                        if (_items.isNotEmpty) ...[
                          const Divider(height: 28),
                          for (int i = 0; i < _items.length; i++)
                            Row(
                              children: [
                                Expanded(
                                  child: LineItemRow(
                                    name: _items[i].name,
                                    detail:
                                        'Talla ${_items[i].size} · ${_items[i].color} · x${_items[i].quantity}',
                                    price: formatCop(_items[i].subtotal),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Quitar',
                                  onPressed: () =>
                                      setState(() => _items.removeAt(i)),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'PAGO',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total del plan: ${formatCop(_total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paymentController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(
                            'Abono inicial (opcional)',
                          ).copyWith(prefixText: r'$ '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(text: 'Crear plan separe', onPressed: _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
