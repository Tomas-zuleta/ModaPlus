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

const masterDataModules = <MasterDataDefinition>[
  MasterDataDefinition('tallas', 'tallas', 'Tallas', 'id_talla',
    Icons.straighten_outlined, ['nombre_talla'], ['nombre_talla']),
  MasterDataDefinition('clientes', 'clientes', 'Clientes', 'id_cliente',
    Icons.people_outline,
    ['tipo_documento', 'identificacion', 'nombres', 'apellidos',
      'telefono', 'correo', 'direccion'],
    ['identificacion', 'nombres', 'apellidos', 'telefono']),
];

const _fieldLabels = <String, String>{
  'nombre_talla': 'Nombre de la talla',
  'tipo_documento': 'Tipo de documento',
  'identificacion': 'Número de documento',
  'nombres': 'Nombres',
  'apellidos': 'Apellidos',
  'telefono': 'Teléfono',
  'correo': 'Correo electrónico',
  'direccion': 'Dirección',
};

class MasterDataPage extends StatefulWidget {
  final MasterDataDefinition definition;
  const MasterDataPage({super.key, required this.definition});
  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  late Future<List<Map<String, dynamic>>> _rows;
  late Future<bool> _canCreate, _canEdit, _canDelete;
  String _search = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _canCreate = AdminPermissions.instance.can(widget.definition.module, 'create');
    _canEdit = AdminPermissions.instance.can(widget.definition.module, 'edit');
    _canDelete = AdminPermissions.instance.can(widget.definition.module, 'delete');
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final d = widget.definition;
    await AdminPermissions.instance.require(d.module, 'view');
    final result = await Supabase.instance.client.from(d.table)
      .select('*').limit(500);
    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void _refresh() => _rows = _fetch();

