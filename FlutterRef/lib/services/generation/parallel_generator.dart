import 'dart:async';
import 'dart:math';
import 'package:sudoku/index.dart';

/// 并行生成器
/// 利用多核CPU并行生成数独谜题
class ParallelGenerator {
  ParallelGenerator({int concurrency = AppConstants.defaultGenerationConcurrency}) : _concurrency = concurrency;
  final int _concurrency;

  /// 并行生成标准数独终盘
  Future<Board?> generateStandardSolution(
    int size,
    bool Function()? isCancelled,
  ) async => _generateSolution(
    size,
    isCancelled,
    (int seed) async {
      final solver = StandardDLXSolver.create(random: Random(seed));
      return solver.generateSolution(isCancelled: isCancelled);
    },
    (int seed) async => null,
  );

  /// 并行生成对角线数独终盘
  Future<Board?> generateDiagonalSolution(
    int size,
    bool Function()? isCancelled,
  ) async => _generateSolution(
      size,
      isCancelled,
      (int seed) async {
        final solver = DiagonalDLXSolver.create(random: Random(seed));
        return solver.generateSolution(isCancelled: isCancelled);
      },
      (int seed) async => null,
    );

  /// 并行生成窗口数独终盘
  Future<Board?> generateWindowSolution(
    int size,
    bool Function()? isCancelled,
  ) async => _generateSolution(
      size,
      isCancelled,
      (int seed) async {
        final solver = WindowDLXSolver.create(random: Random(seed));
        return solver.generateSolution(isCancelled: isCancelled);
      },
      (int seed) async => null,
    );

  /// 并行生成锯齿数独终盘
  Future<Board?> generateJigsawSolution(
    int size,
    List<List<int>> regionMatrix,
    bool Function()? isCancelled,
  ) async => _generateSolution(
      size,
      isCancelled,
      (int seed) async {
        // 锯齿数独：使用 regionMatrix 创建额外约束
        // 将 regionMatrix 转换为 DLX 可用的约束格式
        final extraRegions = _convertRegionMatrixToExtraRegions(
          size,
          regionMatrix,
        );
        final solver = DLXSudokuSolver(
          size: size,
          random: Random(seed),
          extraRegions: extraRegions,
        );
        return solver.generateSolution(isCancelled: isCancelled);
      },
      (int seed) async => null,
    );

  /// 将区域矩阵转换为 DLX 额外约束格式
  ///
  /// regionMatrix: 每个元素表示该位置属于哪个区域（0-8）
  /// 返回: 每个区域对应一个约束列表（81个元素，1表示属于该区域）
  List<List<int>> _convertRegionMatrixToExtraRegions(
    int size,
    List<List<int>> regionMatrix,
  ) {
    final regions = <List<int>>[];
    final regionCount = size; // 9x9 数独有 9 个区域

    for (int regionId = 0; regionId < regionCount; regionId++) {
      final region = List.generate(size * size, (i) {
        final r = i ~/ size;
        final c = i % size;
        return regionMatrix[r][c] == regionId ? 1 : 0;
      });
      regions.add(region);
    }

    return regions;
  }

  /// 通用并行生成方法
  Future<Board?> _generateSolution(
    int size,
    bool Function()? isCancelled,
    Future<Board?> Function(int) primaryGenerator,
    Future<Board?> Function(int) fallbackGenerator,
  ) async {
    final completer = Completer<Board?>();
    final semaphore = Semaphore(_concurrency);
    var completed = false;
    var attempts = 0;
    const maxAttempts = AppConstants.maxParallelGenerationAttempts;

    // 并行尝试多个种子
    for (int i = 0; i < _concurrency * 2 && attempts < maxAttempts; i++) {
      if (completed) break;
      if (isCancelled?.call() ?? false) break;

      await semaphore.acquire().then((_) async {
        if (completed || (isCancelled?.call() ?? false)) {
          semaphore.release();
          return;
        }

        attempts++;
        try {
          // 首先尝试使用主生成器
          final board = await primaryGenerator(i);
          if (board != null && !completed) {
            completed = true;
            completer.complete(board);
          } else {
            // 回退到备用生成器
            final fallbackBoard = await fallbackGenerator(i);
            if (fallbackBoard != null && !completed) {
              completed = true;
              completer.complete(fallbackBoard);
            }
          }
        } catch (e) {
          // 忽略异常，继续尝试
        } finally {
          semaphore.release();
        }
      });
    }

    // 等待结果或超时
    try {
      return await completer.future.timeout(
        AppConstants.generationTimeout,
        onTimeout: () => null,
      );
    } catch (e) {
      return null;
    }
  }
}

/// 信号量实现
class Semaphore {

  Semaphore(this._maxPermits) : _availablePermits = _maxPermits;
  final int _maxPermits;
  int _availablePermits;
  final List<Completer<void>> _waiters = [];

  /// 获取许可
  Future<void> acquire() async {
    if (_availablePermits > 0) {
      _availablePermits--;
      return Future.value();
    } else {
      final completer = Completer<void>();
      _waiters.add(completer);
      return completer.future;
    }
  }

  /// 释放许可
  void release() {
    if (_waiters.isEmpty) {
      _availablePermits++;
      if (_availablePermits > _maxPermits) {
        _availablePermits = _maxPermits;
      }
    }
  }
}
