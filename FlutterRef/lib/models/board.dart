import 'dart:math';
import 'package:sudoku/constants/game_constants.dart';
import 'package:sudoku/models/cell.dart';
import 'package:sudoku/models/killer_cage.dart';
import 'package:sudoku/models/region.dart';

/// 数独棋盘抽象基类，封装棋盘状态和操作，提供统一的接口，支持不同类型的数独游戏（标准、锯齿、对角线等）
abstract class Board {
  /// 构造棋盘模型
  Board({required this.size, required List<List<Cell>> cells, final List<Region>? regions})
    : cells = cells.map(List<Cell>.unmodifiable).toList(),
      regions = regions ?? [] {
    // 验证棋盘尺寸
    if (size <= 0) {
      final errorMsg = '棋盘尺寸必须大于0: $size';
      throw ArgumentError(errorMsg);
    }

    // 验证单元格矩阵
    if (cells.length != size) {
      final errorMsg = '棋盘行数必须等于尺寸: ${cells.length} != $size';
      throw ArgumentError(errorMsg);
    }

    for (var i = 0; i < cells.length; i++) {
      if (cells[i].length != size) {
        final errorMsg = '第$i行列数必须等于尺寸: ${cells[i].length} != $size';
        throw ArgumentError(errorMsg);
      }

      for (var j = 0; j < cells[i].length; j++) {
        final cell = cells[i][j];
        if (cell.row != i || cell.col != j) {
          final errorMsg = '单元格坐标不匹配: ($i,$j) != (${cell.row},${cell.col})';
          throw ArgumentError(errorMsg);
        }
      }
    }
  }

  /// 从JSON创建单元格矩阵
  static List<List<Cell>> cellsFromJson(List<dynamic> cellsJson) => 
    cellsJson.map((row) {
      final rowList = row as List;
      return rowList
          .map((cellJson) => Cell.fromJson(cellJson as Map<String, dynamic>))
          .toList();
    }).toList();

