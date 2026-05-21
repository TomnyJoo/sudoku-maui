import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sudoku/index.dart';

/// summary: 依赖注入模块
class DiModule {
  /// 核心服务
  static List<SingleChildWidget> coreProviders = [
    Provider<GameValidator>(create: (_) => GameValidator()),
    Provider<TemplateManager>(create: (_) => TemplateManager()),
    Provider<GameGenerator>(create: (_) => GameGenerator()),
    Provider<ErrorHandler>(create: (_) => ErrorHandler()),
  ];
  
  /// 设置和主题服务
  static List<SingleChildWidget> settingsProviders = [
    ChangeNotifierProvider(create: (_) => AppSettings()..loadSettings()),
    ChangeNotifierProvider(create: (_) => ThemeManager()),
  ];
  
  /// 所有依赖提供者
  static final List<SingleChildWidget> providers = List.unmodifiable([
    ...coreProviders,
    ...settingsProviders,
  ]);
}
