import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/user_role.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/brand_title.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';
import 'forgot_password_page.dart';
import 'loading_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;

  void _toggleMode() {
    if (_isLoading) return;
    setState(() => _isLogin = !_isLogin);
  }

  void _openForgot() {
    Navigator.of(context).push(
      fadeRoute(const ForgotPasswordPage(),
          duration: const Duration(milliseconds: 400)),
    );
  }

  /// Acepta cualquier correo y contraseña.
  /// Si el correo empieza por "admin" entra como administrador.
  Future<void> _login(String email, String password) {
    return _enter(
      name: _nameFromEmail(email),
      email: email,
      role: roleFromEmail(email),
    );
  }

  /// Quien se registra siempre entra como cliente.
  Future<void> _register(String name, String email, String password) {
    return _enter(name: name, email: email, role: UserRole.client);
  }

  Future<void> _enter({
    required String name,
    required String email,
    required UserRole role,
  }) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    AppStore.instance.startSession(name: name, email: email, role: role);

    Navigator.of(context).pushReplacement(
      fadeRoute(LoadingPage(name: name, role: role)),
    );
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Usuario';
    return local[0].toUpperCase() + local.substring(1);
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
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: _transition,
                      child: _isLogin
                          ? LoginForm(
                              key: const ValueKey('login'),
                              isLoading: _isLoading,
                              onSubmit: _login,
                              onForgot: _openForgot,
                            )
                          : RegisterForm(
                              key: const ValueKey('register'),
                              isLoading: _isLoading,
                              onSubmit: _register,
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLogin
                        ? AuthFooterLink(
                            key: const ValueKey('footer-login'),
                            question: '¿No tienes una cuenta?',
                            actionText: 'Registrarme',
                            onTap: _toggleMode,
                          )
                        : AuthFooterLink(
                            key: const ValueKey('footer-register'),
                            question: '¿Ya tienes una cuenta?',
                            actionText: 'Iniciar sesión',
                            onTap: _toggleMode,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _transition(Widget child, Animation<double> animation) {
    final isRegister = child.key == const ValueKey('register');
    final offset = Tween<Offset>(
      begin: Offset(isRegister ? 0.2 : -0.2, 0),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}