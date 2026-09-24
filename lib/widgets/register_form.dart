import 'package:flutter/material.dart';

import '../utils/animations.dart';
import '../utils/validators.dart';
import 'auth_card.dart';
import 'auth_header.dart';
import 'auth_text_field.dart';
import 'primary_button.dart';

class RegisterForm extends StatefulWidget {
  final bool isLoading;
  final void Function(String name, String email, String password) onSubmit;

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
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameCtrl.text.trim(),
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
              label: 'Nombre completo',
              hint: 'Tu nombre',
              controller: _nameCtrl,
              validator: Validators.name,
            ).stagger(1),
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
            const SizedBox(height: 28),
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