import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_permissions.dart';

class MasterDataDefinition {
  final String module, table, title, key;
  final IconData icon;
  final List<String> columns, requiredFields;
  const MasterDataDefinition(this.module, this.table, this.title, this.key,
    this.icon, this.columns, this.requiredFields);
}

/// Columnas verificadas contra el contrato de guardado de ModaPlus web.
const masterDataModules = <MasterDataDefinition>[
  MasterDataDefinition('tallas', 'tallas', 'Tallas', 'id_talla',
    Icons.straighten_outlined, ['nombre_talla'], ['nombre_talla']),
  MasterDataDefinition('clientes', 'clientes', 'Clientes', 'id_cliente',
    Icons.people_outline,
    ['tipo_documento', 'identificacion', 'nombres', 'apellidos',
      'telefono', 'correo', 'direccion'],
    ['identificacion', 'nombres', 'apellidos', 'telefono']),
];

class MasterDataPage extends StatefulWidget {
  final MasterDataDefinition definition;
  const MasterDataPage({super.key, required this.definition});
  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  late Future<List<Map<String, dynamic>>> _rows;
  late Future<bool> _create, _edit;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
    _create = AdminPermissions.instance.can(widget.definition.module, 'create');
    _edit = AdminPermissions.instance.can(widget.definition.module, 'edit');
  }
  void _load() {
    _rows = _fetch();
  }
  Future<List<Map<String, dynamic>>> _fetch() async {
    final d = widget.definition;
    await AdminPermissions.instance.require(d.module, 'view');
    final result = await Supabase.instance.client.from(d.table)
      .select('*').limit(200);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }
  Future<void> _form([Map<String, dynamic>? existing]) async {
    final d = widget.definition;
    final controllers = <String, TextEditingController>{
      for (final field in d.columns)
        field: TextEditingController(text: existing?[field]?.toString()
          ?? (field == 'tipo_documento' ? 'CC' : '')),
    };
    var status = existing?['estado']?.toString().toUpperCase() == 'INACTIVO'
      ? 'INACTIVO' : 'ACTIVO';
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(existing == null ? 'Crear ${d.title}' : 'Editar ${d.title}'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in d.columns)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(controller: controllers[field],
                    decoration: InputDecoration(labelText: field,
                      border: const OutlineInputBorder()))),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVO', child: Text('ACTIVO')),
                  DropdownMenuItem(value: 'INACTIVO', child: Text('INACTIVO')),
                ],
                onChanged: (value) => update(() => status = value ?? status)),
            ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
            FilledButton(onPressed: () {
              final values = <String, dynamic>{
                for (final entry in controllers.entries)
                  entry.key: entry.value.text.trim(),
                'estado': status,
              };
              if (d.requiredFields.any((field) =>
                  (values[field] as String).isEmpty)) return;
              Navigator.pop(dialogContext, values);
            }, child: const Text('Guardar')),
          ],
        ),
      ));
    // No liberar antes de cerrar las animaciones del diálogo.
    if (data == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await AdminPermissions.instance.require(d.module,
        existing == null ? 'create' : 'edit');
      if (d.module == 'clientes') {
        data['correo'] = (data['correo'] as String).isEmpty
          ? null : (data['correo'] as String).toLowerCase();
        data['direccion'] = (data['direccion'] as String).isEmpty
          ? null : data['direccion'];
      }
      if (existing == null) {
        await Supabase.instance.client.from(d.table).insert(data);
      } else {
        await Supabase.instance.client.from(d.table).update(data)
          .eq(d.key, existing[d.key]);
      }
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _toggle(Map<String, dynamic> row) async {
    final d = widget.definition;
    final next = row['estado']?.toString().toUpperCase() == 'ACTIVO'
      ? 'INACTIVO' : 'ACTIVO';
    final ok = await showDialog<bool>(context: context, builder: (context) =>
      AlertDialog(title: Text('Cambiar a $next'),
        content: const Text('Confirma el cambio de estado. '
          'El servidor puede rechazarlo si existen restricciones.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar')),
        ]));
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await AdminPermissions.instance.require(d.module, 'edit');
      await Supabase.instance.client.from(d.table)
        .update({'estado': next}).eq(d.key, row[d.key]);
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el estado: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final d = widget.definition;
    return Scaffold(
      appBar: AppBar(title: Text(d.title.toUpperCase())),
      floatingActionButton: FutureBuilder<bool>(future: _create,
        builder: (context, s) => s.data == true && !_busy
          ? FloatingActionButton(onPressed: () => _form(),
              child: const Icon(Icons.add)) : const SizedBox.shrink()),
      body: FutureBuilder<List<Map<String, dynamic>>>(future: _rows,
        builder: (context, s) {
          if (s.hasError) return Center(child: Text('No se pudo consultar ${d.title}. '
            'Comprueba los permisos y la conexión.'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(children: [
            for (final row in s.data!)
              Card(child: ListTile(
                title: Text(d.module == 'clientes'
                  ? '${row['nombres'] ?? ''} ${row['apellidos'] ?? ''}'
                  : row['nombre_talla']?.toString() ?? 'Sin nombre'),
                subtitle: Text('Estado: ${row['estado'] ?? '-'}'),
                trailing: FutureBuilder<bool>(future: _edit,
                  builder: (context, permission) => permission.data == true
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined),
                          onPressed: _busy ? null : () => _form(row)),
                        IconButton(icon: const Icon(Icons.toggle_on_outlined),
                          onPressed: _busy ? null : () => _toggle(row)),
                      ]) : const SizedBox.shrink()),
              )),
          ]);
        }),
    );
  }
}
