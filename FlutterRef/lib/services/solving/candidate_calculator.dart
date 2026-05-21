import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/strategies/killer_strategies.dart';
import 'package:sudoku/services/solving/strategy_engine.dart';
import 'package:sudoku/utils/app_logger.dart';

/// 棋盘上下文 - 用于策略分析
class BoardContext {
  BoardContext(this.board, List<Region> regions)
    : size = board.size,
      typeCounts = {} {
    for (final type in RegionType.values) {
      typeCounts[type] = 0;
    }
    for (final region in regions) {
      typeCounts[region.type] = (typeCounts[region.type] ?? 0) + 1;
    }

    final n = size;
    regionCellIndices = regions
        .map((r) => r.cells.map((c) => c.row * n + c.col).toList())
        .toList();
    regionTypes = regions.map((r) => r.type).toList();
    candidateSets = List.generate(n, (_) => List.generate(n, (_) => <int>{}));
    _cellToRegions = null;
  }

  factory BoardContext.fromBoard(Board board) =>
      BoardContext(board, board.regions);

  Board board;
  final int size;
  late final List<List<Set<int>>> candidateSets;
  late final List<List<int>> regionCellIndices;
  late final List<RegionType> regionTypes;
  List<List<List<int>>>? _cellToRegions;
  late final Map<RegionType, int> typeCounts;

  // 杀手数独专用数据
  List<KillerCage>? _killerCages;
  Map<(int, int), KillerCage>? _cellToKillerCage;

  /// 获取单元格到区域的映射（延迟计算）
  List<List<List<int>>> get cellToRegions {
    _cellToRegions ??= _computeCellToRegions();
    return _cellToRegions!;
  }

  /// 计算单元格到区域的映射
  List<List<List<int>>> _computeCellToRegions() {
    final n = size;
    final result = List.generate(n, (_) => List.generate(n, (_) => <int>[]));
    for (int regIdx = 0; regIdx < regionCellIndices.length; regIdx++) {
      for (final idx in regionCellIndices[regIdx]) {
        final r = idx ~/ n;
        final c = idx % n;
        result[r][c].add(regIdx);
      }
    }
    return result;
  }

  bool get hasGlobalRows => typeCounts[RegionType.row] == size;
  bool get hasGlobalColumns => typeCounts[RegionType.column] == size;
  bool get hasGlobalBlocks => typeCounts[RegionType.block] == size;
  bool get hasGlobalRowsAndColumns => hasGlobalRows && hasGlobalColumns;

  List<int> getRegionCells(int regionIdx) => regionCellIndices[regionIdx];
  RegionType getRegionType(int regionIdx) => regionTypes[regionIdx];

  /// 通过区域索引获取区域对象
  Region getRegion(int regionIdx) => board.regions[regionIdx];

  /// 获取包含指定单元格的所有区域
  List<Region> getRegionsForCell(int row, int col) {
    final regionIndices = cellToRegions[row][col];
    return regionIndices.map((idx) => board.regions[idx]).toList();
  }

  /// 直接获取指定位置的单元格
  Cell cell(int row, int col) => board.getCell(row, col);

  /// 直接获取单元格值
  int? cellValue(int row, int col) => board.getCell(row, col).value;

  Set<int> getCandidates(int row, int col) => candidateSets[row][col];

  void setCandidates(int row, int col, Set<int> candidates) {
    candidateSets[row][col] = candidates;
  }

  void removeCandidate(int row, int col, int number) {
    candidateSets[row][col].remove(number);
  }

  void removeCandidates(int row, int col, Set<int> numbers) {
    candidateSets[row][col].removeAll(numbers);
  }

  void addCandidate(int row, int col, int number) {
    candidateSets[row][col].add(number);
  }

  void addCandidates(int row, int col, Set<int> numbers) {
    candidateSets[row][col].addAll(numbers);
  }

  bool hasCandidate(int row, int col, int number) =>
      candidateSets[row][col].contains(number);

  int candidateCount(int row, int col) => candidateSets[row][col].length;

  bool isSingleCandidate(int row, int col) =>
      candidateSets[row][col].length == 1;

  int? getSingleCandidate(int row, int col) {
    if (candidateSets[row][col].length == 1) {
      return candidateSets[row][col].first;
    }
    return null;
  }

  void setKillerCages(List<KillerCage> cages) {
    _killerCages = cages;
    _cellToKillerCage = {};
    for (final cage in cages) {
      for (final (r, c) in cage.cellCoordinates) {
        _cellToKillerCage![(r, c)] = cage;
      }
    }
  }

  List<KillerCage>? get killerCages => _killerCages;

  KillerCage? getCageForCell(int row, int col) =>
      _cellToKillerCage?[(row, col)];
}

/// 候选数计算器
class CandidateCalculator {
  CandidateCalculator(this._board) {
    final regions = _board.regions;
    if (regions.isEmpty) {
      throw ArgumentError('棋盘至少要有一个区域');
    }
    _context = BoardContext(_board, regions);
    _killerBoard = _board is KillerBoard ? _board : null;
    _boardHash = _computeBoardHash();
  }