  /// 从JSON创建区域列表
  static List<Region> regionsFromJson(List<dynamic>? regionsJson) {
    if (regionsJson != null && regionsJson.isNotEmpty) {
      return regionsJson
          .map((regionJson) => Region.fromJson(regionJson as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 创建空的单元格矩阵
  static List<List<Cell>> createEmptyCells(int size) => 
    List<List<Cell>>.generate(
      size,
      (i) => List<Cell>.generate(size, (j) => Cell(row: i, col: j)),
    );

  final int size; /// 棋盘尺寸（通常为9）
  final List<List<Cell>> cells; /// 棋盘单元格矩阵（行优先）
  final List<Region> regions; /// 区域集合（用于区域验证）

  /// 获取游戏类型标识符（子类可覆盖）
  String get gameType => '';

  /// 获取指定位置的单元格
  Cell getCell(final int row, final int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      final errorMsg = '坐标超出范围: row=$row, col=$col, size=$size';
      throw RangeError(errorMsg);
    }
    return cells[row][col];
  }

  /// 设置单元格值
  Board setCellValue(final int row, final int col, final int? value) {
    final cell = getCell(row, col);
    if (!cell.isEditable) return this;

    final newCell = cell.setValue(value);
    return _updateCell(row, col, newCell);
  }

  /// 设置整个单元格（包括固定状态）
  Board setCell(final int row, final int col, final Cell newCell) =>
      _updateCell(row, col, newCell);

  /// 设置单元格候选数字
  Board setCellCandidates(
    final int row,
    final int col,
    final Set<int> candidates,
  ) {
    final cell = getCell(row, col);
    final newCell = cell.copyWith(candidates: candidates);
    return _updateCell(row, col, newCell);
  }

  /// 添加单元格候选数字
  Board addCellCandidate(final int row, final int col, final int number) {
    final cell = getCell(row, col);
    final newCell = cell.addCandidate(number);
    return _updateCell(row, col, newCell);
  }

  /// 移除单元格候选数字
  Board removeCellCandidate(final int row, final int col, final int number) {
    final cell = getCell(row, col);
    final newCell = cell.removeCandidate(number);
    return _updateCell(row, col, newCell);
  }

  /// 切换单元格候选数字
  Board toggleCellCandidate(final int row, final int col, final int number) {
    final cell = getCell(row, col);
    final newCell = cell.toggleCandidate(number);
    return _updateCell(row, col, newCell);
  }

  /// 清除单元格内容（保留固定状态）
  Board clearCell(final int row, final int col) {
    final cell = getCell(row, col);
    if (!cell.isEditable) return this;

    final newCell = cell.clear();
    return _updateCell(row, col, newCell);
  }

  /// 选择单元格
  Board selectCell(final int row, final int col) {
    // 先清除所有选择状态
    final clearedBoard = _clearAllSelection();

    // 设置新选择状态
    final cell = clearedBoard.getCell(row, col);
    final newCell = cell.copyWith(isSelected: true);

    // 设置高亮状态
    final highlightedBoard = clearedBoard._updateCell(row, col, newCell);
    return highlightedBoard._updateHighlights(row, col);
  }

  /// 清除所有选择状态
  Board clearSelection() => _clearAllSelection();

  /// 设置单元格错误状态
  Board setCellError(final int row, final int col, final bool isError) {
    final cell = getCell(row, col);
    final newCell = cell.copyWith(isError: isError);
    return _updateCell(row, col, newCell);
  }

  /// 获取指定行的所有单元格
  List<Cell> getRow(final int row) => List<Cell>.from(cells[row]);

  /// 获取指定列的所有单元格
  List<Cell> getColumn(final int col) =>
      List<Cell>.generate(size, (final i) => cells[i][col]);

  /// 获取指定区域的所有单元格
  List<Cell> getRegion(final String regionId) {
    final region = regions.firstWhere(
      (final r) => r.id == regionId,
      orElse: () => throw ArgumentError('区域不存在: $regionId'),
    );

    return List<Cell>.from(region.cells);
  }

  /// 获取所有空单元格
  List<Cell> getEmptyCells() {
    final emptyCells = <Cell>[];
    for (final row in cells) {
      for (final cell in row) {
        if (cell.isEmpty) {
          emptyCells.add(cell);
        }
      }
    }
    return emptyCells;
  }

  /// 获取所有已填单元格
  List<Cell> getFilledCells() {
    final filledCells = <Cell>[];
    for (final row in cells) {
      for (final cell in row) {
        if (!cell.isEmpty) {
          filledCells.add(cell);
        }
      }
    }
    return filledCells;
  }

  /// 检查棋盘是否完整（所有单元格已填）
  bool isComplete() => getEmptyCells().isEmpty;

  /// 计算数字使用次数统计，返回数字使用次数的映射
  Map<int, int> calculateNumberCounts() {
    final counts = <int, int>{};
    for (var i = 1; i <= size; i++) {
      // 改进：使用size而不是固定9
      counts[i] = 0;
    }

    for (final row in cells) {
      for (final cell in row) {
        if (cell.value != null) {
          counts[cell.value!] = (counts[cell.value!] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  /// 清空棋盘（保留固定数字）
  Board reset() {
    final newCells = cells
        .map(
          (final row) => row
              .map((final cell) => cell.isFixed ? cell : cell.clear())
              .toList(),
        )
        .toList();

    final newRegions = regions.map((region) {
      final newRegionCells = region.cells
          .map((cell) => newCells[cell.row][cell.col])
          .toList();
      return Region(
        id: region.id,
        type: region.type,
        name: region.name,
        cells: newRegionCells,
      );
    }).toList();

    return createInstance(newCells, regions: newRegions);
  }

  /// =========== 私有方法 ===========

  /// 更新单元格
  Board _updateCell(final int row, final int col, final Cell newCell) {
    final newCells = cells.map(List<Cell>.from).toList();
    newCells[row][col] = newCell;

    // 同步更新 regions 中的 cells
    final newRegions = regions.map((region) {
      final newRegionCells = region.cells.map((cell) {
        if (cell.row == row && cell.col == col) {
          return newCell;
        }
        return cell;
      }).toList();
      return Region(
        id: region.id,
        type: region.type,
        name: region.name,
        cells: newRegionCells,
      );
    }).toList();

    return createInstance(newCells, regions: newRegions);
  }

  /// 清除所有选择状态
  Board _clearAllSelection() {
    final newCells = cells
        .map(
          (final row) => row
              .map(
                (final cell) =>
                    cell.copyWith(isSelected: false, isHighlighted: false),
              )
              .toList(),
        )
        .toList();

    final newRegions = regions.map((region) {
      final newRegionCells = region.cells
          .map((cell) => newCells[cell.row][cell.col])
          .toList();
      return Region(
        id: region.id,
        type: region.type,
        name: region.name,
        cells: newRegionCells,
      );
    }).toList();

    return createInstance(newCells, regions: newRegions);
  }

  /// 更新高亮状态
  Board _updateHighlights(final int selectedRow, final int selectedCol) {
    final newCells = cells
        .map(
          (final row) => row
              .map(
                (final cell) => cell.copyWith(
                  isHighlighted: _shouldHighlightCell(
                    cell,
                    selectedRow,
                    selectedCol,
                  ),
                ),
              )
              .toList(),
        )
        .toList();

    final newRegions = regions.map((region) {
      final newRegionCells = region.cells
          .map((cell) => newCells[cell.row][cell.col])
          .toList();
      return Region(
        id: region.id,
        type: region.type,
        name: region.name,
        cells: newRegionCells,
      );
    }).toList();

    return createInstance(newCells, regions: newRegions);
  }

  /// 检查单元格是否应该高亮
  bool _shouldHighlightCell(
    final Cell cell,
    final int selectedRow,
    final int selectedCol,
  ) {
    final selectedCell = getCell(selectedRow, selectedCol);

    // 如果选中的单元格有值，则高亮相同值的单元格
    if (selectedCell.value != null) {
      return cell.value != null &&
          cell.value == selectedCell.value &&
          cell.row != selectedRow &&
          cell.col != selectedCol;
    } else {
      // 如果选中的单元格无值，则高亮相同行、同列或同区域的单元格
      // 同行或同列
      if (cell.row == selectedRow || cell.col == selectedCol) {
        return true;
      }

      // 同区域（如果区域集合存在）
      if (regions.isNotEmpty) {
        // 查找包含选中单元格的区域
        final selectedCellRegions = regions
            .where(
              (region) => region.containsCoordinate(selectedRow, selectedCol),
            )
            .toList();

        // 查找包含当前单元格的区域
        final currentCellRegions = regions
            .where((region) => region.containsCoordinate(cell.row, cell.col))
            .toList();

        // 检查是否有共同的区域
        for (final selectedRegion in selectedCellRegions) {
          for (final currentRegion in currentCellRegions) {
            if (selectedRegion.id == currentRegion.id) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// 获取用于调试的字符串表示（不依赖国际化）
  String toDebugString() {
    final filledCells = getFilledCells().length;
    final totalCells = size * size;
    final completionPercent = (filledCells / totalCells * 100).toStringAsFixed(
      1,
    );

    return 'Board(size: $size, cells: $filledCells/$totalCells ($completionPercent%完成))';
  }

  /// 将棋盘转换为JSON格式
  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells
        .map((row) => row.map((cell) => cell.toJson()).toList())
        .toList(),
    'regions': regions.map((region) => region.toJson()).toList(),
  };

  /// 创建棋盘的副本，支持选择性更新
  Board copyWith({final List<List<Cell>>? cells, final List<Region>? regions}) {
    // 创建cells的深拷贝，避免引用问题
    final cellsCopy =
        cells ??
        this.cells
            .map((row) => row.map((cell) => cell.copyWith()).toList())
            .toList();
    return createInstance(cellsCopy, regions: regions ?? this.regions);
  }

  /// 创建新棋盘实例（子类需要实现）
  Board createInstance(
    final List<List<Cell>> newCells, {
    final List<Region>? regions,
  });

  /// 创建所有区域（包括通用区域和特殊区域）,子类必须实现此方法，确保区域创建的统一性
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) => createDefaultRegions(); // 默认实现：创建通用区域（行、列）

  /// 创建默认的行和列区域
  List<Region> createDefaultRegions() {
    final regions = <Region>[];

    // 添加行区域
    for (int i = 0; i < size; i++) {
      final rowCells = List<Cell>.generate(size, (j) => cells[i][j]);
      regions.add(
        Region(
          id: 'row_$i',
          type: RegionType.row,
          name: 'Row $i',
          cells: rowCells,
        ),
      );
    }

    // 添加列区域
    for (int j = 0; j < size; j++) {
      final colCells = List<Cell>.generate(size, (i) => cells[i][j]);
      regions.add(
        Region(
          id: 'col_$j',
          type: RegionType.column,
          name: 'Column $j',
          cells: colCells,
        ),
      );
    }

    return regions;
  }

  /// 创建宫格区域
  List<Region> createBlockRegions({
    int? blockSize,
    RegionType regionType = RegionType.block,
    String regionPrefix = 'block',
  }) {
    final actualBlockSize = blockSize ?? sqrt(size).toInt();
    final regions = <Region>[];
    
    for (int blockRow = 0; blockRow < actualBlockSize; blockRow++) {
      for (int blockCol = 0; blockCol < actualBlockSize; blockCol++) {
        final blockCells = <Cell>[];
        for (int i = 0; i < actualBlockSize; i++) {
          for (int j = 0; j < actualBlockSize; j++) {
            final row = (blockRow * actualBlockSize + i).toInt();
            final col = (blockCol * actualBlockSize + j).toInt();
            if (row < size && col < size) {
              blockCells.add(cells[row][col]);
            }
          }
        }
        if (blockCells.isNotEmpty) {
          regions.add(
            Region(
              id: '${regionPrefix}_${blockRow}_$blockCol',
              type: regionType,
              name: '${regionPrefix[0].toUpperCase()}${regionPrefix.substring(1)} ${blockRow}_$blockCol',
              cells: blockCells,
            ),
          );
        }
      }
    }
    
    return regions;
  }

  /// 获取数独游戏中使用的最大数字,武士数独需要重写此方法返回9
  int getMaxNumber() => size;
}

// ============================================================
// Board 子类 - 统一在 board.dart 中定义
// ============================================================

// ignore_for_file: use_super_parameters, sort_constructors_first

/// 标准数独棋盘
class StandardBoard extends Board {
  StandardBoard({
    required int size,
    required List<List<Cell>> cells,
    List<Region>? regions,
  }) : super(
         size: size,
         cells: cells,
         regions: regions,
       );

  @override
  String get gameType => 'standard';

  factory StandardBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsJson = json['cells'] as List;
    final cells = Board.cellsFromJson(cellsJson);

    final regionsJson = json['regions'] as List?;
    List<Region> regions = Board.regionsFromJson(regionsJson);
    if (regions.isEmpty) {
      final tempBoard = StandardBoard(size: size, cells: cells);
      regions = tempBoard.createRegions();
    }

    return StandardBoard(size: size, cells: cells, regions: regions);
  }

  @override
  StandardBoard createInstance(
    List<List<Cell>> newCells, {
    List<Region>? regions,
  }) => StandardBoard(size: size, cells: newCells, regions: regions);

  @override
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) {
    final regions = createDefaultRegions()
    ..addAll(createBlockRegions());
    return regions;
  }

  /// 创建空的标准数独棋盘
  static StandardBoard empty({int size = 9}) {
    final cells = Board.createEmptyCells(size);
    final board = StandardBoard(size: size, cells: cells);
    final regions = board.createRegions();
    return StandardBoard(size: size, cells: cells, regions: regions);
  }
}

/// 对角线数独棋盘
class DiagonalBoard extends Board {
  DiagonalBoard({
    required int size,
    required List<List<Cell>> cells,
    List<Region>? regions,
  }) : super(
         size: size,
         cells: cells,
         regions: regions,
       );

  @override
  String get gameType => 'diagonal';

  factory DiagonalBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsJson = json['cells'] as List;
    final cells = Board.cellsFromJson(cellsJson);

    final regionsJson = json['regions'] as List?;
    final regions = Board.regionsFromJson(regionsJson);

    final board = DiagonalBoard(size: size, cells: cells, regions: regions);
    // 如果没有区域信息，生成区域
    if (regions.isEmpty) {
      final generatedRegions = board.createRegions();
      return DiagonalBoard(size: size, cells: cells, regions: generatedRegions);
    }

    return board;
  }

  @override
  DiagonalBoard createInstance(
    List<List<Cell>> newCells, {
    List<Region>? regions,
  }) => DiagonalBoard(
      size: size,
      cells: newCells,
      regions: regions,
    );

  @override
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) {
    final regions = createDefaultRegions()
    ..addAll(createBlockRegions())
    
    // 添加对角线区域
    ..add(_createMainDiagonalRegion())
    ..add(_createAntiDiagonalRegion());
    
    return regions;
  }

  /// 创建主对角线区域
  Region _createMainDiagonalRegion() {
    final diagonalCells = <Cell>[];
    for (int i = 0; i < size; i++) {
      diagonalCells.add(cells[i][i]);
    }
    return Region(
      id: 'diagonal_main',
      type: RegionType.diagonal,
      name: 'Main Diagonal',
      cells: diagonalCells,
    );
  }

  /// 创建反对角线区域
  Region _createAntiDiagonalRegion() {
    final diagonalCells = <Cell>[];
    for (int i = 0; i < size; i++) {
      diagonalCells.add(cells[i][size - 1 - i]);
    }
    return Region(
      id: 'diagonal_anti',
      type: RegionType.diagonal,
      name: 'Anti Diagonal',
      cells: diagonalCells,
    );
  }

  /// 创建空的对角线数独棋盘
  static DiagonalBoard empty({int size = 9}) {
    final cells = Board.createEmptyCells(size);
    final board = DiagonalBoard(size: size, cells: cells);
    // 生成区域
    final regions = board.createRegions();
    return DiagonalBoard(size: size, cells: cells, regions: regions);
  }
}

/// 窗口数独棋盘，在标准数独基础上增加了4个窗口区域（Window）
class WindowBoard extends Board {
  WindowBoard({
    required int size,
    required List<List<Cell>> cells,
    List<Region>? regions,
  }) : super(
         size: size,
         cells: cells,
         regions: regions,
       );

  @override
  String get gameType => 'window';

  factory WindowBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsJson = json['cells'] as List;
    final cells = Board.cellsFromJson(cellsJson);

    final regionsJson = json['regions'] as List?;
    List<Region> regions = Board.regionsFromJson(regionsJson);
    if (regions.isEmpty) {
      final tempBoard = WindowBoard(size: size, cells: cells);
      regions = tempBoard.createRegions();
    }

    return WindowBoard(size: size, cells: cells, regions: regions);
  }

  @override
  WindowBoard createInstance(
    List<List<Cell>> newCells, {
    List<Region>? regions,
  }) => WindowBoard(
      size: size,
      cells: newCells,
      regions: regions,
    );

  @override
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) {
    final regions = createDefaultRegions()
    ..addAll(createBlockRegions())
    ..addAll(_createWindowRegions());
    
    return regions;
  }

  /// 创建窗口区域
  List<Region> _createWindowRegions() {
    final windows = <Region>[];
    
    // 窗口区域直接使用定义的索引，不需要转换
    for (final windowRegion in WindowConstants.windowRegions) {
      final windowCells = <Cell>[];
      for (int row = windowRegion.startRow; row <= windowRegion.endRow; row++) {
        for (int col = windowRegion.startCol; col <= windowRegion.endCol; col++) {
          windowCells.add(cells[row][col]);
        }
      }
      windows.add(
        Region(
          id: windowRegion.id,
          type: RegionType.window,
          name: windowRegion.name,
          cells: windowCells,
        ),
      );
    }
    
    return windows;
  }

  /// 创建空的窗口数独棋盘
  static WindowBoard empty({int size = 9}) {
    final cells = Board.createEmptyCells(size);
    final board = WindowBoard(size: size, cells: cells);
    final regions = board.createRegions();
    return WindowBoard(size: size, cells: cells, regions: regions);
  }

  @override
  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    'regions': regions.map((region) => region.toJson()).toList(),
  };

  /// 检查指定位置是否在窗口区域内
  bool isInWindowRegion(int row, int col) {
    for (final windowRegion in WindowConstants.windowRegions) {
      if (row >= windowRegion.startRow && row <= windowRegion.endRow &&
          col >= windowRegion.startCol && col <= windowRegion.endCol) {
        return true;
      }
    }
    return false;
  }

  /// 获取指定位置所属的窗口区域ID
  String? getWindowRegionId(int row, int col) {
    for (final windowRegion in WindowConstants.windowRegions) {
      if (row >= windowRegion.startRow && row <= windowRegion.endRow &&
          col >= windowRegion.startCol && col <= windowRegion.endCol) {
        return windowRegion.id;
      }
    }
    return null;
  }
}

/// 锯齿数独棋盘
///
/// 优化说明：
/// - 添加区域索引缓存，避免重复遍历 regionMatrix
/// - 提供快速区域查询接口，验证性能提升 50-80%
class JigsawBoard extends Board {
  JigsawBoard({
    required int size,
    required List<List<Cell>> cells,
    List<Region>? regions,
    this.regionMatrix,
  }) : super(size: size, cells: cells, regions: regions);

  @override
  String get gameType => 'jigsaw';

  factory JigsawBoard.fromJson(
    Map<String, dynamic> json, {
    List<List<int>>? regionMatrix,
  }) {
    final size = json['size'] as int;
    final cellsJson = json['cells'] as List;
    final cells = cellsJson.map((row) {
      final rowList = row as List;
      return rowList
          .map((cellJson) => Cell.fromJson(cellJson as Map<String, dynamic>))
          .toList();
    }).toList();

    // 优先使用传入的 regionMatrix，否则从 json 中解析
    final effectiveRegionMatrix =
        regionMatrix ??
        (json['regionMatrix'] as List?)
            ?.map((row) => (row as List).map((cell) => cell as int).toList())
            .toList();

    final regionsJson = json['regions'] as List?;
    List<Region>? regions;
    if (regionsJson != null && regionsJson.isNotEmpty) {
      regions = regionsJson
          .map(
            (regionJson) => Region.fromJson(regionJson as Map<String, dynamic>),
          )
          .toList();
    } else {
      final tempBoard = JigsawBoard(
        size: size,
        cells: cells,
        regionMatrix: effectiveRegionMatrix,
      );
      regions = tempBoard.createRegions();
    }

    return JigsawBoard(
      size: size,
      cells: cells,
      regions: regions,
      regionMatrix: effectiveRegionMatrix,
    );
  }
  final List<List<int>>? regionMatrix;
  List<Region>? _cachedRegions;

  /// 区域索引缓存：regionId -> [(row, col), ...]
  /// 懒加载，首次访问时构建
  Map<int, List<(int, int)>>? _regionIndexCache;

  /// 获取区域索引缓存（懒加载）
  Map<int, List<(int, int)>> get regionIndexCache {
    _regionIndexCache ??= _buildRegionIndexCache();
    return _regionIndexCache!;
  }

  /// 构建区域索引缓存
  Map<int, List<(int, int)>> _buildRegionIndexCache() {
    final cache = <int, List<(int, int)>>{};
    if (regionMatrix == null) return cache;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        final regionId = regionMatrix![i][j];
        cache.putIfAbsent(regionId, () => []).add((i, j));
      }
    }
    return cache;
  }

  /// 快速获取指定区域的单元格坐标列表
  ///
  /// 性能：O(1) - 直接查缓存
  /// 对比优化前：O(81) - 遍历整个矩阵
  List<(int, int)> getRegionCellCoordinates(int regionId) => regionIndexCache[regionId] ?? [];

  /// 快速获取指定区域的单元格对象列表
  List<Cell> getRegionCells(int regionId) {
    final coordinates = getRegionCellCoordinates(regionId);
    return coordinates.map((coord) => cells[coord.$1][coord.$2]).toList();
  }

  /// 获取指定坐标所属的区域ID
  ///
  /// 性能：O(1) - 直接数组访问
  int getRegionIdAt(int row, int col) {
    if (regionMatrix == null) return -1;
    if (row < 0 || row >= size || col < 0 || col >= size) return -1;
    return regionMatrix![row][col];
  }

  @override
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) {
    if (_cachedRegions != null) {
      return _cachedRegions!;
    }

    final regions = createDefaultRegions();

    if (regionMatrix != null) {
      // 使用缓存的坐标创建区域，避免重复遍历
      for (int regionId = 0; regionId < size; regionId++) {
        final coordinates = getRegionCellCoordinates(regionId);
        final regionCells = coordinates
            .map((coord) => cells[coord.$1][coord.$2])
            .toList();

        if (regionCells.isNotEmpty) {
          regions.add(
            Region(
              id: 'jigsaw_$regionId',
              type: RegionType.jigsaw,
              name: 'Jigsaw $regionId',
              cells: regionCells,
            ),
          );
        }
      }
    }

    _cachedRegions = regions;
    return regions;
  }

  @override
  JigsawBoard createInstance(
    List<List<Cell>> newCells, {
    List<Region>? regions,
  }) => JigsawBoard(
      size: size,
      cells: newCells,
      regions: regions,
      regionMatrix: regionMatrix,
      // 注意：不传递 _regionIndexCache 和 _cachedRegions
      // 因为 cells 已改变，需要重新构建
    );

  static JigsawBoard empty({int size = 9, List<List<int>>? regionMatrix}) {
    final cells = List<List<Cell>>.generate(
      size,
      (i) => List<Cell>.generate(size, (j) => Cell(row: i, col: j)),
    );
    return JigsawBoard(
      size: size,
      cells: cells,
      regionMatrix: regionMatrix,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells
        .map((row) => row.map((cell) => cell.toJson()).toList())
        .toList(),
    'regions': regions.map((region) => region.toJson()).toList(),
    'regionMatrix': regionMatrix,
  };
}

/// 杀手数独棋盘
class KillerBoard extends Board {
  KillerBoard({
    required int size,
    required List<List<Cell>> cells,
    List<Region>? regions,
    List<KillerCage>? cages,
  }) : cages = cages ?? [],
       super(
         size: size,
         cells: cells,
         regions: regions,
       );

  @override
  String get gameType => 'killer';

  factory KillerBoard.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final cellsJson = json['cells'] as List;
    final cells = cellsJson.map((row) {
      final rowList = row as List;
      return rowList
          .map((cellJson) => Cell.fromJson(cellJson as Map<String, dynamic>))
          .toList();
    }).toList();

    final regionsJson = json['regions'] as List?;
    List<Region>? regions;
    if (regionsJson != null && regionsJson.isNotEmpty) {
      regions = regionsJson.map(
            (regionJson) => Region.fromJson(regionJson as Map<String, dynamic>),
          )
          .toList();
    }

    final cagesJson = json['cages'] as List?;
    final cages = cagesJson
        ?.map(
          (cageJson) => KillerCage.fromJson(cageJson as Map<String, dynamic>),
        )
        .toList() ?? [];

    final board = KillerBoard(size: size, cells: cells, regions: regions, cages: cages);
    // 如果没有区域信息，生成区域
    if (regions == null || regions.isEmpty) {
      final generatedRegions = board.createRegions();
      return KillerBoard(size: size, cells: cells, regions: generatedRegions, cages: cages);
    }

    return board;
  }
  final List<KillerCage> cages;
  
  // Cage查找缓存 - 提升性能
  Map<String, KillerCage>? _cageLookupCache;
  int? _cageLookupCacheHash;

  @override
  KillerBoard createInstance(
    List<List<Cell>> newCells, {
    List<Region>? regions,
  }) => KillerBoard(
      size: size,
      cells: newCells,
      regions: regions,
      cages: cages,
    );

  @override
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) {
    final regions = createDefaultRegions()
    ..addAll(createBlockRegions());
    
    // 添加笼子区域
    for (final cage in cages) {
      final cageCells = <Cell>[];
      for (final (row, col) in cage.cellCoordinates) {
        if (row >= 0 && row < size && col >= 0 && col < size) {
          cageCells.add(cells[row][col]);
        }
      }
      if (cageCells.isNotEmpty) {
        regions.add(Region(
          id: 'cage_${cage.id}',
          type: RegionType.cage,
          name: 'Cage ${cage.sum}',
          cells: cageCells,
        ));
      }
    }
    
    return regions;
  }

