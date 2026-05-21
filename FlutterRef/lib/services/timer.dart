import 'dart:async';
import 'dart:ui';
import 'package:sudoku/index.dart';

/// 通用游戏计时器，提供统一的计时功能，支持秒级计时和状态管理
class GameTimer {
  /// 游戏是否已完成

  /// 构造函数
  GameTimer({
    required final VoidCallback onTick,
    required final VoidCallback onComplete,
  }) : _onTick = onTick,
       _onComplete = onComplete;

  Timer? _timer; // 计时器实例
  int _elapsedTime = 0; // 已消耗时间（秒）
  bool _isRunning = false; // 计时器是否正在运行
  bool _isCompleted = false; // 游戏是否已完成
  final VoidCallback _onTick; // 每秒回调
  final VoidCallback _onComplete; // 游戏完成回调

  int get elapsedTime => _elapsedTime;

  /// 获取已消耗时间（秒）
  bool get isRunning => _isRunning;

  /// 计时器是否正在运行
  bool get isPaused => !_isRunning && _elapsedTime > 0;

  /// 计时器是否已暂停
  bool get isCompleted => _isCompleted;

  /// 启动计时器
  void start() {
    if (_isRunning || _isCompleted) return;

    _isRunning = true;
    _timer = Timer.periodic(AppConstants.timerTickInterval, (final timer) {
      _elapsedTime++;
      _onTick();
    });
  }

  /// 暂停计时器
  void pause() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// 恢复计时器
  void resume() => start();

  /// 停止计时器
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// 重置计时器
  void reset() {
    stop();
    _elapsedTime = 0;
    _isCompleted = false;
  }

  /// 设置初始时间（用于加载保存的游戏）
  void setElapsedTime(final int seconds) {
    stop();
    _elapsedTime = seconds;
    _isCompleted = false;
  }

  /// 完成游戏
  void complete() {
    stop();
    _isCompleted = true;
    _onComplete();
  }

  /// 销毁计时器
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
