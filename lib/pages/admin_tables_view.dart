import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/admin_table_registry.dart';

/// Explorador de lectura para las tablas administrativas compartidas con web.
/// No escribe, elimina ni cambia estados. RLS y permisos siguen en Supabase.
class AdminTablesView extends StatefulWidget {
  const AdminTablesView({super.key});
  @override
  State<AdminTablesView> createState() => _AdminTablesViewState();
}

class _AdminTablesViewState extends State<AdminTablesView> {
  AdminTableDefinition? _selected;
  Future<List<Map<String, dynamic>>>? _rows;
  static const _pageSize = 30;
  int _offset = 0;

  Future<List<Map<String, dynamic>>> _load(AdminTableDefinition table, int offset) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      throw StateError('Inicia sesión para consultar tablas');
    }
    final data = await Supabase.instance.client
      .from(table.name).select('*').range(offset, offset + _pageSize - 1);
    return data.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void _choose(AdminTableDefinition table) {
    setState(() {
      _selected = table;
      _offset = 0;
      _rows = _load(table, 0);
    });
  }

  void _page(int offset) {
    final table = _selected;
    if (table == null) return;
    setState(() {
      _offset = offset;
      _rows = _load(table, offset);
    });
  }

  // No presentar identificadores de autenticación ni datos sensibles
  // en el explorador genérico. Las pantallas específicas gestionan PII.
  bool _hidden(String key) {
    final k = key.toLowerCase();
    return k.contains('password') || k.contains('contraseña') ||
      k.contains('token') || k.contains('secret') || k.contains('auth_user_id') ||
      k.contains('identificacion') || k.contains('documento') ||
      k.contains('correo') || k.contains('email') || k.contains('telefono') ||
      k.contains('direccion') || k.contains('comprobante') ||
      k.contains('url_foto');
  }

  String _display(Object? value) {
    if (value == null) return '—';
    final text = value.toString();
    return text.length > 150 ? '${text.substring(0, 150)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final table = _selected;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('TABLAS DE MODAPLUS', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Consulta de solo lectura. Los datos dependen de los permisos '
        'de Supabase y de las políticas RLS. Se ocultan datos sensibles.'),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Seleccionar tabla', border: OutlineInputBorder()),
        value: table?.name,
        items: [
          for (final t in adminTables)
            DropdownMenuItem(value: t.name, child: Text('${t.label} · ${t.name}',
              overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (name) {
          if (name == null) return;
          _choose(adminTables.firstWhere((t) => t.name == name));
        },
      ),
      if (table != null) ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Text('Registros ${_offset + 1}–${_offset + _pageSize} (máximo)',
            style: theme.textTheme.bodySmall)),
          IconButton(tooltip: 'Actualizar',
            onPressed: () => _page(_offset),
            icon: const Icon(Icons.refresh)),
        ]),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _rows,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const Card(child: Padding(padding: EdgeInsets.all(16),
                child: Text('No se pudo consultar esta tabla. Puede faltar '
                  'permiso de lectura o conexión.')));
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return const Padding(
              padding: EdgeInsets.all(20), child: Text('No hay registros visibles.'));
            final columns = rows.expand((row) => row.keys).toSet()
              .where((key) => !_hidden(key)).toList()..sort();
            return Column(children: [
              for (final row in rows)
                Card(child: ExpansionTile(
                  title: Text('${table.label} · registro ${_offset + rows.indexOf(row) + 1}'),
                  subtitle: Text('${columns.length} campos visibles'),
                  children: [
                    for (final key in columns)
                      ListTile(dense: true, title: Text(key,
                        style: theme.textTheme.labelMedium),
                        subtitle: SelectableText(_display(row[key]))),
                  ],
                )),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                OutlinedButton(onPressed: _offset > 0
                  ? () => _page((_offset - _pageSize).clamp(0, _offset)) : null,
                  child: const Text('Anterior')),
                Text('Página ${(_offset ~/ _pageSize) + 1}'),
                OutlinedButton(onPressed: rows.length == _pageSize
                  ? () => _page(_offset + _pageSize) : null,
                  child: const Text('Siguiente')),
              ]),
            ]);
          },
        ),
      ],
    ]);
  }
}
