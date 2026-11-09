import 'package:flutter/material.dart';
import '../services/suppliers_service.dart';

class SuppliersView extends StatefulWidget {
  const SuppliersView({super.key});
  @override
  State<SuppliersView> createState() => _SuppliersViewState();
}

class _SuppliersViewState extends State<SuppliersView> {
  late Future<List<Map<String, dynamic>>> _future;
  String _query = '';
  String _status = 'TODOS';
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() => _future = SuppliersService.instance.list();

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final nit = TextEditingController(text: row?['nit']?.toString() ?? '');
    final name = TextEditingController(text: row?['razon_social']?.toString() ?? '');
    final contact = TextEditingController(text: row?['contacto']?.toString() ?? '');
    final phone = TextEditingController(text: row?['telefono']?.toString() ?? '');
    final email = TextEditingController(text: row?['correo']?.toString() ?? '');
    final address = TextEditingController(text: row?['direccion']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    var state = row?['estado']?.toString() ?? 'ACTIVO';
    var busy = false;
    final saved = await showDialog<bool>(context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, update) =>
        AlertDialog(
          title: Text(row == null ? 'Nuevo proveedor' : 'Editar proveedor'),
          content: SizedBox(width: 440, child: SingleChildScrollView(
            child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nit, decoration: const InputDecoration(labelText: 'NIT *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null),
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Razón social *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Obligatorio' : null),
                TextFormField(controller: contact, decoration: const InputDecoration(labelText: 'Contacto')),
                TextFormField(controller: phone, keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono')),
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo')),
                TextFormField(controller: address, decoration: const InputDecoration(labelText: 'Dirección')),
                DropdownButtonFormField<String>(
                  value: state,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                    DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
                  ],
                  onChanged: busy ? null : (value) => update(() => state = value ?? 'ACTIVO'),
                ),
              ])))),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
            FilledButton(onPressed: busy ? null : () async {
              if (!formKey.currentState!.validate()) return;
              update(() => busy = true);
              try {
                await SuppliersService.instance.save(
                  id: (row?['id_proveedor'] as num?)?.toInt(),
                  nit: nit.text, razonSocial: name.text, contacto: contact.text,
                  telefono: phone.text, correo: email.text,
                  direccion: address.text, estado: state);
                if (context.mounted) Navigator.pop(context, true);
              } catch (_) {
                update(() => busy = false);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo guardar. Comprueba permisos y datos.')));
              }
            }, child: Text(busy ? 'Guardando...' : 'Guardar')),
          ],
        )));
    for (final c in [nit, name, contact, phone, email, address]) { c.dispose(); }
    if (saved == true && mounted) setState(_reload);
  }

  Future<void> _deactivate(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar proveedor'),
        content: Text('¿Desactivar ${row['razon_social']}? No se borrarán compras históricas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar')),
        ]));
    if (ok != true) return;
    try {
      await SuppliersService.instance.deactivate((row['id_proveedor'] as num).toInt());
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo desactivar. Revisa permisos.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final rows = (snapshot.data ?? []).where((row) {
          final matches = _status == 'TODOS' || row['estado'] == _status;
          final text = '${row['razon_social'] ?? ''} ${row['nit'] ?? ''}'.toLowerCase();
          return matches && text.contains(_query.toLowerCase());
        }).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: Text('PROVEEDORES', style: theme.textTheme.headlineSmall)),
            IconButton(tooltip: 'Actualizar', onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh)),
            FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add),
              label: const Text('Nuevo')),
          ]),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search), labelText: 'Buscar por NIT o razón social',
            border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final status in ['TODOS', 'ACTIVO', 'INACTIVO'])
              ChoiceChip(label: Text(status == 'TODOS' ? 'Todos'
                : status == 'ACTIVO' ? 'Activos' : 'Inactivos'),
                showCheckmark: false, selected: _status == status,
                onSelected: (_) => setState(() => _status = status)),
          ]),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(child: Padding(padding: EdgeInsets.all(24),
              child: CircularProgressIndicator())),
          if (snapshot.hasError)
            const Card(child: ListTile(title: Text('No se pudo consultar proveedores.'),
              subtitle: Text('Comprueba la conexión y los permisos de tu cuenta.'))),
          if (snapshot.hasData && rows.isEmpty)
            const Card(child: ListTile(title: Text('No hay proveedores visibles.'))),
          for (final row in rows)
            Card(child: ListTile(
              title: Text('${row['razon_social'] ?? 'Sin nombre'}'),
              subtitle: Text('NIT: ${row['nit'] ?? '—'} · ${row['estado'] ?? '—'}'),
              onTap: () => _edit(row),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _edit(row);
                  if (action == 'deactivate') _deactivate(row);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (row['estado'] == 'ACTIVO')
                    const PopupMenuItem(value: 'deactivate', child: Text('Desactivar')),
                ],
              ),
            )),
          const SizedBox(height: 12),
          Text('Se muestran hasta 300 registros autorizados. Las operaciones '
            'requieren permisos RLS; desactivar conserva el historial de compras.',
            style: theme.textTheme.bodySmall),
        ]);
      },
    );
  }
}