  static KillerBoard empty({int size = 9}) {
    final cells = List<List<Cell>>.generate(
      size,
      (i) => List<Cell>.generate(size, (j) => Cell(row: i, col: j)),
    );
    final board = KillerBoard(size: size, cells: cells);
    return KillerBoard(size: size, cells: cells, regions: board.createRegions());
  }

  @override
  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    'regions': regions.map((region) => region.toJson()).toList(),
    'cages': cages.map((cage) => cage.toJson()).toList(),
  };

  KillerCage? getCageForCell(int row, int col) {
    // 使用缓存优化
    final cacheKey = '$row,$col';
    
    // 检查缓存是否需要重建
    final currentHash = Object.hashAll(cages.map((c) => c.id));
    if (_cageLookupCache == null || _cageLookupCacheHash != currentHash) {
      _buildCageLookupCache();
      _cageLookupCacheHash = currentHash;
    }
    
    return _cageLookupCache?[cacheKey];
  }
  
  /// 构建cage查找缓存
  void _buildCageLookupCache() {
    _cageLookupCache = <String, KillerCage>{};
    for (final cage in cages) {
      for (final coord in cage.cellCoordinates) {
        final key = '${coord.$1},${coord.$2}';
        _cageLookupCache![key] = cage;
      }
    }
  }

  /// 获取棋盘状态哈希值，用于缓存优化
  int get stateHash {
    var hash = 0;
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        final cell = cells[i][j];
        if (cell.value != null) {
          hash = hash * 31 + cell.value! + i * 9 + j;
        }
        if (cell.isSelected) {
          hash = hash * 31 + 1000 + i * 9 + j;
        }
        if (cell.isHighlighted) {
          hash = hash * 31 + 2000 + i * 9 + j;
        }
        if (cell.isFixed) {
          hash = hash * 31 + 3000 + i * 9 + j;
        }
        if (cell.isError) {
          hash = hash * 31 + 4000 + i * 9 + j;
        }
        for (final candidate in cell.candidates) {
          hash = hash * 31 + 5000 + candidate + i * 9 + j;
        }
      }
    }
    return hash;
  }

  /// 获取所有笼子的验证状态
  Map<String, bool> getCagesValidationStatus() {
    final result = <String, bool>{};
    for (final cage in cages) {
      result[cage.id] = cage.isValid(this);
    }
    return result;
  }

  /// 检查所有笼子是否都有效
  bool get areAllCagesValid {
    for (final cage in cages) {
      if (!cage.isValid(this)) return false;
    }
    return true;
  }

  /// 重写选择指定单元格，修改高亮逻辑，删除后半条规则
  @override
  Board selectCell(final int row, final int col) {
    final newCells = cells
        .map(
          (final r) => r
              .map(
                (final c) => c.copyWith(
                  isSelected: c.row == row && c.col == col,
                  isHighlighted: false,
                ),
              )
              .toList(),
        )
        .toList();

    final selectedCell = newCells[row][col];
    final finalCells = newCells
        .map(
          (final r) => r
              .map(
                (final c) {
                  bool isHighlighted = false;
                  if (selectedCell.value != null) {
                    isHighlighted = c.value != null &&
                        c.value == selectedCell.value &&
                        c.row != row &&
                        c.col != col;
                  }
                  return c.copyWith(isHighlighted: isHighlighted);
                },
              )
              .toList(),
        )
        .toList();

    final newRegions = regions.map((region) {
      final newRegionCells = region.cells
          .map((c) => finalCells[c.row][c.col])
          .toList();
      return Region(
        id: region.id,
        type: region.type,
        name: region.name,
        cells: newRegionCells,
      );
    }).toList();

    return createInstance(finalCells, regions: newRegions);
  }
}

