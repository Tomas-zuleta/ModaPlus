import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_permissions.dart';
import 'transaction_entry_page.dart';
import 'loss_entry_page.dart';
import '../services/administrative_transactions.dart';

class AdminDomainDefinition {
  final String module, table, title, description, primaryKey;
  final IconData icon;
  final List<String> fields;
  const AdminDomainDefinition(this.module, this.table, this.title,
    this.description, this.primaryKey, this.icon, this.fields);
}

/// Módulos de la web aún sin flujos transaccionales completos en móvil.
/// Cada entrada utiliza una tabla de negocio concreta y permisos reales.
const adminDomainModules = <AdminDomainDefinition>[
  AdminDomainDefinition('inventario', 'productos', 'Productos',
    'Catálogo de productos', 'id_producto', Icons.inventory_2_outlined,
    ['id_producto', 'referencia', 'nombre_producto', 'estado']),
  AdminDomainDefinition('inventario', 'variantes_producto', 'Variantes e inventario',
    'Tallas, colores y existencias', 'id_variante', Icons.style_outlined,
    ['id_variante', 'id_producto', 'id_talla', 'id_color', 'stock_actual', 'precio_venta', 'estado']),
  AdminDomainDefinition('compras', 'compras', 'Compras',
    'Entradas de mercancía', 'id_compra', Icons.local_shipping_outlined,
    ['id_compra', 'id_proveedor', 'fecha_compra', 'estado']),
  AdminDomainDefinition('usuarios', 'usuarios', 'Usuarios',
    'Cuentas y estado de acceso', 'id_usuario', Icons.manage_accounts_outlined,
    ['id_usuario', 'id_cliente', 'estado']),
  AdminDomainDefinition('roles', 'roles', 'Roles',
    'Roles de acceso', 'id_rol', Icons.admin_panel_settings_outlined,
    ['id_rol', 'nombre_rol', 'estado']),
  AdminDomainDefinition('ventas', 'ventas', 'Ventas',
    'Pedidos y estados de venta', 'id_venta', Icons.receipt_long_outlined,
    ['id_venta', 'fecha_venta', 'total_venta', 'estado', 'origen']),
  AdminDomainDefinition('separe', 'planes_separe', 'Plan Separe',
    'Planes y vencimientos', 'id_plan_separe', Icons.bookmark_outline,
    ['id_plan_separe', 'id_cliente', 'fecha_inicio', 'fecha_vencimiento', 'estado']),
  AdminDomainDefinition('abonos', 'abonos_separe', 'Abonos',
    'Pagos de planes separe', 'id_abono', Icons.payments_outlined,
    ['id_abono', 'id_plan_separe', 'valor_abono', 'fecha_abono']),
  AdminDomainDefinition('devoluciones', 'devoluciones', 'Devoluciones',
    'Devoluciones registradas', 'id_devolucion', Icons.assignment_return_outlined,
    ['id_devolucion', 'id_venta', 'estado']),
  AdminDomainDefinition('devoluciones', 'cambios', 'Cambios',
    'Cambios de prendas', 'id_cambio', Icons.swap_horiz_outlined,
    ['id_cambio', 'estado']),
  AdminDomainDefinition('perdidas', 'perdidas', 'Pérdidas',
    'Movimientos de pérdida', 'id_perdida', Icons.report_problem_outlined,
    ['id_perdida', 'estado']),
];

class AdminDomainPage extends StatefulWidget {
  final AdminDomainDefinition definition;
  const AdminDomainPage({super.key, required this.definition});
  @override
  State<AdminDomainPage> createState() => _AdminDomainPageState();
}

class _AdminDomainPageState extends State<AdminDomainPage> {
  late Future<List<Map<String, dynamic>>> _future;
  int _offset = 0;
  static const _size = 30;
  @override
  void initState() { super.initState(); _refresh(); }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final def = widget.definition;
    await AdminPermissions.instance.require(def.module, 'view');
    final result = await Supabase.instance.client.from(def.table)
      .select('*').range(_offset, _offset + _size - 1);
    return result.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _refresh() => _future = _fetch();

