import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/administrative_transactions.dart';

/// Formularios de operaciones comerciales. Los RPC del servidor son la
/// autoridad final sobre existencias, precios, permisos y estados.
class TransactionEntryPage extends StatefulWidget {
  final String module;
  const TransactionEntryPage({super.key, required this.module});
  @override
  State<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _Line {
  int? variant;
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();
  void dispose() { quantity.dispose(); price.dispose(); }
}

class _TransactionEntryPageState extends State<TransactionEntryPage> {
  final _form = GlobalKey<FormState>();
  final _lines = <_Line>[_Line()];
  final _date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _invoice = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _initial = TextEditingController();
  final _reason = TextEditingController();
  final _description = TextEditingController();
  int? _party;
  int? _sale;
  String _payment = 'EFECTIVO';
  String _returnType = 'DINERO';
  bool _busy = false;
  bool _confirmed = false;
  late final Future<void> _load;
  List<Map<String, dynamic>> _parties = [], _variants = [], _sales = [];

  bool get _purchase => widget.module == 'compras';
  bool get _layaway => widget.module == 'separe';
  bool get _return => widget.module == 'devoluciones';
  String get _partyTable => _purchase ? 'proveedores' : 'clientes';
  String get _partyId => _purchase ? 'id_proveedor' : 'id_cliente';
  String get _partyLabel => _purchase ? 'razon_social' : 'nombres';
  String get _title => switch (widget.module) {
    'compras' => 'Nueva compra',
    'ventas' => 'Nueva venta',
    'separe' => 'Nuevo Plan Separe',
    'devoluciones' => 'Nueva devolución',
    _ => 'Nuevo registro',
  };

  String _relatedName(Object? value, String key) {
    final row = value is List ? (value.isEmpty ? null : value.first) : value;
    return row is Map ? (row[key]?.toString() ?? '') : '';
  }

  String _variantName(Map<String, dynamic> variant) {
    final product = _relatedName(variant['productos'], 'nombre_producto');
    final size = _relatedName(variant['tallas'], 'nombre_talla');
    final color = _relatedName(variant['colores'], 'nombre_color');
    return '${product.isEmpty ? 'Producto #${variant['id_producto']}' : product}'
      '${size.isEmpty ? '' : ' · Talla $size'}'
      '${color.isEmpty ? '' : ' · $color'}';
  }

