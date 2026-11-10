import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_permissions.dart';

/// Permisos de un rol existente, editados únicamente mediante una RPC.
class RolePermissionPage extends StatefulWidget {
  final int roleId;
  final String roleName;
  const RolePermissionPage({
    super.key, required this.roleId, required this.roleName,
  });

  @override
  State<RolePermissionPage> createState() => _RolePermissionPageState();
}

class _RolePermissionPageState extends State<RolePermissionPage> {
  late Future<void> _loadFuture;
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _actions = [];
  final Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  String _key(int moduleId, int actionId) => '$moduleId:$actionId';

  Future<void> _load() async {
    await AdminPermissions.instance.require('roles', 'view');
    final db = Supabase.instance.client;
    final result = await Future.wait([
      db.from('modulos').select('id_modulo,codigo').order('codigo'),
      db.from('permisos').select('id_permiso,codigo').order('codigo'),
      db.from('roles_permisos')
        .select('id_modulo,id_permiso').eq('id_rol', widget.roleId),
    ]);
    _modules = result[0].map((e) => Map<String, dynamic>.from(e)).toList();
    _actions = result[1].map((e) => Map<String, dynamic>.from(e)).toList();
    _selected
      ..clear()
      ..addAll(result[2].map((e) => _key(
        (e['id_modulo'] as num).toInt(),
        (e['id_permiso'] as num).toInt())));
  }

  String _moduleName(String code) => const {
    'dashboard': 'Panel de inicio',
    'inventario': 'Inventario y productos',
    'categorias': 'Categorías',
    'colores': 'Colores',
    'tallas': 'Tallas',
    'proveedores': 'Proveedores',
    'clientes': 'Clientes',
    'compras': 'Compras',
    'ventas': 'Ventas y pedidos',
    'separe': 'Plan Separe',
    'abonos': 'Abonos',
    'devoluciones': 'Devoluciones',
    'perdidas': 'Pérdidas',
    'usuarios': 'Usuarios',
    'roles': 'Roles',
  }[code] ?? code;

  String _actionName(String code) => const {
    'view': 'Ver información',
    'create': 'Crear registros',
    'edit': 'Editar registros',
    'delete': 'Eliminar registros',
    'annul': 'Anular movimientos',
    'download': 'Descargar',
  }[code] ?? code;

  Future<void> _save() async {
    if (_saving || widget.roleId <= 1) return;
    setState(() => _saving = true);
    try {
      await AdminPermissions.instance.require('roles', 'edit');
      final changes = <Map<String, int>>[];
      for (final module in _modules) {
        final moduleId = (module['id_modulo'] as num).toInt();
        for (final action in _actions) {
          final actionId = (action['id_permiso'] as num).toInt();
          if (_selected.contains(_key(moduleId, actionId))) {
            changes.add({'id_modulo': moduleId, 'id_permiso': actionId});
          }
        }
      }
      await Supabase.instance.client.rpc('modaplus_actualizar_permisos_rol',
        params: {'p_rol': widget.roleId, 'p_permisos': changes});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Permisos del rol guardados correctamente.')));
      Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Supabase no guardó los permisos: ${error.message}. '
          'En prubasmoda verifica que instalaste el SQL completo.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No fue posible guardar: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos del rol')),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(
            child: Padding(padding: const EdgeInsets.all(20),
              child: Text('No se pudieron cargar los permisos: '
                '${snapshot.error}')));
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(widget.roleName,
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(widget.roleId == 1
                ? 'El Superadmin tiene todos los permisos. Este rol está protegido.'
                : 'Activa lo que podrán hacer las personas que tengan este rol.'),
              const SizedBox(height: 20),
              if (widget.roleId != 1)
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Guardar permisos')),
              const SizedBox(height: 12),
              for (final module in _modules)
                Card(child: ExpansionTile(
                  title: Text(_moduleName(module['codigo']?.toString() ?? ''),
                    style: Theme.of(context).textTheme.titleMedium),
                  subtitle: const Text('Toca para elegir acciones'),
                  children: [
                    for (final action in _actions)
                      CheckboxListTile(
                        title: Text(_actionName(action['codigo']?.toString() ?? '')),
                        value: _selected.contains(_key(
                          (module['id_modulo'] as num).toInt(),
                          (action['id_permiso'] as num).toInt())),
                        onChanged: widget.roleId == 1
                          ? null : (enabled) => setState(() {
                            final key = _key(
                              (module['id_modulo'] as num).toInt(),
                              (action['id_permiso'] as num).toInt());
                            if (enabled == true) { _selected.add(key); }
                            else { _selected.remove(key); }
                          }),
                      ),
                  ],
                )),
              const SizedBox(height: 20),
              if (widget.roleId != 1)
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar permisos')),
            ],
          );
        },
      ),
    );
  }
}
