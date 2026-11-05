import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's appearance choice (System / Light / Dark) across app
/// restarts via SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({SharedPreferences? preferences}) : _prefs = preferences;

  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  static const String _storageKey = 'paisapath_theme_mode';

  ThemeMode get themeMode => _themeMode;

  /// Loads the saved choice. Must be awaited before `runApp`.
  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final String? saved = _prefs?.getString(_storageKey);
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (e) {
      // Preferences failing must never crash the app; system mode stays.
      debugPrint('ThemeProvider.load failed: $e');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _prefs?.setString(_storageKey, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      });
    } catch (e) {
      debugPrint('ThemeProvider.setMode persistence failed: $e');
    }
  }
}
