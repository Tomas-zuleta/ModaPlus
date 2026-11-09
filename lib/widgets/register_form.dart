import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/animations.dart';
import '../services/supabase_auth_service.dart';
import '../utils/validators.dart';
import 'auth_card.dart';
import 'auth_header.dart';
import 'auth_text_field.dart';
import 'primary_button.dart';

class RegisterForm extends StatefulWidget {
  final bool isLoading;
  final void Function(CustomerRegistration customer, String email, String password) onSubmit;

  const RegisterForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _documentCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _documentType = 'CC';
  bool _acceptedDraft = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _documentCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_acceptedDraft) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:
        Text('Lee y acepta los términos antes de continuar.')));
      return;
    }
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        CustomerRegistration(
          tipoDocumento: _documentType,
          identificacion: _documentCtrl.text.trim(),
          nombres: _nameCtrl.text.trim(),
          apellidos: _surnameCtrl.text.trim(),
          telefono: _phoneCtrl.text.trim(),
          direccion: _addressCtrl.text.trim(),
        ),
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeader(
              title: 'Crear Cuenta',
              subtitle: 'Regístrate para comenzar a comprar.',
            ).stagger(0),
            AuthTextField(
              label: 'Nombres',
              hint: 'Tus nombres',
              controller: _nameCtrl,
              validator: Validators.name,
            ).stagger(1),
            const SizedBox(height: 20),
            AuthTextField(label: 'Apellidos', hint: 'Tus apellidos',
              controller: _surnameCtrl, validator: Validators.name).stagger(1),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _documentType,
              decoration: const InputDecoration(labelText: 'Tipo de documento',
                border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'CC', child: Text('Cédula de ciudadanía')),
                DropdownMenuItem(value: 'CE', child: Text('Cédula de extranjería')),
                DropdownMenuItem(value: 'TI', child: Text('Tarjeta de identidad')),
                DropdownMenuItem(value: 'PASAPORTE', child: Text('Pasaporte')),
              ],
              onChanged: (v) => setState(() => _documentType = v ?? 'CC'),
            ),
            const SizedBox(height: 20),
            AuthTextField(label: 'Identificación', hint: 'Número de documento',
              controller: _documentCtrl,
              validator: (v) => (v == null || v.trim().length < 5)
                ? 'Ingresa un documento válido' : null).stagger(2),
            const SizedBox(height: 20),
            AuthTextField(label: 'Teléfono', hint: 'Número de contacto',
              controller: _phoneCtrl, keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().length < 7)
                ? 'Ingresa un teléfono válido' : null).stagger(2),
            const SizedBox(height: 20),
            AuthTextField(label: 'Dirección (opcional)', hint: 'Tu dirección',
              controller: _addressCtrl).stagger(2),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ).stagger(2),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Contraseña',
              hint: '••••••••',
              controller: _passCtrl,
              isPassword: true,
              validator: Validators.password,
            ).stagger(3),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Confirmar contraseña',
              hint: '••••••••',
              controller: _confirmCtrl,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _passCtrl.text),
            ).stagger(4),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(
                'https://github.com/MonsalveGod/ModaPlus/blob/main/docs/legal/terminos_y_condiciones.md'),
                mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 17),
              label: const Text('Leer términos y condiciones (borrador)'),
            ),
            CheckboxListTile(
              value: _acceptedDraft,
              onChanged: widget.isLoading ? null :
                (v) => setState(() => _acceptedDraft = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('He leído y acepto los términos y condiciones'),
              subtitle: const Text('Documento provisional pendiente de aprobación del negocio.'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Registrarme',
              isLoading: widget.isLoading,
              onPressed: _submit,
            ).stagger(5),
          ],
        ),
      ),
    );
  }
}