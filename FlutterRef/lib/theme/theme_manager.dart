import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/theme/app_theme.dart';

/// 主题管理器
///
/// 负责管理应用的主题模式和主题持久化存储
class ThemeManager extends ChangeNotifier {
  /// 初始化主题管理器
  ///
  /// [preloadedMode] 预加载的主题模式，避免首次 build 使用默认值导致闪烁
  ThemeManager({ThemeMode? preloadedMode}) {
    if (preloadedMode != null) {
      _themeMode = preloadedMode;
    }
    _loadThemePreferences();
  }

  /// 主题模式
  ThemeMode _themeMode = ThemeMode.system;

  /// 主题持久化存储键
  static const String _themeModeKey = 'theme_mode';

  /// 主题缓存，避免重复计算
  ThemeData? _lightThemeCache;
  ThemeData? _darkThemeCache;

  /// 加载保存的主题偏好
  ///
  /// 从 SharedPreferences 中加载保存的主题模式
  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载主题模式
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.byName(themeModeString);
    }

    notifyListeners();
  }

  /// 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// 设置主题模式
  ///
  /// [mode] 要设置的主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    notifyListeners();

    // 保存主题模式到持久化存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// 根据当前主题模式获取主题数据
  ///
  /// [context] 构建上下文
  ///
  /// 返回当前环境下的主题数据
  ThemeData getTheme(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system && brightness == Brightness.dark);

    if (isDarkMode) {
      _darkThemeCache ??= AppTheme.darkTheme;
      return _darkThemeCache!;
    } else {
      _lightThemeCache ??= AppTheme.lightTheme;
      return _lightThemeCache!;
    }
  }

  /// 切换主题模式
  ///
  /// 按顺序切换：light → dark → system → light
  Future<void> toggleThemeMode() async {
    ThemeMode newMode;
    switch (_themeMode) {
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
    }
    await setThemeMode(newMode);
  }

  /// 清理缓存，释放内存
  void clearCache() {
    _lightThemeCache = null;
    _darkThemeCache = null;
  }
}
