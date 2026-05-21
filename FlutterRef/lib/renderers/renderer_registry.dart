import 'board_renderer_base.dart';
import 'diagonal_board_renderer.dart';
import 'jigsaw_board_renderer.dart';
import 'killer_board_renderer.dart';
import 'standard_board_renderer.dart';
import 'window_board_renderer.dart';

/// 渲染器注册表
///
/// 符合设计文档 IRendererFactory 接口，支持动态注册和获取渲染器
class RendererRegistry {
  RendererRegistry() {
    // 注册内置渲染器
    register('standard', () => const StandardBoardRenderer());
    register('diagonal', () => const DiagonalBoardRenderer());
    register('window', () => const WindowBoardRenderer());
    register('killer', () => const KillerBoardRenderer());
    register('jigsaw', () => const JigsawBoardRenderer());
  }

  final Map<String, BoardRendererBase Function()> _renderers = {};

  /// 渲染器实例缓存
  static final Map<String, BoardRendererBase> _cache = {};

  /// 注册渲染器
  void register(String gameId, BoardRendererBase Function() builder) {
    _renderers[gameId] = builder;
    _cache.remove(gameId); // 新注册时清除缓存
  }

  /// 获取渲染器（带缓存）
  BoardRendererBase? getRenderer(String gameId) {
    if (_cache.containsKey(gameId)) return _cache[gameId];
    final builder = _renderers[gameId];
    if (builder == null) return null;
    final renderer = builder();
    _cache[gameId] = renderer;
    return renderer;
  }

  /// 获取所有已注册的游戏 ID
  List<String> getRegisteredGameIds() => _renderers.keys.toList();
}
