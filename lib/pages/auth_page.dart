import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_store.dart';
import '../models/user_role.dart';
import '../utils/app_colors.dart';
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
  void _toggleMode() { if (!_isLoading) setState(() => _isLogin = !_isLogin); }
  void _openForgot() => Navigator.of(context).push(fadeRoute(const ForgotPasswordPage(), duration: const Duration(milliseconds: 400)));

  // TODO: Reemplazar este flujo de demostración por Supabase Auth antes de producción.
  // Nunca conceder rol admin según el texto del correo electrónico.
  Future<void> _login(String email, String password) => _enter(name: _nameFromEmail(email), email: email);
  Future<void> _register(String name, String email, String password) => _enter(name: name, email: email);
  Future<void> _enter({required String name, required String email}) async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => _isLoading = false);
    AppStore.instance.startSession(name: name, email: email, role: UserRole.client);
    Navigator.of(context).pushReplacement(fadeRoute(LoadingPage(name: name, role: UserRole.client)));
  }
  String _nameFromEmail(String email) { final local = email.split('@').first.trim(); return local.isEmpty ? 'Usuario' : local[0].toUpperCase() + local.substring(1); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(children: [
      Positioned(top: -100, right: -120, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.acid.withValues(alpha: .3), width: 50)))),
      Positioned(top: 110, left: -45, child: Transform.rotate(angle: -.18, child: Container(width: 120, height: 14, color: AppColors.acid.withValues(alpha: .65)))),
      SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 28, 20, 32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const BrandTitle(), Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: AppColors.textDark, borderRadius: BorderRadius.circular(24)), child: const Text('EST. 2026', style: TextStyle(color: AppColors.acid, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))) ]),
        const SizedBox(height: 36),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.acid.withValues(alpha: .28), borderRadius: BorderRadius.circular(9)), child: const Text('NUEVA TEMPORADA  /  MODA PLUS', style: TextStyle(color: AppColors.textDark, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4))),
        const SizedBox(height: 14),
        const Text('TU ESTILO.\nTU ESENCIA.', style: TextStyle(color: AppColors.textDark, fontSize: 44, height: .98, fontWeight: FontWeight.w900, letterSpacing: -2.4)).animate().fadeIn(duration: 550.ms).slideY(begin: .2, end: 0, duration: 600.ms),
        const SizedBox(height: 12),
        const Text('Descubre lo nuevo, guarda tus favoritos y compra a tu manera.', style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted)),
        const SizedBox(height: 26),
        AnimatedSize(duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic, alignment: Alignment.topCenter, child: AnimatedSwitcher(duration: const Duration(milliseconds: 330), switchInCurve: Curves.easeOutCubic, switchOutCurve: Curves.easeInCubic, transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(.08, .04), end: Offset.zero).animate(animation), child: child)), child: _isLogin ? LoginForm(key: const ValueKey('login'), isLoading: _isLoading, onSubmit: _login, onForgot: _openForgot) : RegisterForm(key: const ValueKey('register'), isLoading: _isLoading, onSubmit: _register))),
        const SizedBox(height: 22),
        Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _isLogin ? AuthFooterLink(key: const ValueKey('footer-login'), question: '¿No tienes una cuenta?', actionText: 'Registrarme', onTap: _toggleMode) : AuthFooterLink(key: const ValueKey('footer-register'), question: '¿Ya tienes una cuenta?', actionText: 'Iniciar sesión', onTap: _toggleMode))),
        const SizedBox(height: 30),
        const Center(child: Text('MODA PLUS  •  VISTE TU HISTORIA', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.4))),
      ])))),
    ]),
  );
}
