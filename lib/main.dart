import 'package:flutter/material.dart';

import 'pages/auth_page.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const ModaPlusApp());
}

class ModaPlusApp extends StatelessWidget {
  const ModaPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moda Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Georgia',
        fontFamilyFallback: const ['Times New Roman', 'serif'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
      ),
      home: const AuthPage(),
    );
  }
}   