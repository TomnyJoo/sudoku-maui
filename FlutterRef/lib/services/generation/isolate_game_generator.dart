import 'dart:async';
import 'dart:isolate';
import 'package:sudoku/exceptions/exceptions.dart';
import 'package:sudoku/models/difficulty.dart';
import 'package:sudoku/models/game_type.dart';
import 'package:sudoku/models/generation_contracts.dart';
import 'package:sudoku/services/generation/game_generator.dart';
import 'package:sudoku/services/generation/message_protocol.dart';

/// Isolate 游戏生成器
///
/// 在独立 Isolate 中执行游戏生成，避免阻塞主线程
class IsolateGameGenerator {
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  Completer<GenerationResult>? _completer;
  Function(GenerationStage)? _onStageUpdate;
  Completer<void>? _readyCompleter;

  /// 生成游戏
  Future<GenerationResult> generate({
    required GameType gameType,
    required Difficulty difficulty,
    required int size,
    Function(GenerationStage)? onStageUpdate,
    Map<String, dynamic>? templateData,
  }) async {
    _onStageUpdate = onStageUpdate;
    _completer = Completer<GenerationResult>();
    _readyCompleter = Completer<void>();

    // 创建主线程的 ReceivePort
    _mainReceivePort = ReceivePort();

    // 启动 Isolate，传入主线程的 SendPort
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _mainReceivePort!.sendPort,
    );

    // 监听来自 Isolate 的消息（统一处理所有消息）
    _mainReceivePort!.listen(_handleMessage);

    // 等待 Isolate 准备就绪
    await _readyCompleter!.future;

    // 发送生成请求
    _isolateSendPort?.send(GenerationRequest(
      gameType: gameType.name,
      difficulty: difficulty.name,
      size: size,
      templateData: templateData,
    ));

    return _completer!.future;
  }

  /// 处理来自 Isolate 的消息
  void _handleMessage(dynamic message) {
    switch (message) {
      case IsolateReady():
        _isolateSendPort = message.sendPort;
        _readyCompleter?.complete();
        _readyCompleter = null;
      case GenerationProgress():
        final stage = GenerationStage.values.byName(message.stage);
        _onStageUpdate?.call(stage);
      case GenerationResultMessage():
        _completer?.complete(GenerationResult.fromJson(message.result));
        _cleanup();
      case GenerationError():
        _completer?.completeError(GameGenerationException(message.message));
        _cleanup();
    }
  }

  /// 取消游戏生成
  void cancel() {
    _isolate?.kill(priority: Isolate.immediate);
    _completer?.completeError(GameGenerationCancelledException());
    _cleanup();
  }

  /// 清理资源
  void _cleanup() {
    _mainReceivePort?.close();
    _isolate = null;
    _isolateSendPort = null;
    _mainReceivePort = null;
    _completer = null;
    _readyCompleter = null;
  }

  // ==================== Isolate 入口点和执行逻辑 ====================

  /// Isolate 入口函数（静态方法，在 Isolate 中执行）
  static void _isolateEntryPoint(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();

    // 向主线程发送 Isolate 的 SendPort
    mainSendPort.send(IsolateReady(isolateReceivePort.sendPort));

    final generator = GameGenerator();

    isolateReceivePort.listen((message) {
      if (message is GenerationRequest) {
        _executeGeneration(message, mainSendPort, generator);
      }
    });
  }

  /// 在 Isolate 中执行游戏生成
  static Future<void> _executeGeneration(
    GenerationRequest request,
    SendPort mainSendPort,
    GameGenerator generator,
  ) async {
    try {
      // 解析枚举类型
      final gameType = GameType.values.byName(request.gameType);
      final difficulty = Difficulty.values.byName(request.difficulty);

      // 发送生成请求
      final result = await generator.generate(
        gameType: gameType,
        difficulty: difficulty,
        size: request.size,
        isCancelled: () => false, // Isolate 内部不需要取消检查
        onStageUpdate: (stage) {
          mainSendPort.send(GenerationProgress(stage.name));
        },
        templateData: request.templateData,
      );

      // 发送生成结果
      mainSendPort.send(GenerationResultMessage(result.toJson()));
    } catch (e) {
      // 发送错误信息
      mainSendPort.send(GenerationError(e.toString()));
    }
  }
}
