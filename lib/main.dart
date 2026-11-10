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
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Arial', 'sans-serif'],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, height: 1.15,
          fontWeight: FontWeight.w800, color: AppColors.textDark),
        headlineSmall: TextStyle(fontSize: 24, height: 1.2,
          fontWeight: FontWeight.w800, color: AppColors.textDark),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700,
          color: AppColors.textDark),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.textDark),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45,
          color: AppColors.textDark),
        bodyMedium: TextStyle(fontSize: 15, height: 1.45,
          color: AppColors.textDark),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        ),
      ),
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
