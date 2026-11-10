import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ModaPlus utiliza una apariencia clara permanente en todas las pantallas.
  ThemeData _theme() {
    const background = Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: background,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dialogTheme: const DialogThemeData(backgroundColor: background),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: background),
      fontFamily: 'Georgia',
      fontFamilyFallback: const ['Times New Roman', 'serif'],
      colorScheme: scheme,
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFF1F5F9),
        selectedColor: Color(0xFFD1FAE5),
        shape: StadiumBorder(),
        labelStyle: TextStyle(color: AppColors.textDark),
      ),
      cardColor: background,
      dividerColor: AppColors.cardBorder,
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: AppColors.textDark,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
        themeMode: ThemeMode.light,
        theme: _theme(),
        builder: (context, child) {
          final reduceMotion = !AppPreferences.instance.animations;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.white,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const AuthPage(),
      ),
    );
  }
}
