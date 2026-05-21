/// 性能监控工具
class PerformanceMonitor {
  static final Map<String, int> _operationCount = {};
  static final Map<String, Stopwatch> _stopwatches = {};

  /// 最大监控操作数量，防止内存泄漏
  static const int _maxOperations = 50;
  
  /// 开始监控操作
  static void startOperation(final String operationName) {
    // 超过容量限制时自动清理
    if (_operationCount.length >= _maxOperations) {
      reset();
    }

    _operationCount[operationName] = (_operationCount[operationName] ?? 0) + 1;
    
    if (!_stopwatches.containsKey(operationName)) {
      _stopwatches[operationName] = Stopwatch();
    }
    _stopwatches[operationName]!.start();
  }
  
  /// 结束监控操作
  static void endOperation(final String operationName) {
    final stopwatch = _stopwatches[operationName];
    if (stopwatch != null && stopwatch.isRunning) {
      stopwatch.stop();
    }
  }
  
  /// 获取操作统计
  static Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _stopwatches.entries) {
      final operationName = entry.key;
      final stopwatch = entry.value;
      final count = _operationCount[operationName] ?? 0;
      
      stats[operationName] = {
        'count': count,
        'totalTime': stopwatch.elapsedMicroseconds,
        'averageTime': count > 0 ? stopwatch.elapsedMicroseconds / count : 0,
      };
    }
    
    return stats;
  }
  
  /// 重置监控数据
  static void reset() {
    _operationCount.clear();
    _stopwatches.clear();
  }
}
