import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../utils/format.dart';
import '../services/supabase_checkout_service.dart';

/// Paso de pago: no se crea una venta hasta contar con operación atómica validada.
class CheckoutPaymentPage extends StatefulWidget {
  const CheckoutPaymentPage({super.key});
  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  PlatformFile? _receipt;
  bool _accepted = false;
  bool _sending = false;
  int? _createdOrderId;
  String? _error;
  static const int _maxBytes = 1024 * 1024;
  static const _extensions = ['png', 'jpg', 'jpeg', 'pdf'];
  static const _qr = String.fromEnvironment('MODAPLUS_PAYMENT_QR_URL');

  Future<void> _selectReceipt() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: _extensions,
        withData: true, allowMultiple: false);
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final extension = file.extension?.toLowerCase();
      if (file.size == 0 || file.size > _maxBytes ||
          !_extensions.contains(extension) || file.bytes == null) {
        setState(() { _receipt = null;
          _error = 'Selecciona PNG, JPG o PDF de máximo 1 MB.'; });
        return;
      }
      // Validación inicial del contenido, no solo de la extensión.
      final b = file.bytes!;
      final png = b.length >= 8 && b[0] == 137 && b[1] == 80 &&
        b[2] == 78 && b[3] == 71;
      final jpg = b.length >= 3 && b[0] == 255 && b[1] == 216 && b[2] == 255;
      final pdf = b.length >= 5 && b[0] == 37 && b[1] == 80 &&
        b[2] == 68 && b[3] == 70 && b[4] == 45;
      final valid = switch (extension) {
        'png' => png,
        'jpg' || 'jpeg' => jpg,
        'pdf' => pdf,
        _ => false,
      };
      if (!valid) {
        setState(() { _receipt = null;
          _error = 'El archivo no coincide con el formato indicado.'; });
        return;
      }
      setState(() { _receipt = file; _error = null; });
    } catch (_) {
      if (mounted) setState(() =>
        _error = 'No se pudo abrir el selector de archivos.');
    }
  }

  Future<void> _submit() async {
    if (_sending || _receipt == null || !_accepted) return;
    setState(() { _sending = true; _error = null; });
    try {
      final file = _receipt!;
      final ext = file.extension?.toLowerCase();
      final mime = ext == 'pdf' ? 'application/pdf'
        : ext == 'png' ? 'image/png' : 'image/jpeg';
      final id = await SupabaseCheckoutService.instance.submit(
        cart: List.of(AppStore.instance.cart),
        receipt: file.bytes!, filename: file.name, mimeType: mime);
      if (!mounted) return;
      AppStore.instance.clearCart();
      setState(() => _createdOrderId = id);
    } catch (e) {
      if (mounted) setState(() => _error =
        e is CheckoutException ? e.message :
        'No se pudo confirmar el pedido. Revisa Mis compras antes de reintentar.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = AppStore.instance;
    final verifiedVariants = cart.cart.isNotEmpty &&
      cart.cart.every((item) => item.variantId != null);
    final theme = Theme.of(context);
    final qr = Uri.tryParse(_qr);
    final qrReady = qr != null && qr.scheme == 'https' && qr.host.isNotEmpty;
    if (_createdOrderId != null) {
      return Scaffold(appBar: AppBar(title: const Text('PEDIDO RECIBIDO')),
        body: Center(child: Padding(padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_outline, size: 72),
            const SizedBox(height: 16),
            Text('Pedido #${_createdOrderId!} registrado',
              style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text('Pendiente de verificación del comprobante. '
              'La transferencia no se considera aprobada todavía.',
              textAlign: TextAlign.center),
            TextButton(onPressed: () => Navigator.of(context).pop(),
              child: const Text('VOLVER')),
          ]))));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('FINALIZAR COMPRA')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        Text('PAGO POR TRANSFERENCIA / QR',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Realiza tu transferencia, conserva el comprobante '
          'y adjúntalo para que el administrador pueda verificar el pago.'),
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL A PAGAR', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(formatCop(cart.cartTotal), style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('${cart.cartCount} prendas seleccionadas'),
          ]))),
        const SizedBox(height: 20),
        if (qrReady) ...[
          Center(child: ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.network(_qr, width: 240, height: 240, fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text('No se pudo cargar el QR')))),
          const SizedBox(height: 8),
          const Text('Escanea el QR desde tu aplicación bancaria.',
            textAlign: TextAlign.center),
        ] else
          const Card(child: Padding(padding: EdgeInsets.all(18),
            child: Text('El QR oficial de ModaPlus todavía no está configurado '
              'en la aplicación. No realices transferencias hasta confirmarlo.'))),
        if (!verifiedVariants) const Card(child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Tu carrito contiene productos de demostración. '
            'Elige variantes reales desde el catálogo conectado a Supabase.'))),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: _selectReceipt,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_receipt == null ? 'ADJUNTAR COMPROBANTE' : 'CAMBIAR COMPROBANTE')),
        const SizedBox(height: 6),
        const Text('PNG, JPG o PDF · Máximo 1 MB'),
        if (_receipt != null) ...[
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.check_circle_outline),
            title: Text(_receipt!.name),
            subtitle: Text('${(_receipt!.size / 1024).toStringAsFixed(0)} KB · '
              'Seleccionado en el dispositivo, aún no enviado')),
          if (['png', 'jpg', 'jpeg'].contains(_receipt!.extension?.toLowerCase()))
            Image.memory(_receipt!.bytes!, height: 170, fit: BoxFit.contain),
        ],
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
        const SizedBox(height: 16),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _accepted,
          title: const Text('Confirmo que el comprobante corresponde '
            'a mi transferencia y acepto los términos de compra.'),
          onChanged: (value) => setState(() => _accepted = value ?? false)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: !_sending && SupabaseCheckoutService.enabled &&
            verifiedVariants && _accepted && _receipt != null && qrReady
            ? _submit : null,
          icon: const Icon(Icons.lock_outline),
          label: Text(_sending ? 'ENVIANDO...' : 'ENVIAR PEDIDO Y COMPROBANTE'),
        ),
        const SizedBox(height: 12),
        Text(SupabaseCheckoutService.enabled
          ? 'El pedido queda pendiente hasta la revisión administrativa.'
          : 'Envío real desactivado hasta verificar RPC, RLS e inventario.',
          textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ]),
    );
  }
}
