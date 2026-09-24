import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/brand_title.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _step = 0;
  String _email = '';

  Future<void> _goTo(int step) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _step = step);
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepForm(
          key: const ValueKey(0),
          title: 'Recuperar contraseña',
          subtitle: 'Te enviaremos un código para restablecerla.',
          buttonText: 'Enviar código',
          fields: [
            _Field(
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              keyboard: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ],
          onSubmit: (values) async {
            _email = values[0].trim();
            await _goTo(1);
          },
        );
      case 1:
        return _StepForm(
          key: const ValueKey(1),
          title: 'Verifica tu código',
          subtitle: 'Ingresa el código de 6 dígitos enviado a $_email.\n'
              '(Demo: sirve cualquier código de 6 dígitos)',
          buttonText: 'Verificar código',
          fields: [
            _Field(
              label: 'Código',
              hint: '123456',
              keyboard: TextInputType.number,
              validator: (v) => (v != null && RegExp(r'^\d{6}$').hasMatch(v.trim()))
                  ? null
                  : 'Ingresa los 6 dígitos',
            ),
          ],
          onSubmit: (values) => _goTo(2),
        );
      case 2:
        return _StepForm(
          key: const ValueKey(2),
          title: 'Nueva contraseña',
          subtitle: 'Crea una contraseña segura para tu cuenta.',
          buttonText: 'Restaurar contraseña',
          confirmLast: true,
          fields: [
            _Field(
              label: 'Nueva contraseña',
              hint: '••••••••',
              isPassword: true,
              validator: Validators.password,
            ),
            _Field(
              label: 'Confirmar contraseña',
              hint: '••••••••',
              isPassword: true,
              validator: Validators.password,
            ),
          ],
          onSubmit: (values) => _goTo(3),
        );
      default:
        return AuthCard(
          key: const ValueKey(3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              const AuthHeader(
                title: 'Contraseña restaurada',
                subtitle: 'Ya puedes iniciar sesión con tu nueva contraseña.',
              ),
              PrimaryButton(
                text: 'Volver a iniciar sesión',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandTitle(),
                  const SizedBox(height: 40),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _buildStep(),
                    ),
                  ),
                  if (_step < 3) ...[
                    const SizedBox(height: 28),
                    AuthFooterLink(
                      question: '¿La recordaste?',
                      actionText: 'Iniciar sesión',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field {
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboard;
  final String? Function(String?) validator;

  const _Field({
    required this.label,
    required this.hint,
    required this.validator,
    this.isPassword = false,
    this.keyboard = TextInputType.text,
  });
}

class _StepForm extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final List<_Field> fields;
  final bool confirmLast;
  final Future<void> Function(List<String> values) onSubmit;

  const _StepForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.fields,
    required this.onSubmit,
    this.confirmLast = false,
  });

  @override
  State<_StepForm> createState() => _StepFormState();
}

class _StepFormState extends State<_StepForm> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _ctrls = List.generate(
    widget.fields.length,
    (_) => TextEditingController(),
  );
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.onSubmit(_ctrls.map((c) => c.text).toList());
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.fields.length - 1;
    return AuthCard(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthHeader(title: widget.title, subtitle: widget.subtitle),
            for (int i = 0; i < widget.fields.length; i++) ...[
              AuthTextField(
                label: widget.fields[i].label,
                hint: widget.fields[i].hint,
                controller: _ctrls[i],
                isPassword: widget.fields[i].isPassword,
                keyboardType: widget.fields[i].keyboard,
                textInputAction:
                    i == last ? TextInputAction.done : TextInputAction.next,
                validator: (widget.confirmLast && i == last)
                    ? Validators.confirmPassword(() => _ctrls[i - 1].text)
                    : widget.fields[i].validator,
              ),
              if (i < last) const SizedBox(height: 20),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              text: widget.buttonText,
              isLoading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}