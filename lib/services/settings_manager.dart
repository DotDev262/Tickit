import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsManagerProvider = Provider<SettingsManager>((ref) => SettingsManager());

class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;

  SettingsManager._internal();

  late SharedPreferences _prefs;

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<bool> notificationsEnabledNotifier = ValueNotifier(true);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    final themeModeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;

    themeModeNotifier.value = ThemeMode.values[themeModeIndex];
    notificationsEnabledNotifier.value = notificationsEnabled;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    themeModeNotifier.value = themeMode;
    await _prefs.setInt('themeMode', themeMode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabledNotifier.value = enabled;
    await _prefs.setBool('notificationsEnabled', enabled);
  }
}