  Future<void> _annul(Map<String, dynamic> row) async {
    final d = widget.definition;
    final id = (row[d.primaryKey] as num?)?.toInt();
    if (id == null) return;
    final confirmed = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar anulación'),
        content: Text('¿Anular ${d.title.toLowerCase()} #$id? '
          'La operación puede modificar inventario, reservas o saldos. '
          'No se puede deshacer desde esta pantalla.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular')),
        ],
      ));
    if (confirmed != true || !mounted) return;
    try {
      final service = AdministrativeTransactions.instance;
      switch (d.table) {
        case 'compras': await service.annulPurchase(id);
        case 'planes_separe': await service.annulLayaway(id);
        case 'abonos_separe': await service.annulPayment(id);
        case 'perdidas':
          await service.manageLoss('anular', row);
        default: throw StateError('Anulación no soportada');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anulación confirmada por Supabase')));
      setState(_refresh);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo anular: $error')));
    }
  }
  void _page(int offset) {
    setState(() { _offset = offset; _refresh(); });
  }

  String _format(Object? value) {
    if (value == null) return '—';
    final text = value.toString();
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    return Scaffold(
      appBar: AppBar(title: Text(def.title.toUpperCase()),
        actions: [IconButton(tooltip: 'Actualizar',
          onPressed: () => setState(_refresh),
          icon: const Icon(Icons.refresh))]),
      floatingActionButton: const ['compras', 'ventas', 'separe', 'devoluciones', 'perdidas']
        .contains(def.module) && const ['compras', 'ventas', 'planes_separe', 'devoluciones', 'perdidas']
        .contains(def.table)
        ? FutureBuilder<bool>(
            future: AdminPermissions.instance.can(def.module, 'create'),
            builder: (context, permission) => permission.data == true
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar'),
                  onPressed: () async {
                    final saved = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => def.module == 'perdidas'
                        ? const LossEntryPage()
                        : TransactionEntryPage(module: def.module)));
                    if (saved == true && mounted) setState(_refresh);
                  },
                ) : const SizedBox.shrink(),
          )
        : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No fue posible consultar ${def.title}. '
              'Comprueba permisos, conexión y políticas RLS.')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(def.description, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Consulta autorizada. Crear, editar, anular o eliminar '
              'requiere el flujo específico de la web; no se permite '
              'modificar registros desde esta pantalla.'),
            const SizedBox(height: 16),
            if (rows.isEmpty) const Text('No hay registros visibles.'),
            for (final row in rows)
              Card(child: ExpansionTile(
                title: Text('${def.title} #${_format(row[def.primaryKey])}'),
                subtitle: Text(def.fields.skip(1)
                  .where((key) => row[key] != null).take(2)
                  .map((key) => _format(row[key])).join(' · ')),
                children: [
                  if (const ['compras', 'planes_separe', 'abonos_separe', 'perdidas']
                    .contains(def.table) &&
                    !const ['ANULADA', 'ANULADO'].contains(
                      row['estado']?.toString().toUpperCase()))
                    FutureBuilder<bool>(
                      future: AdminPermissions.instance.can(def.module, 'annul'),
                      builder: (context, allowed) => allowed.data == true
                        ? Padding(padding: const EdgeInsets.all(8),
                            child: OutlinedButton.icon(
                              onPressed: () => _annul(row),
                              icon: const Icon(Icons.block_outlined),
                              label: const Text('Anular')))
                        : const SizedBox.shrink()),
                  for (final key in def.fields)
                    if (row.containsKey(key))
                      ListTile(dense: true, title: Text(key),
                        subtitle: SelectableText(_format(row[key]))),
                ],
              )),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              OutlinedButton(onPressed: _offset > 0
                ? () => _page(_offset - _size) : null,
                child: const Text('Anterior')),
              Text('Página ${_offset ~/ _size + 1}'),
              OutlinedButton(onPressed: rows.length == _size
                ? () => _page(_offset + _size) : null,
                child: const Text('Siguiente')),
            ]),
          ]);
        }),
    );
  }
}
