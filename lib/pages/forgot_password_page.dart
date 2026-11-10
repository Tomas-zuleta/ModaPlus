import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';

/// Solicita un correo real de recuperación; no acepta códigos ficticios.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _controller.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseAuthService.instance.resetPassword(email);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is AuthException ? error.message : 'No se pudo enviar el correo.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('RECUPERAR CONTRASEÑA')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(25), children: [
        const Icon(Icons.mark_email_read_outlined, size: 65),
        const SizedBox(height: 22),
        Text(_sent ? 'REVISA TU CORREO' : 'RECUPERA TU ACCESO',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(_sent
          ? 'Si existe una cuenta asociada, recibirás instrucciones de recuperación. '
            'El cambio de contraseña se completa mediante el enlace configurado en Supabase.'
          : 'Te enviaremos un enlace de recuperación a tu correo.',
          textAlign: TextAlign.center),
        if (!_sent) ...[
          const SizedBox(height: 22),
          TextField(controller: _controller, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo electrónico',
              border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loading ? null : _send,
            child: Text(_loading ? 'ENVIANDO...' : 'ENVIAR ENLACE')),
        ],
      ]))),
  );
}
