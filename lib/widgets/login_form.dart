import 'package:flutter/material.dart';

import '../utils/animations.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';
import 'auth_card.dart';
import 'auth_header.dart';
import 'auth_text_field.dart';
import 'primary_button.dart';

class LoginForm extends StatefulWidget {
  final bool isLoading;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onForgot;

  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgot,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_emailCtrl.text.trim(), _passCtrl.text);
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
              title: 'Iniciar Sesión',
              subtitle: 'Accede a tu cuenta para continuar.',
            ).stagger(0),
            AuthTextField(
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ).stagger(1),
            const SizedBox(height: 20),
            AuthTextField(
              label: 'Contraseña',
              hint: '••••••••',
              controller: _passCtrl,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
            ).stagger(2),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onForgot,
                child: const Text(
                  '¿Olvidé mi contraseña?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ).stagger(3),
            const SizedBox(height: 22),
            PrimaryButton(
              text: 'Ingresar',
              isLoading: widget.isLoading,
              onPressed: _submit,
            ).stagger(4),
          ],
        ),
      ),
    );
  }
}