  Future<void> _edit([Map<String, dynamic>? current]) async {
    final editor = _MasterDataEditor(definition: widget.definition,
      record: current, compact: widget.definition.columns.length <= 2);
    final saved = widget.definition.columns.length > 2
      ? await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) => editor))
      : await showModalBottomSheet<bool>(
          context: context, useSafeArea: true, isScrollControlled: true,
          builder: (_) => editor);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado correctamente.')));
      setState(_refresh);
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> row) async {
    final d = widget.definition;
    final active = row['estado']?.toString().toUpperCase() == 'ACTIVO';
    final next = active ? 'INACTIVO' : 'ACTIVO';
    final yes = await showModalBottomSheet<bool>(
      context: context, useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.help_outline, size: 42),
          const SizedBox(height: 10),
          Text(active ? '¿Desactivar registro?' : '¿Activar registro?',
            style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 10),
          const Text('Se conserva su historial. Puedes volver a cambiarlo.'),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => Navigator.pop(sheetContext, true),
            child: const Text('Sí, continuar')),
          TextButton(onPressed: () => Navigator.pop(sheetContext, false),
            child: const Text('Cancelar')),
        ]),
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AdminPermissions.instance.require(d.module, 'edit');
      await Supabase.instance.client.from(d.table)
        .update({'estado': next}).eq(d.key, row[d.key]).select(d.key).single();
      if (mounted) setState(_refresh);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el estado: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final d = widget.definition;
    final yes = await showModalBottomSheet<bool>(
      context: context, useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('¿Eliminar este registro?',
            style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('No podrás recuperarlo. Si tiene ventas o movimientos '
            'asociados, Supabase impedirá eliminarlo.'),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => Navigator.pop(sheetContext, true),
            child: const Text('Eliminar permanentemente')),
          TextButton(onPressed: () => Navigator.pop(sheetContext, false),
            child: const Text('Cancelar')),
        ]),
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AdminPermissions.instance.require(d.module, 'delete');
      await Supabase.instance.client.from(d.table)
        .delete().eq(d.key, row[d.key]).select(d.key).single();
      if (mounted) setState(_refresh);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar. '
          'Puede estar vinculado a una compra o venta. Detalle: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.definition;
    return Scaffold(
      appBar: AppBar(title: Text(d.title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(d.title == 'Clientes' ? 'Personas que compran en tu tienda'
                : 'Tallas que puedes asignar a tus prendas',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              FutureBuilder<bool>(
                future: _canCreate,
                builder: (context, permission) => permission.data == true
                  ? FilledButton.icon(
                    onPressed: _saving ? null : () => _edit(),
                    icon: const Icon(Icons.add),
                    label: Text(d.title == 'Clientes'
                      ? 'Registrar cliente' : 'Añadir talla'))
                  : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar un registro'),
                onChanged: (value) => setState(() => _search = value.toLowerCase())),
              const SizedBox(height: 14),
              if (snapshot.hasError)
                Card(child: ListTile(
                  title: const Text('No se pudieron cargar los datos.'),
                  subtitle: Text('${snapshot.error}'),
                  trailing: IconButton(
                    onPressed: () => setState(_refresh),
                    icon: const Icon(Icons.refresh)))),
              if (snapshot.hasData) ...[
                if (snapshot.data!.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text('Aún no hay registros. Usa el botón de arriba para empezar.'))),
                for (final row in snapshot.data!.where((row) =>
                  row.values.join(' ').toLowerCase().contains(_search)))
                  Card(child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                    leading: CircleAvatar(child: Icon(d.icon)),
                    title: Text(d.module == 'clientes'
                      ? '${row['nombres'] ?? ''} ${row['apellidos'] ?? ''}'
                      : row['nombre_talla']?.toString() ?? 'Sin nombre'),
                    subtitle: Text('Estado: ${row['estado'] ?? '-'}'),
                    trailing: FutureBuilder<List<bool>>(
                      future: Future.wait([_canEdit, _canDelete]),
                      builder: (context, allowed) {
                        final canEdit = allowed.data?.first ?? false;
                        final canDelete = allowed.data?.last ?? false;
                        if (!canEdit && !canDelete) {
                          return const SizedBox.shrink();
                        }
                        return PopupMenuButton<String>(
                          tooltip: 'Acciones',
                          enabled: !_saving,
                          onSelected: (value) {
                            if (value == 'edit' && canEdit) _edit(row);
                            if (value == 'status' && canEdit) _changeStatus(row);
                            if (value == 'delete' && canDelete) _delete(row);
                          },
                          itemBuilder: (_) => [
                            if (canEdit) ...[
                              const PopupMenuItem(
                                value: 'edit', child: Text('Editar')),
                              const PopupMenuItem(
                                value: 'status',
                                child: Text('Activar / Desactivar')),
                            ],
                            if (canDelete)
                              const PopupMenuItem(
                                value: 'delete', child: Text('Eliminar')),
                          ],
                        );
                      },
                    ),
                    onTap: () => _edit(row),
                  )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MasterDataEditor extends StatefulWidget {
  final MasterDataDefinition definition;
  final Map<String, dynamic>? record;
  final bool compact;
  const _MasterDataEditor({
    required this.definition,
    required this.record,
    required this.compact,
  });
  @override
  State<_MasterDataEditor> createState() => _MasterDataEditorState();
}

class _MasterDataEditorState extends State<_MasterDataEditor> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String _state = 'ACTIVO';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final column in widget.definition.columns) {
      _controllers[column] = TextEditingController(
        text: widget.record?[column]?.toString()
          ?? (column == 'tipo_documento' ? 'CC' : ''));
    }
    _state = widget.record?['estado']?.toString() == 'INACTIVO'
      ? 'INACTIVO' : 'ACTIVO';
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final d = widget.definition;
      await AdminPermissions.instance.require(
        d.module, widget.record == null ? 'create' : 'edit');
      final data = <String, dynamic>{
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
        'estado': _state,
      };
      if (d.module == 'clientes') {
        final email = _controllers['correo']!.text.trim().toLowerCase();
        data['correo'] = email.isEmpty ? null : email;
        data['direccion'] = _controllers['direccion']!.text.trim().isEmpty
          ? null : _controllers['direccion']!.text.trim();
      }
      final db = Supabase.instance.client;
      if (widget.record == null) {
        await db.from(d.table).insert(data).select(d.key).single();
      } else {
        await db.from(d.table).update(data).eq(d.key, widget.record![d.key])
          .select(d.key).single();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supabase no pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _formBody() {
    final d = widget.definition;
    return SafeArea(
      top: !widget.compact,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
          MediaQuery.viewInsetsOf(context).bottom + 24),
        child: SingleChildScrollView(child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.compact) ...[
                Center(child: Container(
                  height: 5, width: 44,
                  decoration: BoxDecoration(color: Colors.black26,
                    borderRadius: BorderRadius.circular(9)))),
                const SizedBox(height: 18),
                Text(widget.record == null ? 'Nueva talla' : 'Editar talla',
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 18),
              ],
              for (final field in d.columns) ...[
                TextFormField(
                  controller: _controllers[field],
                  decoration: InputDecoration(
                    labelText: _fieldLabels[field] ?? field),
                  keyboardType: field == 'correo'
                    ? TextInputType.emailAddress
                    : field == 'telefono'
                      ? TextInputType.phone : TextInputType.text,
                  textCapitalization: field == 'correo'
                    ? TextCapitalization.none : TextCapitalization.sentences,
                  validator: (value) {
                    final content = (value ?? '').trim();
                    if (d.requiredFields.contains(field) && content.isEmpty) {
                      return 'Este dato es obligatorio.';
                    }
                    if (field == 'correo' && content.isNotEmpty &&
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(content)) {
                      return 'Revisa el correo electrónico.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],
              DropdownButtonFormField<String>(
                initialValue: _state,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                  DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
                ],
                onChanged: (value) => setState(() => _state = value ?? _state)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar registro')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ],
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.compact
    ? _formBody()
    : Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null
          ? 'Registrar cliente' : 'Actualizar cliente')),
      body: _formBody(),
    );
}
