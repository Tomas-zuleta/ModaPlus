import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/administrative_transactions.dart';

/// Registro de pérdidas vía gestionar_perdida (nunca UPDATE directo a stock).
class LossEntryPage extends StatefulWidget {
  const LossEntryPage({super.key});
  @override
  State<LossEntryPage> createState() => _LossEntryPageState();
}

class _LossEntryPageState extends State<LossEntryPage> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _reason = TextEditingController();
  final _description = TextEditingController();
  late final Future<List<Map<String, dynamic>>> _variants;
  int? _variant;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _variants = Supabase.instance.client.from('variantes_producto')
      .select('id_variante,stock_actual,estado').limit(500)
      .then((items) => items.map((e) => Map<String, dynamic>.from(e)).toList());
  }
  @override
  void dispose() {
    _quantity.dispose(); _reason.dispose(); _description.dispose();
    super.dispose();
  }
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate() || _variant == null) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) =>
      AlertDialog(
        title: const Text('Registrar pérdida'),
        content: const Text('Esta operación puede disminuir existencias reales. '
          '¿Confirmas que los datos son correctos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar')),
        ]));
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AdministrativeTransactions.instance.manageLoss('guardar', {
        'id_perdida': null, 'id_devolucion': null,
        'id_variante': _variant, 'cantidad': int.parse(_quantity.text),
        'motivo': _reason.text.trim(), 'descripcion': _description.text.trim(),
        'estado': 'ACTIVA',
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar la pérdida: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('REGISTRAR PÉRDIDA')),
    body: FutureBuilder<List<Map<String, dynamic>>>(future: _variants,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text(
          'No se pudieron consultar variantes. Comprueba los permisos.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Form(key: _form, child: ListView(
          padding: const EdgeInsets.all(20), children: [
            DropdownButtonFormField<int>(
              value: _variant, isExpanded: true,
              decoration: const InputDecoration(labelText: 'Variante'),
              items: snapshot.data!.map((v) => DropdownMenuItem<int>(
                value: (v['id_variante'] as num).toInt(),
                child: Text('Variante #${v['id_variante']} · Stock ${v['stock_actual']}'))).toList(),
              onChanged: (value) => setState(() => _variant = value),
              validator: (v) => v == null ? 'Selecciona una variante' : null),
            TextFormField(controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              validator: (value) {
                final count = int.tryParse(value ?? '');
                return count == null || count <= 0 ? 'Cantidad entera positiva' : null;
              }),
            TextFormField(controller: _reason,
              decoration: const InputDecoration(labelText: 'Motivo'),
              validator: (value) => (value ?? '').trim().isEmpty
                ? 'Indica el motivo' : null),
            TextFormField(controller: _description,
              decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Registrando...' : 'Guardar pérdida')),
          ]));
      }),
  );
}
