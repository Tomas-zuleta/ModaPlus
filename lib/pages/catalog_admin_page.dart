import 'package:flutter/material.dart';
import '../services/admin_permissions.dart';
import '../services/catalog_admin_service.dart';
import 'suppliers_view.dart';
import 'admin_domain_page.dart';
import 'master_data_page.dart';

/// Un menú por tareas, no un catálogo de nombres técnicos de tablas.
class CatalogAdminPage extends StatelessWidget {
  const CatalogAdminPage({super.key});

  void _open(BuildContext context, String title, Widget child) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => child));
  }

  Widget _entry(BuildContext context, {
    required IconData icon, required String title,
    required String hint, required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE9F5EF),
        child: Icon(icon, color: const Color(0xFF28744D)),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(hint, style: Theme.of(context).textTheme.bodyMedium)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );

  Widget _section(BuildContext context, String title, String hint) =>
    Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(hint, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );

  @override
  Widget build(BuildContext context) {
    AdminDomainDefinition? find(String table) {
      for (final item in adminDomainModules) {
        if (item.table == table) return item;
      }
      return null;
    }
    void openDomain(String table) {
      final item = find(table);
      if (item != null) _open(context, item.title,
        AdminDomainPage(definition: item));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 34),
      children: [
        Text('Gestionar mi tienda',
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Elige qué quieres hacer. Puedes crear, consultar '
          'y actualizar registros con los permisos de tu cuenta.'),
        _section(context, 'Productos e inventario',
          'Organiza lo que vendes y consulta las existencias.'),
        _entry(context, icon: Icons.checkroom_outlined,
          title: 'Mis productos',
          hint: 'Crear prendas, corregir su información y cambiar su estado.',
          onTap: () => openDomain('productos')),
        _entry(context, icon: Icons.inventory_2_outlined,
          title: 'Precios, tallas y existencias',
          hint: 'Registrar variantes y consultar unidades disponibles.',
          onTap: () => openDomain('variantes_producto')),
        _entry(context, icon: Icons.category_outlined,
          title: 'Categorías',
          hint: 'Organizar camisetas, pantalones y otras clases de productos.',
          onTap: () => _open(context, 'Categorías',
            const CatalogReferencePage(module: 'categorias'))),
        _entry(context, icon: Icons.palette_outlined,
          title: 'Colores',
          hint: 'Crear colores y cambiar sus datos.',
          onTap: () => _open(context, 'Colores',
            const CatalogReferencePage(module: 'colores'))),
        _entry(context, icon: Icons.straighten_outlined,
          title: 'Tallas',
          hint: 'Añadir o actualizar tallas.',
          onTap: () => _open(context, 'Tallas',
            MasterDataPage(definition: masterDataModules.first))),
        _section(context, 'Personas',
          'Organiza la información para vender y comprar.'),
        _entry(context, icon: Icons.people_outline,
          title: 'Clientes',
          hint: 'Registrar clientes, actualizar datos y cambiar su estado.',
          onTap: () => _open(context, 'Clientes',
            MasterDataPage(definition: masterDataModules.last))),
        _entry(context, icon: Icons.local_shipping_outlined,
          title: 'Proveedores',
          hint: 'Registrar a quién compras mercancía.',
          onTap: () => _open(context, 'Proveedores',
            Scaffold(
              appBar: AppBar(title: const Text('Proveedores')),
              body: const SafeArea(child: SuppliersView())))),
        _section(context, 'Movimientos de la tienda',
          'Registra compras y revisa el historial.'),
        _entry(context, icon: Icons.shopping_bag_outlined,
          title: 'Compras a proveedores',
          hint: 'Agregar mercancía mediante una compra registrada.',
          onTap: () => openDomain('compras')),
        _entry(context, icon: Icons.receipt_long_outlined,
          title: 'Historial de ventas',
          hint: 'Consultar ventas realizadas y revisar sus datos.',
          onTap: () => openDomain('ventas')),
        _entry(context, icon: Icons.assignment_return_outlined,
          title: 'Devoluciones',
          hint: 'Registrar solicitudes y revisar devoluciones existentes.',
          onTap: () => openDomain('devoluciones')),
        _entry(context, icon: Icons.report_problem_outlined,
          title: 'Pérdidas',
          hint: 'Registrar prendas dañadas o perdidas.',
          onTap: () => openDomain('perdidas')),
        _section(context, 'Seguridad',
          'Controla quién puede entrar y qué puede consultar.'),
        _entry(context, icon: Icons.manage_accounts_outlined,
          title: 'Usuarios',
          hint: 'Consultar cuentas y asignar roles.',
          onTap: () => openDomain('usuarios')),
        _entry(context, icon: Icons.admin_panel_settings_outlined,
          title: 'Roles',
          hint: 'Consultar y editar los roles existentes.',
          onTap: () => openDomain('roles')),
      ],
    );
  }
}

