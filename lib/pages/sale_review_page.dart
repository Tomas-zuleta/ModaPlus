import 'package:flutter/material.dart';
import '../services/supabase_data_service.dart';

/// Consulta de venta y comprobante. No aprueba ni descuenta inventario:
/// esas operaciones requieren una función SQL autorizada y transaccional.
class SaleReviewPage extends StatefulWidget {
  final int saleId;
  final bool isAdmin;
  const SaleReviewPage({super.key, required this.saleId, required this.isAdmin});
  @override
  State<SaleReviewPage> createState() => _SaleReviewPageState();
}

class _SaleReviewPageState extends State<SaleReviewPage> {
  late Future<Map<String, dynamic>> _sale;
  String? _signedUrl;
  bool _loadingReceipt = false;
  String? _receiptError;
  @override
  void initState() { super.initState(); _refresh(); }
  void _refresh() => _sale = SupabaseDataService.instance.saleDetail(widget.saleId);

  Future<void> _viewReceipt(String path) async {
    if (_loadingReceipt) return;
    setState(() { _loadingReceipt = true; _receiptError = null; _signedUrl = null; });
    try {
      final url = await SupabaseDataService.instance.receiptSignedUrl(path);
      if (mounted) setState(() => _signedUrl = url);
    } catch (_) {
      if (mounted) setState(() => _receiptError =
        'No tienes acceso al comprobante o no se pudo generar un enlace privado.');
    } finally {
      if (mounted) setState(() => _loadingReceipt = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('PEDIDO #${widget.saleId}')),
    body: FutureBuilder<Map<String, dynamic>>(future: _sale,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('No se pudo consultar esta venta.'),
            TextButton(onPressed: () => setState(_refresh),
              child: const Text('Reintentar')),
          ]));
        }
        final sale = snapshot.data!;
        final path = sale['comprobante_url']?.toString() ?? '';
        final name = sale['comprobante_nombre']?.toString() ?? '';
        final image = name.toLowerCase().endsWith('.png') ||
          name.toLowerCase().endsWith('.jpg') ||
          name.toLowerCase().endsWith('.jpeg');
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text('Estado: ${sale['estado'] ?? 'Sin estado'}',
            style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Card(child: Column(children: [
            ListTile(title: const Text('Total registrado'),
              trailing: Text('${sale['total_venta'] ?? 0} COP')),
            ListTile(title: const Text('Fecha'),
              trailing: Text('${sale['fecha_venta'] ?? '-'}')),
            ListTile(title: const Text('Medio de pago'),
              subtitle: Text('${sale['metodo_pago'] ?? '-'}')),
            if (sale['motivo_rechazo'] != null)
              ListTile(title: const Text('Motivo de rechazo'),
                subtitle: Text('${sale['motivo_rechazo']}')),
          ])),
          const SizedBox(height: 16),
          Text('Comprobante', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (path.isEmpty) const Text('No hay comprobante asociado a esta venta.'),
          if (path.isNotEmpty) ...[
            Text(name.isEmpty ? 'Archivo adjunto' : name),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _loadingReceipt ? null
              : () => _viewReceipt(path),
              icon: const Icon(Icons.lock_outline),
              label: Text(_loadingReceipt ? 'Consultando...' : 'Consultar comprobante privado')),
            if (_receiptError != null)
              Text(_receiptError!, style: TextStyle(
                color: Theme.of(context).colorScheme.error)),
            if (_signedUrl != null && image)
              Image.network(_signedUrl!, height: 340, fit: BoxFit.contain,
                errorBuilder: (_, error, stack) =>
                  const Text('No se pudo mostrar la imagen del comprobante.')),
            if (_signedUrl != null && !image)
              const Text('El archivo no es una imagen. La vista previa de PDF '
                'requiere un visor seguro adicional.'),
          ],
          if (widget.isAdmin) ...[
            const SizedBox(height: 20),
            const Card(child: Padding(padding: EdgeInsets.all(16),
              child: Text('Revisión administrativa: solo consulta. '
                'Aprobar o rechazar requiere un RPC protegido que valide permisos, '
                'estado e inventario en una sola transacción.'))),
          ],
        ]);
      }),
  );
}
