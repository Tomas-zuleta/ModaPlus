import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_store.dart';
import '../services/supabase_auth_service.dart';
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

  Future<void> _login(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      if (const String.fromEnvironment('SUPABASE_URL').isEmpty ||
          const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').isEmpty) {
        throw const AuthException('Configura Supabase para iniciar sesión.');
      }
      final account = await SupabaseAuthService.instance.signIn(email, password);
      if (!mounted) return;
      AppStore.instance.startSession(
        name: account.name, email: account.email, role: account.role);
      Navigator.of(context).pushReplacement(
        fadeRoute(LoadingPage(name: account.name, role: account.role)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error is AuthException ? error.message :
          'No se pudo iniciar sesión. Revisa tu conexión e inténtalo de nuevo.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register(String name, String email, String password) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('El registro móvil requiere datos de identificación. '
        'Por ahora crea tu cuenta desde la web e inicia sesión aquí.')));
  }

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
      ]))))),
    ]),
  );
}
