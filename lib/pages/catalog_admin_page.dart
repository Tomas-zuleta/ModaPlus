import 'package:flutter/material.dart';
import '../services/admin_permissions.dart';
import '../services/catalog_admin_service.dart';
import 'suppliers_view.dart';

/// Entrada administrativa por dominio; no ofrece CRUD genérico indiscriminado.
class CatalogAdminPage extends StatelessWidget {
  const CatalogAdminPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('GESTIÓN', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text('Módulos administrativos conectados a Supabase. '
        'Las acciones disponibles dependen de los permisos de tu cuenta.'),
      const SizedBox(height: 16),
      ListTile(leading: const Icon(Icons.local_shipping_outlined),
        title: const Text('Proveedores'), subtitle: const Text('Crear, editar y desactivar'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const Scaffold(body: SafeArea(child: SuppliersView()))))),
      for (final module in const ['categorias', 'colores'])
        ListTile(
          leading: Icon(module == 'categorias' ? Icons.category_outlined : Icons.palette_outlined),
          title: Text(module == 'categorias' ? 'Categorías' : 'Colores'),
          subtitle: const Text('Consultar, crear, editar y eliminar'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CatalogReferencePage(module: module))),
        ),
    ],
  );
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
    final result = await showDialog<({String name, String hex, String status})>(
      context: context, builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(row == null ? 'Crear registro' : 'Editar registro'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
              if (!_category) TextField(controller: hex,
                decoration: const InputDecoration(labelText: 'Código HEX (#RRGGBB)')),
              DropdownButton<String>(value: status, isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                  DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
                ],
                onChanged: (v) => update(() => status = v ?? status)),
            ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
            FilledButton(onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(context, (name: name.text.trim(),
                hex: hex.text.trim(), status: status));
            }, child: const Text('Guardar')),
          ],
        ),
      ));
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
