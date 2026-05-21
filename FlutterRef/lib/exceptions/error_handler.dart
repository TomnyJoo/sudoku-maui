import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/game_state.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 统一的错误处理器
class ErrorHandler {
  factory ErrorHandler() => _instance;

  ErrorHandler._internal();
  static final ErrorHandler _instance = ErrorHandler._internal();

  /// 处理异常并返回用户友好的错误消息
  String handleException(Exception e) {
    if (e is GameGenerationException) {
      return '游戏生成失败: ${e.message}';
    } else if (e is GameGenerationCancelledException) {
      return '游戏生成已取消: ${e.message}';
    } else if (e is GameGenerationTimeoutException) {
      return '游戏生成超时: ${e.message}';
    } else if (e is GameGenerationNoSolutionException) {
      return '游戏生成无解: ${e.message}';
    } else if (e is GameLogicException) {
      return '游戏逻辑错误: ${e.message}';
    } else if (e is GameValidationException) {
      return '游戏验证错误: ${e.message}';
    } else if (e is GameStorageException) {
      return '游戏存储错误: ${e.message}';
    } else if (e is GameAnalysisException) {
      return '游戏分析错误: ${e.message}';
    } else if (e is AppException) {
      return e.message;
    } else if (e is BaseException) {
      return e.message;
    } else {
      return '发生未知错误: ${e.toString()}';
    }
  }

  /// 记录错误
  void logError(Exception e, [String? context, StackTrace? stackTrace]) {
    final message = context != null ? '[$context] ${e.toString()}' : e.toString();
    AppLogger.error(message, e, stackTrace);
  }

  /// 处理游戏状态错误
  GameState handleGameStateError(GameState state, Exception e) {
    logError(e, 'GameState Error');
    // 可以根据错误类型返回不同的游戏状态
    return state;
  }

  /// 执行异步操作并自动处理错误
  Future<T> handleAsync<T>(
    Future<T> Function() operation, {
    required String operationName,
    String? errorMessage,
    T? defaultValue,
    void Function(Exception e, StackTrace stackTrace)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (onError != null) {
        onError(e is Exception ? e : Exception(e), stackTrace);
      }

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }

  /// 检查错误类型
  bool isGameLogicError(Exception e) =>
      e is GameLogicException || e is GameValidationException;

  bool isGameStorageError(Exception e) => e is GameStorageException;

  bool isGameGenerationError(Exception e) =>
      e is GameGenerationException ||
      e is GameGenerationCancelledException ||
      e is GameGenerationTimeoutException ||
      e is GameGenerationNoSolutionException;

  bool isGameAnalysisError(Exception e) => e is GameAnalysisException;

  bool isNetworkError(Exception e) => e is AppException && e.code == 'NETWORK_ERROR';

  bool isValidationError(Exception e) =>
      e is AppException && e.code == 'VALIDATION_FAILED';
}
