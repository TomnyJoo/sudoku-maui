import 'dart:isolate';

/// Isolate 消息基类
sealed class IsolateMessage {
  const IsolateMessage();
}

/// 生成请求
class GenerationRequest extends IsolateMessage {

  const GenerationRequest({
    required this.gameType,
    required this.difficulty,
    required this.size,
    this.templateData,
  });
  final String gameType;
  final String difficulty;
  final int size;
  final Map<String, dynamic>? templateData;
}

/// 生成进度
class GenerationProgress extends IsolateMessage {

  const GenerationProgress(this.stage);
  final String stage;
}

/// 生成结果
class GenerationResultMessage extends IsolateMessage {

  const GenerationResultMessage(this.result);
  final Map<String, dynamic> result;
}

/// 生成错误
class GenerationError extends IsolateMessage {

  const GenerationError(this.message);
  final String message;
}

/// Isolate 初始化完成
class IsolateReady extends IsolateMessage {

  const IsolateReady(this.sendPort);
  final SendPort sendPort;
}