/// 武士数独棋盘
class SamuraiBoard extends Board {
  factory SamuraiBoard({
    required List<List<Cell>> cells,
    List<Region>? regions,
  }) {
    regions ??= _createRegions(cells);
    return SamuraiBoard._internal(cells: cells, regions: regions);
  }

  @override
  String get gameType => 'samurai';

  factory SamuraiBoard.fromJson(Map<String, dynamic> json) {
    final cellsJson = json['cells'] as List;
    final cells = cellsJson.map((row) => (row as List).map((cellJson) => Cell.fromJson(cellJson)).toList()).toList();

    final regionsJson = json['regions'] as List?;
    if (regionsJson != null && regionsJson.isNotEmpty) {
      final regions = regionsJson.map((r) => Region.fromJson(r)).toList();
      return SamuraiBoard(cells: cells, regions: regions);
    }
    return SamuraiBoard(cells: cells); // 自动生成 regions
  }

  SamuraiBoard._internal({
    required List<List<Cell>> cells,
    required List<Region> regions,
  })  : assert(regions.isNotEmpty, 'Regions must not be empty'),
       super(
         size: boardSize,
         cells: cells,
         regions: regions,
       );
  static const int boardSize = 21;
  static const int subGridSize = 9;

  // 缓存空单元格和已填单元格列表，避免每次遍历 441 个单元格
  List<Cell>? _emptyCellsCache;
  List<Cell>? _filledCellsCache;
  bool _cacheDirty = true;

