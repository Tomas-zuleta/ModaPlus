import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales de la aplicación, independientes de la sesión.
class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final instance = AppPreferences._();

  ThemeMode _themeMode = ThemeMode.light;
  bool _animations = true;
  bool _confirmRemove = true;
  bool _notifications = true;

  ThemeMode get themeMode => _themeMode;
  bool get animations => _animations;
  bool get confirmRemove => _confirmRemove;
  bool get notifications => _notifications;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = switch (prefs.getString('theme_mode')) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
    _animations = prefs.getBool('animations') ?? true;
    _confirmRemove = prefs.getBool('confirm_remove') ?? true;
    _notifications = prefs.getBool('notifications') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> setAnimations(bool value) async {
    _animations = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations', value);
  }

  Future<void> setConfirmRemove(bool value) async {
    _confirmRemove = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('confirm_remove', value);
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
  }
}
