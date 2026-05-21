import 'package:flutter/material.dart';
import 'package:sudoku/services/app_settings.dart';

/// 设置页 ViewModel
///
/// 封装设置相关的业务逻辑，将 UI 与 AppSettings 解耦
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required this.settings});

  final AppSettings settings;

  // ========== 音频相关 ==========

  bool get musicEnabled => settings.musicEnabled;

  void setMusicEnabled(bool value) {
    settings.toggleMusic(value);
    notifyListeners();
  }

  bool get soundEffectsEnabled => settings.soundEffectsEnabled;

  void setSoundEffectsEnabled(bool value) {
    settings.toggleSoundEffects(value);
    notifyListeners();
  }

  // ========== 语言 ==========

  String get language => settings.language;

  void setLanguage(String languageCode) {
    settings.setLanguage(languageCode);
    notifyListeners();
  }

  // ========== 游戏设置 ==========

  bool get autoCheckEnabled => settings.autoCheckEnabled;

  void setAutoCheckEnabled(bool value) {
    settings.toggleAutoCheck(value);
    notifyListeners();
  }

  bool get highlightMistakesEnabled => settings.highlightMistakesEnabled;

  void setHighlightMistakes(bool value) {
    settings.toggleHighlightMistakes(value);
    notifyListeners();
  }

  bool get useAdvancedStrategy => settings.useAdvancedStrategy;

  void setUseAdvancedStrategy(bool value) {
    settings.toggleUseAdvancedStrategy(value);
    notifyListeners();
  }
}
