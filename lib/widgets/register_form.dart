import 'package:flutter/material.dart';

import '../utils/validators.dart';
import 'auth_card.dart';
import 'auth_header.dart';
import 'auth_text_field.dart';
import 'password_strength_indicator.dart';
import 'primary_button.dart';

class RegisterForm extends StatefulWidget {
  final bool isLoading;
  final void Function({
    required String nombres,
    required String apellidos,
    required String identificacion,
    required String telefono,
    required String email,
    required String password,
  }) onSubmit;

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
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _docCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        nombres: _nombresCtrl.text.trim(),
        apellidos: _apellidosCtrl.text.trim(),
        identificacion: _docCtrl.text.trim(),
        telefono: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }
  }

  String? _required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

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
            ),
            AuthTextField(
              label: 'Nombres',
              hint: 'Tus nombres',
              controller: _nombresCtrl,
              validator: (v) => _required(v, 'Ingresa tus nombres'),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Apellidos',
              hint: 'Tus apellidos',
              controller: _apellidosCtrl,
              validator: (v) => _required(v, 'Ingresa tus apellidos'),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Documento de identidad',
              hint: '1234567890',
              controller: _docCtrl,
              keyboardType: TextInputType.number,
              validator: (v) => _required(v, 'Ingresa tu documento'),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Teléfono',
              hint: '3001234567',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) => _required(v, 'Ingresa tu teléfono'),
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Contraseña',
              hint: '••••••••',
              controller: _passCtrl,
              isPassword: true,
              validator: Validators.password,
              onChanged: (_) => setState(() {}),
            ),
            PasswordStrengthIndicator(password: _passCtrl.text),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Confirmar contraseña',
              hint: '••••••••',
              controller: _confirmCtrl,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _passCtrl.text),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              text: 'Registrarme',
              isLoading: widget.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}