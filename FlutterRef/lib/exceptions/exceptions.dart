/// 基础异常类
/// 所有应用异常的基类，提供统一的错误信息结构
abstract class BaseException implements Exception {

  BaseException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (code != null) {
      return '$runtimeType[$code]: $message';
    }
    return '$runtimeType: $message';
  }
}

/// 通用应用异常
/// 处理应用级别的错误（网络、存储、验证等）
class AppException extends BaseException {
  AppException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AppException.audioError(String message, [dynamic error]) =>
      AppException(
        '音频错误: $message',
        code: 'AUDIO_ERROR',
        originalError: error,
      );

  factory AppException.networkError(String message, [dynamic error]) =>
      AppException(
        '网络错误: $message',
        code: 'NETWORK_ERROR',
        originalError: error,
      );

  factory AppException.validationFailed(String message) =>
      AppException(
        '验证失败: $message',
        code: 'VALIDATION_FAILED',
      );

  factory AppException.deleteFailed(String operation, [dynamic error]) =>
      AppException(
        '删除失败: $operation',
        code: 'DELETE_FAILED',
        originalError: error,
      );

  factory AppException.loadFailed(String operation, [dynamic error]) =>
      AppException(
        '加载失败: $operation',
        code: 'LOAD_FAILED',
        originalError: error,
      );

  factory AppException.saveFailed(String operation, [dynamic error]) =>
      AppException(
        '保存失败: $operation',
        code: 'SAVE_FAILED',
        originalError: error,
      );
}

/// 游戏异常基类
/// 所有游戏相关异常的基类
class GameException extends AppException {
  GameException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// 游戏生成异常
class GameGenerationException extends GameException {
  GameGenerationException(super.message, [dynamic cause])
      : super(originalError: cause);
}

/// 游戏生成取消异常
class GameGenerationCancelledException extends GameException {
  GameGenerationCancelledException([super.message = '游戏生成已取消'])
      : super(code: 'GENERATION_CANCELLED');
}

/// 游戏生成超时异常
class GameGenerationTimeoutException extends GameException {
  GameGenerationTimeoutException([super.message = '游戏生成超时'])
      : super(code: 'GENERATION_TIMEOUT');
}

/// 游戏生成无解异常
class GameGenerationNoSolutionException extends GameException {
  GameGenerationNoSolutionException([super.message = '无法生成有效的游戏'])
      : super(code: 'GENERATION_NO_SOLUTION');
}

/// 游戏逻辑异常
class GameLogicException extends GameException {
  GameLogicException(super.message, [dynamic cause])
      : super(originalError: cause);
}

/// 游戏验证异常
class GameValidationException extends GameException {
  GameValidationException(super.message, [dynamic cause])
      : super(originalError: cause);
}

/// 游戏存储异常
class GameStorageException extends GameException {
  GameStorageException(super.message, [dynamic cause])
      : super(originalError: cause);
}

/// 游戏分析异常
class GameAnalysisException extends GameException {
  GameAnalysisException(super.message, [dynamic cause])
      : super(originalError: cause);
}
