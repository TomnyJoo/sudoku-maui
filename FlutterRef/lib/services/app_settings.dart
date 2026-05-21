import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置
class AppSettings extends ChangeNotifier {
  // ========== 变量 ==========
  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  String _language = 'zh';
  bool _autoCheckEnabled = true;
  bool _highlightMistakesEnabled = true;
  bool _useAdvancedStrategy = true;

  // ========== 常量 ==========
  static const String _musicKey = 'app_music';
  static const String _soundEffectsKey = 'app_sound_effects';
  static const String _languageKey = 'app_language';
  static const String _autoCheckKey = 'game_auto_check';
  static const String _highlightMistakesKey = 'game_highlight_mistakes';
  static const String _useAdvancedStrategyKey = 'game_use_advanced_strategy';
  
  // ========== 获取器 ==========
  bool get musicEnabled => _musicEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  String get language => _language;
  bool get autoCheckEnabled => _autoCheckEnabled;
  bool get highlightMistakesEnabled => _highlightMistakesEnabled;
  bool get useAdvancedStrategy => _useAdvancedStrategy;

  // ========== 方法 ==========
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _musicEnabled = prefs.getBool(_musicKey) ?? true;
    _soundEffectsEnabled = prefs.getBool(_soundEffectsKey) ?? true;
    _language = prefs.getString(_languageKey) ?? 'zh';

    _autoCheckEnabled = _loadBoolWithMigration(
      prefs, 
      _autoCheckKey, 
      ['standard_auto_check', 'diagonal_auto_check', 'killer_auto_check', 'jigsaw_auto_check', 'window_auto_check'], 
      true
    );
    _highlightMistakesEnabled = _loadBoolWithMigration(
      prefs, 
      _highlightMistakesKey, 
      ['standard_highlight_mistakes', 'diagonal_highlight_mistakes', 'killer_highlight_mistakes', 'jigsaw_highlight_mistakes', 'window_highlight_mistakes'], 
      true
    );
    _useAdvancedStrategy = prefs.getBool(_useAdvancedStrategyKey) ?? true;

    notifyListeners();
  }

  bool _loadBoolWithMigration(SharedPreferences prefs, String newKey, List<String> oldKeys, bool defaultValue) {
    if (prefs.containsKey(newKey)) {
      return prefs.getBool(newKey) ?? defaultValue;
    }
    
    for (final oldKey in oldKeys) {
      if (prefs.containsKey(oldKey)) {
        final value = prefs.getBool(oldKey) ?? defaultValue;
        prefs.setBool(newKey, value);
        return value;
      }
    }
    
    return defaultValue;
  }

  Future<void> toggleMusic(bool value) async {
    _musicEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicKey, value);
    notifyListeners();
  }

  Future<void> toggleSoundEffects(bool value) async {
    _soundEffectsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, value);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  Future<void> toggleAutoCheck(bool value) async {
    _autoCheckEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckKey, value);
    notifyListeners();
  }

  Future<void> toggleHighlightMistakes(bool value) async {
    _highlightMistakesEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highlightMistakesKey, value);
    notifyListeners();
  }

  Future<void> toggleUseAdvancedStrategy(bool value) async {
    _useAdvancedStrategy = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useAdvancedStrategyKey, value);
    notifyListeners();
  }




}