class CatalogReferencePage extends StatefulWidget {
  final String module;
  const CatalogReferencePage({super.key, required this.module});
  @override
  State<CatalogReferencePage> createState() => _CatalogReferencePageState();
}

class _CatalogReferencePageState extends State<CatalogReferencePage> {
  late Future<List<Map<String, dynamic>>> _rows;
  late Future<bool> _canCreate;
  late Future<bool> _canEdit;
  late Future<bool> _canDelete;
  bool _busy = false;
  bool get _category => widget.module == 'categorias';
  String get _key => _category ? 'id_categoria' : 'id_color';
  String get _name => _category ? 'nombre_categoria' : 'nombre_color';
  @override
  void initState() {
    super.initState();
    _reload();
    _canCreate = AdminPermissions.instance.can(widget.module, 'create');
    _canEdit = AdminPermissions.instance.can(widget.module, 'edit');
    _canDelete = AdminPermissions.instance.can(widget.module, 'delete');
  }
  void _reload() {
    _rows = CatalogAdminService.instance.list(widget.module);
  }
  Future<void> _edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?[_name]?.toString() ?? '');
    final hex = TextEditingController(text: row?['codigo_hex']?.toString() ?? '#000000');
    var status = row?['estado']?.toString().toUpperCase() == 'INACTIVO'
      ? 'INACTIVO' : 'ACTIVO';
    final result = await showModalBottomSheet<({String name, String hex, String status})>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 22),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26, borderRadius: BorderRadius.circular(8)))),
                const SizedBox(height: 14),
                Text(row == null ? 'Agregar ${_category ? "categoría" : "color"}'
                  : 'Editar ${_category ? "categoría" : "color"}',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 18),
                TextField(controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre')),
                if (!_category) ...[
                  const SizedBox(height: 12),
                  TextField(controller: hex,
                    decoration: const InputDecoration(
                      labelText: 'Color HEX', hintText: '#112233')),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                    DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
                  ],
                  onChanged: (v) => update(() => status = v ?? status)),
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: () {
                  if (name.text.trim().isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Escribe un nombre.')));
                    return;
                  }
                  Navigator.pop(sheetContext, (
                    name: name.text.trim(), hex: hex.text.trim(), status: status));
                }, icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios')),
                TextButton(onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancelar')),
              ],
            )),
          ),
        ),
      ),
    );
    // Los controladores se liberan tras el cierre del diálogo.
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await CatalogAdminService.instance.save(widget.module,
        id: (row?[_key] as num?)?.toInt(), name: result.name,
        hex: result.hex, status: result.status);
      if (!mounted) return;
      setState(_reload);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(context: context, builder: (context) =>
      AlertDialog(title: const Text('Confirmar eliminación'),
        content: const Text('Solo se eliminará si Supabase lo permite y '
          'no existen relaciones que lo impidan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar')),
        ]));
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await CatalogAdminService.instance.delete(widget.module, (row[_key] as num).toInt());
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_category ? 'CATEGORÍAS' : 'COLORES')),
    floatingActionButton: FutureBuilder<bool>(future: _canCreate,
      builder: (context, s) => s.data == true && !_busy
        ? FloatingActionButton(onPressed: () => _edit(), child: const Icon(Icons.add))
        : const SizedBox.shrink()),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error al cargar: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('Sin registros'));
        return ListView.builder(itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final row = snapshot.data![i];
            return Card(child: ListTile(
              title: Text(row[_name]?.toString() ?? 'Sin nombre'),
              subtitle: Text('Estado: ${row['estado'] ?? '-'}'
                '${_category ? '' : ' · HEX: ${row['codigo_hex'] ?? '-'}'}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                FutureBuilder<bool>(future: _canEdit, builder: (context, s) =>
                  s.data == true ? IconButton(icon: const Icon(Icons.edit_outlined),
                    onPressed: _busy ? null : () => _edit(row)) : const SizedBox.shrink()),
                FutureBuilder<bool>(future: _canDelete, builder: (context, s) =>
                  s.data == true ? IconButton(icon: const Icon(Icons.delete_outline),
                    onPressed: _busy ? null : () => _delete(row)) : const SizedBox.shrink()),
              ]),
            ));
          });
      }),
  );
}
