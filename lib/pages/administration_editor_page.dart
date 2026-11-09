import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_permissions.dart';
import '../services/administrative_transactions.dart';

/// Formularios de catálogo y asignación de roles. No modifican stock existente.
class AdministrationEditorPage extends StatefulWidget {
  final String table;
  final Map<String, dynamic>? record;
  const AdministrationEditorPage({super.key, required this.table, this.record});
  @override
  State<AdministrationEditorPage> createState() => _AdministrationEditorPageState();
}

class _AdministrationEditorPageState extends State<AdministrationEditorPage> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _selected = <String, int?>{};
  final _roleIds = <int>{};
  List<Map<String, dynamic>> _categories = [], _products = [], _sizes = [],
    _colors = [], _roles = [];
  late final Future<void> _loading;
  bool _busy = false;
  String _status = 'ACTIVO';
  String _gender = 'Mujer';

  bool get _product => widget.table == 'productos';
  bool get _variant => widget.table == 'variantes_producto';
  bool get _user => widget.table == 'usuarios';
  bool get _role => widget.table == 'roles';
  String get _module => _user ? 'usuarios' : _role ? 'roles' : 'inventario';
  String get _pk => _product ? 'id_producto' :
    _variant ? 'id_variante' : _role ? 'id_rol' : 'id_usuario';

  @override
  void initState() {
    super.initState();
    final row = widget.record ?? {};
    for (final field in _product
        ? ['referencia', 'nombre_producto', 'descripcion']
        : _variant ? ['precio_venta', 'stock_minimo']
        : _role ? ['nombre_rol', 'descripcion'] : <String>[]) {
      _controllers[field] = TextEditingController(text: row[field]?.toString() ?? '');
    }
    _status = row['estado']?.toString().toUpperCase() == 'INACTIVO'
      ? 'INACTIVO' : 'ACTIVO';
    _gender = row['genero']?.toString() == 'Hombre' ? 'Hombre' : 'Mujer';
    _loading = _load();
  }
  Future<void> _load() async {
    final db = Supabase.instance.client;
    if (_product) {
      _categories = (await db.from('categorias').select('id_categoria,nombre_categoria')
        .limit(300)).map((e) => Map<String, dynamic>.from(e)).toList();
      _selected['id_categoria'] = (widget.record?['id_categoria'] as num?)?.toInt();
    } else if (_variant) {
      final lists = await Future.wait([
        db.from('productos').select('id_producto,nombre_producto').limit(500),
        db.from('tallas').select('id_talla,nombre_talla').limit(300),
        db.from('colores').select('id_color,nombre_color').limit(300),
      ]);
      _products = lists[0].map((e) => Map<String, dynamic>.from(e)).toList();
      _sizes = lists[1].map((e) => Map<String, dynamic>.from(e)).toList();
      _colors = lists[2].map((e) => Map<String, dynamic>.from(e)).toList();
      for (final field in ['id_producto', 'id_talla', 'id_color']) {
        _selected[field] = (widget.record?[field] as num?)?.toInt();
      }
    } else if (_user) {
      _roles = (await db.from('roles').select('id_rol,nombre_rol,estado')
        .limit(300)).map((e) => Map<String, dynamic>.from(e)).toList();
      final userId = (widget.record?['id_usuario'] as num?)?.toInt();
      if (userId != null) {
        final assignments = await db.from('usuarios_roles')
          .select('id_rol').eq('id_usuario', userId);
        _roleIds.addAll(assignments.map((e) => (e['id_rol'] as num).toInt()));
      }
    }
  }
  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }
  Widget _field(String key, String label, {bool numeric = false}) =>
    TextFormField(controller: _controllers[key],
      decoration: InputDecoration(labelText: label),
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
      validator: (value) {
        if ((value ?? '').trim().isEmpty && key != 'descripcion') {
          return 'Campo obligatorio';
        }
        if (numeric && (double.tryParse(value ?? '') ?? -1) < 0) {
          return 'Número no negativo';
        }
        return null;
      });
  Widget _choice(String key, String title, List<Map<String, dynamic>> items,
      String id, String label) => DropdownButtonFormField<int>(
    value: _selected[key], isExpanded: true,
    decoration: InputDecoration(labelText: title),
    items: items.map((item) => DropdownMenuItem<int>(
      value: (item[id] as num).toInt(),
      child: Text(item[label]?.toString() ?? '', overflow: TextOverflow.ellipsis))).toList(),
    onChanged: (value) => setState(() => _selected[key] = value),
    validator: (value) => value == null ? 'Selecciona $title' : null);

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_user && _roleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un rol')));
      return;
    }
    setState(() => _busy = true);
    try {
      final existing = widget.record;
      await AdminPermissions.instance.require(_module,
        existing == null ? 'create' : 'edit');
      final db = Supabase.instance.client;
      if (_user) {
        final userId = (existing?['id_usuario'] as num).toInt();
        await AdministrativeTransactions.instance.assignRoles(userId, _roleIds.toList());
      } else {
        final data = <String, dynamic>{'estado': _status};
        if (_product) {
          data.addAll({
            'referencia': _controllers['referencia']!.text.trim().toUpperCase(),
            'nombre_producto': _controllers['nombre_producto']!.text.trim(),
            'descripcion': _controllers['descripcion']!.text.trim(),
            'id_categoria': _selected['id_categoria'],
            'genero': _gender,
          });
        } else if (_variant) {
          data.addAll({
            'id_producto': _selected['id_producto'],
            'id_talla': _selected['id_talla'],
            'id_color': _selected['id_color'],
            'precio_venta': double.parse(_controllers['precio_venta']!.text),
            'stock_minimo': int.parse(_controllers['stock_minimo']!.text),
            'stock_maximo': int.parse(_controllers['stock_minimo']!.text),
          });
          if (existing == null) data['stock_actual'] = 0;
        } else if (_role) {
          data.addAll({
            'nombre_rol': _controllers['nombre_rol']!.text.trim(),
            'descripcion': _controllers['descripcion']!.text.trim(),
          });
        }
        if (existing == null) {
          await db.from(widget.table).insert(data);
        } else {
          await db.from(widget.table).update(data).eq(_pk, existing[_pk]);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_user ? 'Asignar roles' : 'Editar ${widget.table}')),
    body: FutureBuilder<void>(future: _loading, builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return Form(key: _form, child: ListView(padding: const EdgeInsets.all(20),
        children: [
          if (_product) ...[
            _choice('id_categoria', 'Categoría', _categories,
              'id_categoria', 'nombre_categoria'),
            _field('referencia', 'Referencia'),
            _field('nombre_producto', 'Nombre'),
            _field('descripcion', 'Descripción'),
            DropdownButtonFormField<String>(value: _gender,
              decoration: const InputDecoration(labelText: 'Género'),
              items: const ['Mujer', 'Hombre'].map((e) =>
                DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _gender = v ?? _gender)),
          ],
          if (_variant) ...[
            _choice('id_producto', 'Producto', _products, 'id_producto', 'nombre_producto'),
            _choice('id_talla', 'Talla', _sizes, 'id_talla', 'nombre_talla'),
            _choice('id_color', 'Color', _colors, 'id_color', 'nombre_color'),
            _field('precio_venta', 'Precio de venta', numeric: true),
            _field('stock_minimo', 'Stock mínimo', numeric: true),
            const Text('El stock actual solo cambia mediante compras, ventas y otras RPC.'),
          ],
          if (_role) ...[
            _field('nombre_rol', 'Nombre del rol'),
            _field('descripcion', 'Descripción'),
            const Text('Los permisos granulares se administran en la matriz web.'),
          ],
          if (_user) ...[
            const Text('Selecciona los roles de esta cuenta:'),
            for (final role in _roles)
              CheckboxListTile(
                title: Text(role['nombre_rol']?.toString() ?? ''),
                value: _roleIds.contains((role['id_rol'] as num).toInt()),
                onChanged: (value) => setState(() {
                  final id = (role['id_rol'] as num).toInt();
                  if (value == true) { _roleIds.add(id); }
                  else { _roleIds.remove(id); }
                })),
          ],
          if (!_user) DropdownButtonFormField<String>(value: _status,
            decoration: const InputDecoration(labelText: 'Estado'),
            items: const ['ACTIVO', 'INACTIVO'].map((v) =>
              DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _status = v ?? _status)),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Guardando...' : 'Guardar')),
        ]));
    }),
  );
}