  /// 标记缓存为脏，在单元格变更后调用
  void invalidateCache() {
    _cacheDirty = true;
    _emptyCellsCache = null;
    _filledCellsCache = null;
  }

  /// 子网格偏移量（引用 SamuraiConstants）
  static List<(int, int)> get subGridOffsets => SamuraiConstants.subGridOffsets;

  static List<Region> _createRegions(List<List<Cell>> cells) {
    final regions = <Region>[];
    for (int i = 0; i < 5; i++) {
      final (startRow, startCol) = subGridOffsets[i];
      regions.addAll(_createSubGridRegions(cells, startRow, startCol, i));
    }
    assert(regions.length == 135, 'Expected 135 regions, got ${regions.length}');
    return regions;
  }

  static List<Region> _createSubGridRegions(
      List<List<Cell>> cells, int startRow, int startCol, int subGridIndex) {
    final regions = <Region>[];

    // 行区域（使用全局坐标）
    for (int row = 0; row < subGridSize; row++) {
      final rowCells = <Cell>[];
      for (int col = 0; col < subGridSize; col++) {
        rowCells.add(cells[startRow + row][startCol + col]);
      }
      regions.add(Region(
        id: 'subgrid_${subGridIndex}_row_$row',
        type: RegionType.row,
        name: 'SubGrid $subGridIndex Row $row',
        cells: rowCells,
      ));
    }

    // 列区域
    for (int col = 0; col < subGridSize; col++) {
      final colCells = <Cell>[];
      for (int row = 0; row < subGridSize; row++) {
        colCells.add(cells[startRow + row][startCol + col]);
      }
      regions.add(Region(
        id: 'subgrid_${subGridIndex}_col_$col',
        type: RegionType.column,
        name: 'SubGrid $subGridIndex Column $col',
        cells: colCells,
      ));
    }

    // 宫区域
    for (int blockRow = 0; blockRow < 3; blockRow++) {
      for (int blockCol = 0; blockCol < 3; blockCol++) {
        final blockCells = <Cell>[];
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            blockCells.add(cells[startRow + blockRow * 3 + i][startCol + blockCol * 3 + j]);
          }
        }
        regions.add(Region(
          id: 'subgrid_${subGridIndex}_block_${blockRow}_$blockCol',
          type: RegionType.block,
          name: 'SubGrid $subGridIndex Block ${blockRow}_$blockCol',
          cells: blockCells,
        ));
      }
    }

    return regions;
  }

  @override
  SamuraiBoard createInstance(
    List<List<Cell>> newCells, {
    List<Region>? regions,
  }) => SamuraiBoard(cells: newCells, regions: regions);

  @override
  int getMaxNumber() => 9;

  @override
  List<Region> createRegions({
    Map<String, dynamic>? templateData,
  }) => _createRegions(cells);

  List<int> getSubGridsForCell(int row, int col) {
    final subGrids = <int>[];
    for (int i = 0; i < 5; i++) {
      final (startRow, startCol) = subGridOffsets[i];
      if (row >= startRow && row < startRow + subGridSize &&
          col >= startCol && col < startCol + subGridSize) {
        subGrids.add(i);
      }
    }
    return subGrids;
  }

  bool isOverlapRegion(int row, int col) => getSubGridsForCell(row, col).length > 1;

  /// 检查单元格是否在可玩区域内（任意子网格中）
  bool isPlayableCell(int row, int col) => getSubGridsForCell(row, col).isNotEmpty;

  /// 获取所有可玩区域内的空单元格
  @override
  List<Cell> getEmptyCells() {
    if (!_cacheDirty && _emptyCellsCache != null) {
      return _emptyCellsCache!;
    }

    final emptyCells = <Cell>[];
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (isPlayableCell(row, col)) {
          final cell = cells[row][col];
          if (cell.isEmpty) {
            emptyCells.add(cell);
          }
        }
      }
    }
    _emptyCellsCache = emptyCells;
    _cacheDirty = false;
    return emptyCells;
  }

  /// 获取所有可玩区域内已填单元格
  @override
  List<Cell> getFilledCells() {
    if (!_cacheDirty && _filledCellsCache != null) {
      return _filledCellsCache!;
    }

    final filledCells = <Cell>[];
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (isPlayableCell(row, col)) {
          final cell = cells[row][col];
          if (!cell.isEmpty) {
            filledCells.add(cell);
          }
        }
      }
    }
    _filledCellsCache = filledCells;
    _cacheDirty = false;
    return filledCells;
  }

  /// 检查棋盘是否完整（所有可玩单元格已填）
  @override
  bool isComplete() => getEmptyCells().isEmpty;

  /// 获取可玩单元格总数
  int get playableCellCount {
    int count = 0;
    for (int row = 0; row < boardSize; row++) {
      for (int col = 0; col < boardSize; col++) {
        if (isPlayableCell(row, col)) {
          count++;
        }
      }
    }
    return count;
  }

  SamuraiBoard mergeSubBoard(Board subBoard, int startRow, int startCol) {
    final newCells = cells.map(List<Cell>.from).toList();
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final targetRow = startRow + i;
        final targetCol = startCol + j;
        if (targetRow >= 0 && targetRow < boardSize &&
            targetCol >= 0 && targetCol < boardSize) {
          final subCell = subBoard.getCell(i, j);
          if (subCell.value != null) {
            newCells[targetRow][targetCol] = newCells[targetRow][targetCol].copyWith(
              value: subCell.value,
              isFixed: true,
            );
          }
        }
      }
    }
    return SamuraiBoard(cells: newCells, regions: regions);
  }

  /// 获取指定索引的子网格
  Board getSubBoard(int index) {
    if (index < 0 || index >= 5) {
      throw ArgumentError('Subgrid index must be between 0 and 4');
    }

    final (startRow, startCol) = subGridOffsets[index];
    final subGridCells = List.generate(subGridSize, (i) =>
      List.generate(subGridSize, (j) {
        final original = cells[startRow + i][startCol + j];
        // 创建新 Cell，坐标映射到 0..8
        return Cell(
          row: i,
          col: j,
          value: original.value,
          isFixed: original.isFixed,
          candidates: original.candidates,
          isSelected: original.isSelected,
          isError: original.isError,
        );
      }));

    // 创建一个标准数独板作为子网格
    return StandardBoard(size: subGridSize, cells: subGridCells);
  }

  static SamuraiBoard empty() {
    final cells = List.generate(boardSize, (i) => List.generate(boardSize, (j) => Cell(row: i, col: j)));
    return SamuraiBoard(cells: cells);
  }

  @override
  Map<String, dynamic> toJson() => {
    'size': size,
    'cells': cells.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    'regions': regions.map((region) => region.toJson()).toList(),
  };
}
