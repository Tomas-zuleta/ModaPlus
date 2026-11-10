import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modaplus/services/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ModaPlus always uses light mode even with a stored dark preference',
      () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final prefs = AppPreferences.instance;
    await prefs.load();
    expect(prefs.themeMode, ThemeMode.light);
    await prefs.setThemeMode(ThemeMode.dark);
    expect(prefs.themeMode, ThemeMode.light);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getString('theme_mode'), 'light');
  });
}