  final Board _board;
  late final BoardContext _context;
  KillerBoard? _killerBoard;
  String? _boardHash;
  int get size => _board.size;
  BoardContext get context => _context;
  int getMaxNumber() => _board.getMaxNumber();

  /// 计算棋盘哈希（用于检测棋盘变化）
  String _computeBoardHash() {
    final buffer = StringBuffer();
    for (int row = 0; row < _board.size; row++) {
      for (int col = 0; col < _board.size; col++) {
        final cell = _board.getCell(row, col);
        buffer.write('${cell.value ?? 0};');
      }
    }
    return buffer.toString();
  }

  /// 计算所有单元格的候选数
  Map<String, Set<int>> computeAllCandidates({
    bool useAdvancedStrategies = true,
  }) {
    try {
      // 检查棋盘是否变化，如果没变化则重用上下文
      final currentHash = _computeBoardHash();
      if (_boardHash != currentHash) {
        _boardHash = currentHash;
        _context = BoardContext(_board, _board.regions);
      }

      // 第一步：初始化候选数为 {1,2,3,4,5,6,7,8,9}
      _initializeCandidates();

      // 第二步：应用区域互异约束（行、列、宫约束）
      // 必须先应用区域约束，移除同行/列/宫已填数字
      _applyRegionConstraints();

      // 第三步：如果是杀手数独，设置笼子信息并应用笼子约束
      // 区域约束后候选数已缩小，笼子约束在此基础上进一步收缩
      if (_killerBoard != null) {
        _context.setKillerCages(_killerBoard!.cages);
        // 循环应用笼子约束和区域约束，直到无变化（确保约束充分传播）
        bool changed = true;
        int maxRounds = 5;
        while (changed && maxRounds-- > 0) {
          changed = false;
          final before = _captureAllCandidates();
          _applyKillerCageConstraints();
          _applyRegionConstraints();
          if (_candidatesChangedFrom(before)) {
            changed = true;
          }
        }
      }

      // 第四步：应用高级策略（统一使用策略系统）
      if (useAdvancedStrategies) {
        StrategyService.initialize();
        if (_killerBoard != null) {
          StrategyService.instance.applyStrategiesForGame(_context, GameType.killer);
        } else {
          StrategyService.instance.applyStrategies(_context);
        }
      }

      // 构建结果
      final result = <String, Set<int>>{};

      for (int r = 0; r < _board.size; r++) {
        for (int c = 0; c < _board.size; c++) {
          final candidates = _context.getCandidates(r, c);
          result['$r,$c'] = candidates.toSet();
        }
      }

      // 验证候选数一致性（仅记录警告，不阻断计算）
      _validateCandidates(result);

      return result;
    } catch (e, stackTrace) {
      AppLogger.warning('候选数计算失败: $e\n$stackTrace');
      // 返回空结果，表示无解
      return {};
    }
  }

  /// 计算指定单元格的候选数
  Set<int> computeCellCandidates(
    int row,
    int col, {
    bool useAdvancedStrategies = true,
  }) {
    final candidates = computeAllCandidates(
      useAdvancedStrategies: useAdvancedStrategies,
    );
    return candidates['$row,$col'] ?? <int>{};
  }

  /// 计算武士数独局部候选数（只计算指定子棋盘）
  Map<String, Set<int>> computeSamuraiCandidates(
    List<int> visibleSubBoards, {
    bool useAdvancedStrategies = true,
  }) {
    final result = <String, Set<int>>{};
    final maxNumber = _board.getMaxNumber();

    for (final subBoardIndex in visibleSubBoards) {
      final (startRow, startCol) = SamuraiBoard.subGridOffsets[subBoardIndex];
      final virtualBoard = _createVirtualSubBoard(startRow, startCol);
      final subBoardCalculator = CandidateCalculator(virtualBoard);
      final subBoardCandidates = subBoardCalculator.computeAllCandidates(
        useAdvancedStrategies: useAdvancedStrategies,
      );

      for (int subRow = 0; subRow < maxNumber; subRow++) {
        for (int subCol = 0; subCol < maxNumber; subCol++) {
          final originalRow = startRow + subRow;
          final originalCol = startCol + subCol;
          final key = '$originalRow,$originalCol';
          final subKey = '$subRow,$subCol';
          final candidates = subBoardCandidates[subKey]!;

          final previous = result[key];
          if (previous == null) {
            result[key] = candidates;
          } else if (previous.isNotEmpty) {
            final intersection = previous.intersection(candidates);
            result[key] = intersection;
          }
        }
      }
    }
    return result;
  }

  /// 创建子棋盘的虚拟数独棋盘
  StandardBoard _createVirtualSubBoard(int startRow, int startCol) {
    final maxNumber = _board.getMaxNumber(); // 9
    final cells = List.generate(
      maxNumber,
      (row) => List.generate(maxNumber, (col) {
        final originalCell = _board.getCell(startRow + row, startCol + col);
        return Cell(
          row: row,
          col: col,
          value: originalCell.value,
          isFixed: originalCell.isFixed,
          isError: originalCell.isError,
          candidates: originalCell.candidates,
        );
      }),
    );

    final regions = _buildStandardRegions(cells, maxNumber);
    return StandardBoard(size: maxNumber, cells: cells, regions: regions);
  }

