import 'package:flutter/material.dart';
import 'pages/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/app_preferences.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.instance.load();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(const ModaPlusApp());
}

class ModaPlusApp extends StatelessWidget {
  const ModaPlusApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: dark ? const Color(0xFF0F172A) : AppColors.background,
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['Times New Roman', 'serif'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: dark ? const Color(0xFF6EE7A8) : AppColors.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        selectedColor: dark ? const Color(0xFF225A49) : const Color(0xFFD1FAE5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        labelStyle: TextStyle(color: dark ? Colors.white : const Color(0xFF0F172A)),
      ),
      cardColor: dark ? const Color(0xFF1E293B) : Colors.white,
      dividerColor: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: dark ? Colors.white : AppColors.textDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppPreferences.instance,
      builder: (context, _) => MaterialApp(
        title: 'Moda Plus',
        debugShowCheckedModeBanner: false,
        themeMode: AppPreferences.instance.themeMode,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        builder: (context, child) {
          final reduceMotion = !AppPreferences.instance.animations;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthPage(),
      ),
    );
  }
}