  Future<void> _chooseVariant(int index) async {
    String query = '';
    final selected = await showModalBottomSheet<int>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) {
          final matches = _variants.where((v) {
            final name = _variantName(v).toLowerCase();
            return name.contains(query.toLowerCase()) ||
              '${v['id_variante']}'.contains(query);
          }).toList();
          return SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(children: [
                Center(child: Container(width: 44, height: 5,
                  decoration: BoxDecoration(color: Colors.black26,
                    borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 18),
                Text('Elige una prenda',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar nombre, talla o color'),
                  onChanged: (value) => update(() => query = value)),
                const SizedBox(height: 10),
                Expanded(child: ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, i) {
                    final variant = matches[i];
                    final stock = (variant['stock_actual'] as num?)?.toInt() ?? 0;
                    return Card(child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                      title: Text(_variantName(variant)),
                      subtitle: Text('Precio: COP ${variant['precio_venta']}'
                        ' · Disponibles: $stock'),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: (!_purchase && !_return && stock <= 0)
                        ? null
                        : () => Navigator.pop(sheetContext,
                            (variant['id_variante'] as num).toInt()),
                    ));
                  },
                )),
              ]),
            ),
          );
        },
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _lines[index].variant = selected;
      final variant = _variants.firstWhere(
        (v) => (v['id_variante'] as num).toInt() == selected);
      if (!_purchase && !_return) {
        _lines[index].price.text = '${variant['precio_venta'] ?? ''}';
      }
    });
  }

  double get _previewTotal {
    if (_return) return 0;
    final subtotal = _lines.fold<double>(0, (sum, line) {
      final quantity = int.tryParse(line.quantity.text) ?? 0;
      final price = double.tryParse(line.price.text.replaceAll(',', '.')) ?? 0;
      return sum + quantity * price;
    });
    final discount = widget.module == 'ventas'
      ? (double.tryParse(_discount.text.replaceAll(',', '.')) ?? 0)
      : 0.0;
    return (subtotal - discount).clamp(0.0, double.infinity);
  }

  @override
  void initState() { super.initState(); _load = _loadOptions(); }
  Future<void> _loadOptions() async {
    final db = Supabase.instance.client;
    final parties = await db.from(_partyTable).select('*').limit(300);
    final variants = await db.from('variantes_producto')
      .select('id_variante,id_producto,precio_venta,stock_actual,estado,'
        'productos(nombre_producto),tallas(nombre_talla),colores(nombre_color)')
      .eq('estado', 'ACTIVO').limit(500);
    final sales = _return
      ? await db.from('ventas').select('id_venta,id_cliente,estado').limit(300)
      : <Map<String, dynamic>>[];
    _parties = parties.map((e) => Map<String, dynamic>.from(e)).toList();
    _variants = variants.map((e) => Map<String, dynamic>.from(e)).toList();
    _sales = sales.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  @override
  void dispose() {
    _date.dispose(); _invoice.dispose(); _discount.dispose();
    _initial.dispose(); _reason.dispose(); _description.dispose();
    for (final line in _lines) { line.dispose(); }
    super.dispose();
  }
  String? _positive(String? value) {
    final number = num.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null || number <= 0 ? 'Introduce un valor mayor a cero' : null;
  }
  String? _nonNegative(String? value) {
    final number = num.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null || number < 0 ? 'Introduce un valor válido' : null;
  }
  double _number(String value) => double.parse(value.replaceAll(',', '.'));
  DateTime _twoMonths(DateTime start) {
    final monthIndex = start.month + 2;
    final firstOfNext = DateTime(start.year, monthIndex + 1, 1);
    final lastOfMonth = firstOfNext.subtract(const Duration(days: 1)).day;
    return DateTime(start.year, monthIndex,
      start.day > lastOfMonth ? lastOfMonth : start.day);
  }
  Future<void> _save() async {
    if (_busy || !_confirmed || !_form.currentState!.validate()) return;
    if ((_return ? _sale : _party) == null || _lines.any((e) => e.variant == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona el cliente/proveedor o venta y todas las variantes.')));
      return;
    }
    final ids = _lines.map((e) => e.variant).toList();
    if (ids.toSet().length != ids.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Agrupa las variantes repetidas en una sola línea.')));
      return;
    }
    final now = _date.text;
    final total = _return ? 0.0 : _lines.fold<double>(0, (sum, line) =>
      sum + _number(line.quantity.text) * _number(line.price.text));
    final details = _lines.map((line) {
      final quantity = int.parse(line.quantity.text);
      final price = _return ? 0.0 : _number(line.price.text);
      if (_purchase) return <String, dynamic>{
        'id_compra': 0, 'id_variante': line.variant!,
        'cantidad': quantity, 'costo_unitario': price,
      };
      if (_return) return <String, dynamic>{
        'id_variante': line.variant!, 'cantidad': quantity,
        'motivo': _reason.text.trim(), 'descripcion': _description.text.trim(),
      };
      if (_layaway) return <String, dynamic>{
        'id_plan_separe': 0, 'id_variante': line.variant!,
        'cantidad': quantity, 'precio_unitario': price,
      };
      return <String, dynamic>{
        'id_variante': line.variant!, 'cantidad': quantity,
        'precio_unitario': price, 'subtotal': quantity * price,
      };
    }).toList();
    final discount = _number(_discount.text);
    if (!_purchase && !_layaway && !_return && discount > total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El descuento supera el subtotal.')));
      return;
    }
    if (_layaway && _number(_initial.text) < _lines.fold<double>(
      0, (sum, line) => sum + 20000 * int.parse(line.quantity.text))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La cuota inicial mínima es \$20.000 por prenda.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final service = AdministrativeTransactions.instance;
      final id = switch (widget.module) {
        'compras' => await service.savePurchase({
          'id_compra': 0, 'id_proveedor': _party, 'fecha_compra': now,
          'fecha_registro': now, 'factura': _invoice.text.trim(),
          'tipo_pago': 'CONTADO', 'estado': 'ACTIVA',
        }, details),
        'ventas' => await service.saveSale({
          'id_venta': 0, 'id_cliente': _party, 'fecha_venta': now,
          'metodo_pago': _payment, 'subtotal': total, 'descuento': discount,
          'total_venta': total - discount, 'saldo_aplicado': 0,
          'estado': 'APROBADA', 'origen': 'ADMIN',
          'comprobante_url': null, 'comprobante_nombre': null,
        }, details),
        'separe' => await service.saveLayaway({
          'id_plan_separe': 0, 'id_cliente': _party, 'fecha_inicio': now,
          'fecha_vencimiento': _twoMonths(DateTime.parse(now)).toIso8601String().substring(0, 10),
          'estado': 'ACTIVO', 'abono_inicial': _number(_initial.text),
          'metodo_abono_inicial': _payment,
          'comprobante_inicial': null, 'comprobante_inicial_nombre': null,
        }, details),
        'devoluciones' => await service.saveReturn({
          'id_devolucion': 0, 'id_venta': _sale,
          'fecha_devolucion': now, 'motivo': _reason.text.trim().toUpperCase(),
          'descripcion': _description.text.trim(), 'tipo_respuesta': _returnType,
          'estado': 'ACTIVA', 'fecha_estado': now, 'cambio': null,
        }, details),
        _ => throw StateError('Módulo no soportado'),
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operación #$id registrada por Supabase')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: FutureBuilder<void>(future: _load, builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text(
        'No se pudieron cargar los datos. Revisa permisos y conexión.'));
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return Form(key: _form, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(padding: EdgeInsets.all(16),
            child: Text('Completa los pasos en orden. Al finalizar, '
              'revisa los valores antes de guardar. '
              'Supabase verifica existencias y permisos.'))),
          const SizedBox(height: 12),
          Text('1. ${_purchase ? 'Proveedor' : _return ? 'Venta original' : 'Cliente'}',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (!_return) DropdownButtonFormField<int>(
            value: _party, isExpanded: true,
            decoration: InputDecoration(labelText: _purchase ? 'Proveedor' : 'Cliente'),
            items: _parties.map((p) => DropdownMenuItem<int>(
              value: (p[_partyId] as num).toInt(),
              child: Text('${p[_partyLabel] ?? ''} ${p['apellidos'] ?? ''}',
                overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) => setState(() => _party = v),
            validator: (v) => v == null ? 'Selecciona un registro' : null),
          if (_return) DropdownButtonFormField<int>(
            value: _sale, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Venta de origen'),
            items: _sales.map((s) => DropdownMenuItem<int>(
              value: (s['id_venta'] as num).toInt(),
              child: Text('Venta #${s['id_venta']} · ${s['estado']}'))).toList(),
            onChanged: (v) => setState(() => _sale = v),
            validator: (v) => v == null ? 'Selecciona una venta' : null),
          TextFormField(controller: _date, readOnly: true,
            decoration: const InputDecoration(labelText: 'Fecha (hoy)')),
          if (_purchase) TextFormField(controller: _invoice,
            decoration: const InputDecoration(labelText: 'Factura del proveedor'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatoria' : null),
          if (!_purchase && !_return) DropdownButtonFormField<String>(
            value: _payment,
            decoration: const InputDecoration(labelText: 'Método de pago'),
            items: const ['EFECTIVO', 'TRANSFERENCIA', 'QR'].map((v) =>
              DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _payment = v ?? _payment)),
          if (_return) ...[
            TextFormField(controller: _reason,
              decoration: const InputDecoration(labelText: 'Motivo'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null),
            TextFormField(controller: _description,
              decoration: const InputDecoration(labelText: 'Descripción')),
            DropdownButtonFormField<String>(value: _returnType,
              decoration: const InputDecoration(labelText: 'Respuesta (devolución de dinero)'),
              items: const ['DINERO'].map((v) =>
                DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _returnType = v ?? _returnType)),
          ],
          const SizedBox(height: 24),
          Text('2. Elige los productos', style: Theme.of(context).textTheme.titleLarge),
          const Text('Busca una prenda por su nombre, talla o color.'),
          const SizedBox(height: 12),
          for (var i = 0; i < _lines.length; i++)
            Card(key: ObjectKey(_lines[i]), child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(4),
                  leading: const CircleAvatar(
                    child: Icon(Icons.checkroom_outlined)),
                  title: Text(_lines[i].variant == null
                    ? 'Toca para elegir una prenda'
                    : _variantName(_variants.firstWhere((v) =>
                      (v['id_variante'] as num).toInt() == _lines[i].variant))),
                  subtitle: const Text('Ver prendas disponibles'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _chooseVariant(i),
                ),
                const SizedBox(height: 8),
                TextFormField(controller: _lines[i].quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '¿Cuántas unidades?'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n <= 0 ? 'Cantidad entera positiva' : null;
                  }),
                if (!_return) TextFormField(controller: _lines[i].price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText:
                    _purchase ? 'Costo unitario' : 'Precio unitario'),
                  validator: _positive,
                  onChanged: (_) => setState(() {})),
                if (_lines.length > 1) TextButton.icon(
                  onPressed: () => setState(() {
                    final line = _lines.removeAt(i);
                    line.dispose();
                  }),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Quitar línea')),
              ]))),
          OutlinedButton.icon(onPressed: () => setState(() => _lines.add(_Line())),
            icon: const Icon(Icons.add), label: const Text('Agregar producto')),
          if (widget.module == 'ventas') TextFormField(controller: _discount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Descuento total'),
            validator: _nonNegative,
            onChanged: (_) => setState(() {})),
          if (_layaway) TextFormField(controller: _initial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Abono inicial'),
            validator: _positive),
          const SizedBox(height: 20),
          Text('3. Revisa antes de guardar',
            style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (!_return)
            Card(child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Expanded(child: Text('Total de la operación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Text('COP ${_previewTotal.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium),
              ]),
            )),
          CheckboxListTile(value: _confirmed,
            title: const Text('Revisé el cliente, las prendas y los valores.'),
            onChanged: _busy ? null : (v) =>
              setState(() => _confirmed = v ?? false)),
          FilledButton.icon(
            onPressed: _busy || !_confirmed ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Guardando...' : 'Guardar ${_title.toLowerCase()}')),
          const SizedBox(height: 20),
        ]));
    }),
  );
}