  List<Region> _buildStandardRegions(List<List<Cell>> cells, int size) {
    final regions = <Region>[];
    // 行
    for (int r = 0; r < size; r++) {
      final rowCells = List.generate(size, (c) => cells[r][c]);
      regions.add(
        Region(
          id: 'row_$r',
          type: RegionType.row,
          name: '第${r + 1}行',
          cells: rowCells,
        ),
      );
    }
    // 列
    for (int c = 0; c < size; c++) {
      final colCells = List.generate(size, (r) => cells[r][c]);
      regions.add(
        Region(
          id: 'col_$c',
          type: RegionType.column,
          name: '第${c + 1}列',
          cells: colCells,
        ),
      );
    }
    // 宫（标准 9x9 宫大小为 3）
    const blockSize = AppConstants.standardBlockSize;
    final blocksPerSide = size ~/ blockSize;
    int blockId = 0;
    for (int br = 0; br < blocksPerSide; br++) {
      for (int bc = 0; bc < blocksPerSide; bc++) {
        final blockCells = <Cell>[];
        for (int r = br * blockSize; r < (br + 1) * blockSize; r++) {
          for (int c = bc * blockSize; c < (bc + 1) * blockSize; c++) {
            blockCells.add(cells[r][c]);
          }
        }
        regions.add(
          Region(
            id: 'block_$blockId',
            type: RegionType.block,
            name: '第${blockId + 1}宫',
            cells: blockCells,
          ),
        );
        blockId++;
      }
    }
    return regions;
  }

  /// 初始化候选数为 {1,2,3,4,5,6,7,8,9}
  void _initializeCandidates() {
    final maxNumber = _board.getMaxNumber();
    final fullSet = Set<int>.from(List.generate(maxNumber, (i) => i + 1));

    final n = _board.size;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (_board.getCell(r, c).value != null) {
          _context.setCandidates(r, c, <int>{});
        } else {
          _context.setCandidates(r, c, fullSet.toSet());
        }
      }
    }
  }

  /// 应用区域互异约束（行、列、宫约束）
  void _applyRegionConstraints() {
    final n = _board.size;

    // 预先构建每个区域的已填数字集合
    final regionFilledNumbers = <int, Set<int>>{};
    for (int regIdx = 0; regIdx < _context.regionCellIndices.length; regIdx++) {
      final region = _context.getRegion(regIdx);
      final filledNumbers = <int>{};
      for (final cell in region.cells) {
        final value = _context.cellValue(cell.row, cell.col);
        if (value != null) {
          filledNumbers.add(value);
        }
      }
      regionFilledNumbers[regIdx] = filledNumbers;
    }

    // 为每个空单元格应用区域约束
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        // 跳过已填单元格
        if (_context.cellValue(r, c) != null) continue;

        // 获取当前候选数
        final candidates = _context.getCandidates(r, c).toSet();

        // 从候选数中移除所有相关区域的已填数字
        for (final regIdx in _context.cellToRegions[r][c]) {
          candidates.removeAll(regionFilledNumbers[regIdx]!);
        }

        _context.setCandidates(r, c, candidates);
      }
    }
  }

  /// 应用杀手数独笼子约束（基础约束）
  void _applyKillerCageConstraints() {
    final cages = _context.killerCages;
    if (cages == null) return;

    for (final cage in cages) {
      KillerCombinationChecker.applyCageConstraint(
        cage.sum,
        cage.cellCoordinates,
        (r, c) => _context.getCandidates(r, c),
        (r, c, candidates) => _context.setCandidates(r, c, candidates),
        (r, c) => _board.getCell(r, c).value,
      );
    }
  }

  /// 验证候选数一致性
  bool _validateCandidates(Map<String, Set<int>> result) {
    bool valid = true;
    for (int r = 0; r < _board.size; r++) {
      for (int c = 0; c < _board.size; c++) {
        if (_board.getCell(r, c).value != null) continue;

        final candidates = result['$r,$c'];
        if (candidates == null || candidates.isEmpty) {
          AppLogger.warning('空候选数 ($r,$c): 棋盘状态不一致');
          valid = false;
        }
      }
    }
    return valid;
  }

  /// 快照所有候选数（用于检测变化）
  Map<String, Set<int>> _captureAllCandidates() {
    final snapshot = <String, Set<int>>{};
    for (int r = 0; r < _board.size; r++) {
      for (int c = 0; c < _board.size; c++) {
        snapshot['$r,$c'] = _context.getCandidates(r, c).toSet();
      }
    }
    return snapshot;
  }

  /// 检查候选数是否与快照不同
  bool _candidatesChangedFrom(Map<String, Set<int>> snapshot) {
    for (int r = 0; r < _board.size; r++) {
      for (int c = 0; c < _board.size; c++) {
        final key = '$r,$c';
        final current = _context.getCandidates(r, c);
        final before = snapshot[key];
        if (before == null || current.length != before.length) return true;
        for (final num in current) {
          if (!before.contains(num)) return true;
        }
      }
    }
    return false;
  }
}
