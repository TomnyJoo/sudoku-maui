import 'dart:async';
import 'package:flutter/material.dart';

/// 性能优化工具类
class PerformanceUtils {
  /// 防抖函数 - 减少频繁调用的函数执行次数
  /// 
  /// [func] 要执行的函数
  /// [delay] 延迟时间
  /// 
  /// 返回防抖处理后的函数
  static void Function() debounce(final void Function() func, [final Duration delay = const Duration(milliseconds: 16)]) {
    Timer? timer;

    return () {
      timer?.cancel();
      timer = Timer(delay, func);
    };
  }

  /// 节流函数 - 确保函数在指定时间内只执行一次
  /// 
  /// [func] 要执行的函数
  /// [delay] 节流时间
  /// 
  /// 返回节流处理后的函数
  static void Function() throttle(final void Function() func, [final Duration delay = const Duration(milliseconds: 16)]) {
    var isThrottled = false;
    
    return () {
      if (!isThrottled) {
        func();
        isThrottled = true;
        Timer(delay, () {
          isThrottled = false;
        });
      }
    };
  }
  
  /// 批量更新优化 - 用于减少频繁的状态更新
  static final BatchUpdate batchUpdate = BatchUpdate._();
}

/// 批量更新优化 - 用于减少频繁的状态更新
class BatchUpdate {
  BatchUpdate._();
  
  static Timer? _batchTimer;
  static final List<VoidCallback> _pendingUpdates = [];
  
  /// 添加更新到批量队列
  /// 
  /// [update] 要执行的更新函数
  void addUpdate(final VoidCallback update) {
    _pendingUpdates.add(update);
    
    // 延迟执行批量更新
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 16), _executeBatch);
  }
  
  /// 执行批量更新
  static void _executeBatch() {
    if (_pendingUpdates.isNotEmpty) {
      // 执行所有待处理的更新
      for (final update in _pendingUpdates) {
        update();
      }
      _pendingUpdates.clear();
    }
  }
  
  /// 强制立即执行所有待处理的更新
  void flush() {
    _batchTimer?.cancel();
    _executeBatch();
  }
}

/// 内存优化 - 对象池模式
class ObjectPool<T> {
  
  ObjectPool({required this.create, required this.reset});
  final List<T> pool = [];
  final T Function() create;
  final void Function(T) reset;
  
  /// 获取对象
  /// 
  /// 返回从池中获取的对象，如果池为空则创建新对象
  T get() {
    if (pool.isNotEmpty) {
      return pool.removeLast();
    }
    return create();
  }
  
  /// 归还对象
  /// 
  /// [obj] 要归还的对象
  void returnObject(final T obj) {
    reset(obj);
    pool.add(obj);
  }
  
  /// 清空对象池
  void clear() {
    pool.clear();
  }
  
  /// 获取对象池大小
  int get size => pool.length;
}
