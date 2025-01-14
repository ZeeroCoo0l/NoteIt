import 'package:flutter/material.dart';
import 'package:super_editor_note_app/themeAndData/theme.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeData _lightMode = themeDataLightMode;
  late ThemeData _darkMode = themeDataDarkMode;
  late ThemeMode _themeMode = ThemeMode.dark;
  bool isDarkMode = true;

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightMode => _lightMode;
  ThemeData get darkMode => _darkMode;

  void toggleMode() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      isDarkMode = false;
    } else {
      _themeMode = ThemeMode.dark;
      isDarkMode = true;
    }
    notifyListeners();
  }
}
