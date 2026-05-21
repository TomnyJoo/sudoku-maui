import 'dart:collection';
import 'dart:math';

import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/cell.dart';
import 'package:sudoku/models/game_type.dart';

/// Board对象池
/// 用于管理Board对象的创建和复用，提高性能
class BoardPool {
  
  factory BoardPool() => _instance;
  
  BoardPool._internal();

  static final BoardPool _instance = BoardPool._internal();
  
  // 按游戏类型分类的对象池
  final Map<GameType, Queue<Board>> _pools = {};
  
  // 最大池大小
  static const int _maxPoolSize = 100;
  
  // 最大Board大小
  static const int _maxBoardSize = 21; // Samurai Sudoku的大小
  
  /// 从池中获取Board
  /// 如果池中没有对应大小的Board，则创建新的
  Board acquire(int size) => acquireWithType(size, GameType.standard);
  
  /// 根据游戏类型从池中获取Board
  /// 如果池中没有对应大小的Board，则创建新的
  Board acquireWithType(int size, GameType gameType) {
    if (size < 1 || size > _maxBoardSize) {
      throw ArgumentError('Board size must be between 1 and $_maxBoardSize');
    }
    
    final pool = _pools.putIfAbsent(gameType, Queue<Board>.new);
    
    if (pool.isNotEmpty) {
      final board = pool.removeFirst()
      ..reset();
      return board;
    }
    
    // 池中没有，创建新的
    return _createBoardWithType(size, gameType);
  }
  
  /// 释放Board到池中
  /// 如果池已满，则丢弃
  void release(Board board) {
    final size = board.size;
    
    if (size < 1 || size > _maxBoardSize) {
      return; // 不处理无效大小的Board
    }
    
    final gameType = _getGameTypeFromBoard(board);
    final pool = _pools.putIfAbsent(gameType, Queue<Board>.new);
    
    if (pool.length < _maxPoolSize) {
      // 重置Board后放入池中
      board.reset();
      pool.add(board);
    }
    // 如果池已满，则丢弃该Board
  }
  
  /// 批量释放多个Board
  void releaseAll(Iterable<Board> boards) {
    for (final board in boards) {
      release(board);
    }
  }
  
  /// 清空指定游戏类型的池
  void clear(GameType? gameType) {
    if (gameType == null) {
      _pools.clear();
    } else if (_pools.containsKey(gameType)) {
      _pools[gameType]!.clear();
    }
  }
  
  /// 获取池状态
  Map<String, dynamic> getPoolStatus() {
    final status = <String, dynamic>{};
    
    int totalBoards = 0;
    for (final entry in _pools.entries) {
      status['type_${entry.key.name}'] = entry.value.length;
      totalBoards += entry.value.length;
    }
    
    status['total_boards'] = totalBoards;
    status['max_pool_size'] = _maxPoolSize;
    
    return status;
  }
  
  /// 创建新的Board
  Board createBoard(int size) => _createBoardWithType(size, GameType.standard);
  
  /// 根据游戏类型创建新的Board
  Board _createBoardWithType(int size, GameType gameType) {
    // 创建空的单元格
    final cells = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => Cell(row: row, col: col),
      ),
    );
    
    switch (gameType) {
      case GameType.standard:
        return StandardBoard(size: size, cells: cells);
      case GameType.diagonal:
        return DiagonalBoard(size: size, cells: cells);
      case GameType.window:
        return WindowBoard(size: size, cells: cells);
      case GameType.jigsaw:
        // 对于锯齿数独，需要生成区域矩阵
        final regionMatrix = _generateJigsawRegionMatrix(size);
        return JigsawBoard(
          size: size,
          cells: cells,
          regionMatrix: regionMatrix,
        );
      case GameType.samurai:
        return SamuraiBoard(cells: cells);
      // ignore: no_default_cases
      default:
        return StandardBoard(size: size, cells: cells);
    }
  }
  
  /// 根据Board的运行时类型推断游戏类型
  static GameType _getGameTypeFromBoard(Board board) {
    if (board is StandardBoard) return GameType.standard;
    if (board is DiagonalBoard) return GameType.diagonal;
    if (board is WindowBoard) return GameType.window;
    if (board is JigsawBoard) return GameType.jigsaw;
    if (board is SamuraiBoard) return GameType.samurai;
    return GameType.standard;
  }
  
  /// 生成锯齿数独的区域矩阵
  List<List<int>> _generateJigsawRegionMatrix(int size) {
    // 简单的区域矩阵生成，实际应用中可能需要更复杂的算法
    final matrix = List.generate(size, (i) => List.generate(size, (j) => 0));
    final regions = <Set<(int, int)>>[];
    final used = <(int, int)>{};
    
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (!used.contains((i, j))) {
          final region = _generateJigsawRegion(i, j, size, used);
          regions.add(region);
        }
      }
    }
    
    // 填充区域矩阵
    for (int r = 0; r < regions.length; r++) {
      for (final (i, j) in regions[r]) {
        matrix[i][j] = r;
      }
    }
    
    return matrix;
  }
  
  /// 生成单个锯齿区域
  Set<(int, int)> _generateJigsawRegion(int startRow, int startCol, int size, Set<(int, int)> used) {
    final region = <(int, int)>{};
    final queue = Queue<(int, int)>()
    ..add((startRow, startCol));
    used.add((startRow, startCol));
    
    final directions = [(0, 1), (1, 0), (0, -1), (-1, 0)];
    final random = Random();
    
    while (queue.isNotEmpty && region.length < size) {
      // 随机选择一个元素
      final index = random.nextInt(queue.length);
      final (row, col) = queue.elementAt(index);
      queue.removeWhere((element) => element == (row, col));
      region.add((row, col));
      
      for (final (dr, dc) in directions) {
        final newRow = row + dr;
        final newCol = col + dc;
        if (newRow >= 0 && newRow < size && newCol >= 0 && newCol < size &&
            !used.contains((newRow, newCol)) && region.length < size) {
          used.add((newRow, newCol));
          queue.add((newRow, newCol));
        }
      }
    }
    
    return region;
  }
}
