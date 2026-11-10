import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_permissions.dart';

/// Matriz legible de permisos. Los cambios se guardan atómicamente por RPC.
class RolePermissionsPage extends StatefulWidget {
  final int roleId;
  final String roleName;
  const RolePermissionsPage({
    super.key, required this.roleId, required this.roleName,
  });

  @override
  State<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends State<RolePermissionsPage> {
  late Future<void> _loading;
  final _modules = <Map<String, dynamic>>[];
  final _permissions = <Map<String, dynamic>>[];
  final _enabled = <String>{};
  bool _saving = false;
  bool _changed = false;

  static const _actions = <String, String>{
    'view': 'Consultar',
    'create': 'Crear',
    'edit': 'Modificar',
    'delete': 'Eliminar',
    'annul': 'Anular',
  };
  static const _moduleNames = <String, String>{
    'dashboard': 'Panel principal',
    'inventario': 'Productos e inventario',
    'colores': 'Colores',
    'tallas': 'Tallas',
    'categorias': 'Categorías',
    'compras': 'Compras',
    'proveedores': 'Proveedores',
    'clientes': 'Clientes',
    'roles': 'Roles y permisos',
    'usuarios': 'Usuarios',
    'ventas': 'Ventas y pedidos',
    'separe': 'Plan Separe',
    'abonos': 'Abonos',
    'devoluciones': 'Devoluciones',
    'perdidas': 'Pérdidas',
  };

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  String _key(int moduleId, int permissionId) =>
    '$moduleId:$permissionId';

  Future<void> _load() async {
    await AdminPermissions.instance.require('roles', 'view');
    final db = Supabase.instance.client;
    final rows = await Future.wait([
      db.from('modulos').select('id_modulo,codigo').order('codigo').limit(120),
      db.from('permisos').select('id_permiso,codigo').order('codigo').limit(50),
      db.from('roles_permisos')
        .select('id_modulo,id_permiso').eq('id_rol', widget.roleId).limit(1000),
    ]);
    _modules.clear();
    _modules.addAll(rows[0]);
    _permissions.clear();
    _permissions.addAll(rows[1]);
    _enabled.clear();
    _enabled.addAll(rows[2].map((row) => _key(
      (row['id_modulo'] as num).toInt(),
      (row['id_permiso'] as num).toInt(),
    )));
    _changed = false;
  }

  Future<bool> _save() async {
    if (_saving || !_changed) return false;
    if (widget.roleId == 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Los permisos del SUPERADMIN están protegidos.')));
      return false;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context, useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('¿Guardar estos permisos?',
              style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text('Actualizarás los permisos de ${widget.roleName}. '
              'Las personas que tengan ese rol podrán utilizar las acciones seleccionadas.'),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('Sí, guardar permisos')),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('Volver')),
          ]),
        ),
      ),
    );
    if (confirmed != true || !mounted) return false;
    setState(() => _saving = true);
    try {
      await AdminPermissions.instance.require('roles', 'edit');
      final pairs = <Map<String, dynamic>>[];
      for (final entry in _enabled) {
        final tokens = entry.split(':');
        pairs.add({
          'id_modulo': int.parse(tokens[0]),
          'id_permiso': int.parse(tokens[1]),
        });
      }
      await Supabase.instance.client.rpc('modaplus_actualizar_permisos_rol',
        params: {'p_rol': widget.roleId, 'p_permisos': pairs});
      if (!mounted) return false;
      setState(() => _changed = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Permisos guardados correctamente.')));
      return true;
    } on PostgrestException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Supabase no guardó los permisos: ${error.message}')));
      return false;
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo guardar: $error')));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Permisos del rol')),
    body: FutureBuilder<void>(future: _loading, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No fue posible cargar los permisos.'),
          Text('${snapshot.error}', textAlign: TextAlign.center),
          TextButton(onPressed: () => setState(() => _loading = _load()),
            child: const Text('Reintentar')),
        ]),
      ));
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final protected = widget.roleId == 1;
      return ListView(padding: const EdgeInsets.all(18), children: [
        Text(widget.roleName,
          style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(protected
          ? 'El SUPERADMIN tiene acceso completo. Sus permisos no se editan aquí.'
          : 'Activa las acciones permitidas para cada área de la tienda. '
            'Los cambios se aplican al pulsar Guardar.'),
        const SizedBox(height: 16),
        for (final module in _modules) ...[
          Card(child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_moduleNames[module['codigo']] ??
                  module['codigo'].toString(),
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                for (final permission in _permissions)
                  if (_actions.containsKey(permission['codigo']))
                    CheckboxListTile(
                      dense: false,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_actions[permission['codigo']]!),
                      value: _enabled.contains(_key(
                        (module['id_modulo'] as num).toInt(),
                        (permission['id_permiso'] as num).toInt())),
                      onChanged: protected || _saving ? null : (checked) {
                        setState(() {
                          final k = _key(
                            (module['id_modulo'] as num).toInt(),
                            (permission['id_permiso'] as num).toInt());
                          if (checked == true) {
                            _enabled.add(k);
                          } else {
                            _enabled.remove(k);
                          }
                          _changed = true;
                        });
                      },
                    ),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
        if (!protected) FilledButton.icon(
          onPressed: _changed && !_saving ? _save : null,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Guardando...' : 'Guardar permisos')),
        const SizedBox(height: 30),
      ]);
    }),
  );
}
