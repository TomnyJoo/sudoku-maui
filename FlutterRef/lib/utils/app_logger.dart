import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 应用日志记录器
class AppLogger {
  AppLogger._();

  /// 日志记录器
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.info,
  );

  /// 简单日志记录器
  static final Logger _simpleLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.info,
  );

  /// 记录调试日志
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 记录信息日志
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _simpleLogger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 记录警告日志
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _simpleLogger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 记录错误日志
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 记录致命错误日志
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// 记录跟踪日志
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// 记录API请求日志
  static void logApiRequest(String method, String url, [Map<String, dynamic>? params]) {
    debug('API Request: $method $url ${params ?? ''}');
  }

  /// 记录API响应日志
  static void logApiResponse(String method, String url, int statusCode, [dynamic data]) {
    debug('API Response: $method $url - $statusCode ${data ?? ''}');
  }

  /// 记录性能日志
  static void logPerformance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms');
  }

  /// 记录用户操作日志
  static void logUserAction(String action, [Map<String, dynamic>? details]) {
    debug('User Action: $action ${details ?? ''}');
  }
}
