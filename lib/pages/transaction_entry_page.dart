import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/administrative_transactions.dart';

/// Consola de transacciones para administradores avanzados.
/// Los JSON deben seguir los contratos de los RPC de la web; se muestran
/// ejemplos de estructura, no valores de clientes ni importes inventados.
class TransactionEntryPage extends StatefulWidget {
  final String module;
  const TransactionEntryPage({super.key, required this.module});
  @override
  State<TransactionEntryPage> createState() => _TransactionEntryPageState();
}

class _TransactionEntryPageState extends State<TransactionEntryPage> {
  late final TextEditingController _header;
  late final TextEditingController _lines;
  bool _busy = false;
  bool _confirmed = false;
  String get _rpc => switch (widget.module) {
    'compras' => 'guardar_compra',
    'ventas' => 'guardar_venta',
    'separe' => 'guardar_plan_separe',
    'devoluciones' => 'guardar_devolucion',
    _ => 'desconocido',
  };
  @override
  void initState() {
    super.initState();
    _header = TextEditingController(text: const JsonEncoder.withIndent('  ')
      .convert(switch (widget.module) {
        'compras' => <String, dynamic>{
          'id_compra': 0, 'id_proveedor': null, 'fecha_compra': null,
          'fecha_registro': null, 'factura': null, 'tipo_pago': null,
          'estado': 'ACTIVA',
        },
        'ventas' => <String, dynamic>{
          'id_venta': 0, 'id_cliente': null, 'fecha_venta': null,
          'metodo_pago': null, 'subtotal': null, 'descuento': 0,
          'total_venta': null, 'saldo_aplicado': 0, 'estado': null,
          'origen': 'ADMIN', 'comprobante_url': null,
          'comprobante_nombre': null,
        },
        'separe' => <String, dynamic>{
          'id_plan_separe': 0, 'id_cliente': null,
          'comprobante_inicial': null, 'comprobante_inicial_nombre': null,
        },
        _ => <String, dynamic>{
          'id_devolucion': 0, 'id_venta': null, 'fecha_devolucion': null,
          'motivo': null, 'descripcion': null, 'tipo_respuesta': null,
          'estado': null, 'fecha_estado': null, 'cambio': null,
        },
      }));
    _lines = TextEditingController(text: '[\n  {}\n]');
  }
  @override
  void dispose() {
    _header.dispose();
    _lines.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_confirmed) return;
    Map<String, dynamic> header;
    List<Map<String, dynamic>> details;
    try {
      final parsedHeader = jsonDecode(_header.text);
      final parsedLines = jsonDecode(_lines.text);
      if (parsedHeader is! Map<String, dynamic> || parsedLines is! List ||
          parsedLines.isEmpty || parsedLines.any((e) => e is! Map<String, dynamic>)) {
        throw const FormatException('Se requiere un objeto y una lista de detalles.');
      }
      header = parsedHeader;
      details = parsedLines.cast<Map<String, dynamic>>();
      if (header.values.any((value) => value == null) ||
          details.any((line) => line.isEmpty || line.values.any((v) => v == null))) {
        throw const FormatException('Completa los campos obligatorios y los detalles.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Revisa el formato de la transacción: $e')));
      return;
    }
    setState(() => _busy = true);
    try {
      final service = AdministrativeTransactions.instance;
      final id = switch (widget.module) {
        'compras' => await service.savePurchase(header, details),
        'ventas' => await service.saveSale(header, details),
        'separe' => await service.saveLayaway(header, details),
        'devoluciones' => await service.saveReturn(header, details),
        _ => throw StateError('Módulo no autorizado'),
      };
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transacción confirmada por el servidor: #$id')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El servidor rechazó la operación: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Registrar ${widget.module}')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Card(child: Padding(padding: EdgeInsets.all(14),
        child: Text('Herramienta avanzada. Solo para administradores que '
          'conozcan el contrato del servidor. Los ejemplos son plantillas '
          'incompletas: nunca guardes datos ficticios. '
          'La operación puede cambiar inventario, saldos o estados reales.'))),
      const SizedBox(height: 12),
      SelectableText('Procedimiento de Supabase: $_rpc'),
      const SizedBox(height: 12),
      TextField(controller: _header, maxLines: 14,
        decoration: const InputDecoration(labelText: 'Datos de cabecera (JSON)',
          border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextField(controller: _lines, maxLines: 10,
        decoration: const InputDecoration(labelText: 'Detalles (lista JSON)',
          border: OutlineInputBorder())),
      const SizedBox(height: 14),
      CheckboxListTile(value: _confirmed,
        onChanged: _busy ? null : (value) =>
          setState(() => _confirmed = value ?? false),
        title: const Text('He verificado los datos, importes y existencias'),
        subtitle: const Text('La transacción se ejecutará en el servidor conectado.')),
      const SizedBox(height: 10),
      FilledButton.icon(
        onPressed: _busy || !_confirmed ? null : _save,
        icon: const Icon(Icons.save_outlined),
        label: Text(_busy ? 'Procesando...' : 'Ejecutar transacción'),
      ),
    ]),
  );
}
