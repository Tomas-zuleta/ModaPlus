import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias locales de la aplicación, independientes de la sesión.
class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final instance = AppPreferences._();

  bool _animations = true;
  bool _confirmRemove = true;
  bool _notifications = true;

  ThemeMode get themeMode => ThemeMode.light;
  bool get animations => _animations;
  bool get confirmRemove => _confirmRemove;
  bool get notifications => _notifications;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _animations = prefs.getBool('animations') ?? true;
    _confirmRemove = prefs.getBool('confirm_remove') ?? true;
    _notifications = prefs.getBool('notifications') ?? true;
    notifyListeners();
  }

  /// Conserva compatibilidad con versiones anteriores: no permite modo oscuro.
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', ThemeMode.light.name);
    notifyListeners();
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
