import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/strategy_engine.dart';

/// 裸单策略
base class NakedSingleStrategy extends Strategy {
  const NakedSingleStrategy();

  @override
  StrategyType get type => StrategyType.nakedSingle;

  @override
  StrategyLevel get level => StrategyLevel.basic;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    bool changed = false;
    final n = context.size;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (context.cellValue(r, c) != null) continue;
        final candidates = context.getCandidates(r, c);
        if (candidates.length == 1) {
          final num = candidates.first;
          // 从所有相关区域中移除该数字
          for (final regIdx in context.cellToRegions[r][c]) {
            final region = context.getRegion(regIdx);
            if (region.cells.length != context.board.getMaxNumber()) {
              continue; // 只处理大小为9的区域
            }
            for (final cell in region.cells) {
              final cr = cell.row;
              final cc = cell.col;
              if (cr == r && cc == c) continue;
              if (context.cellValue(cr, cc) != null) continue;
              if (context.hasCandidate(cr, cc, num)) {
                context.removeCandidate(cr, cc, num);
                changed = true;
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// 隐单策略
base class HiddenSingleStrategy extends Strategy {
  const HiddenSingleStrategy();

  @override
  StrategyType get type => StrategyType.hiddenSingle;

  @override
  StrategyLevel get level => StrategyLevel.basic;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    bool changed = false;

    // 只处理1到maxNumber之间的数字
    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      for (
        int regIdx = 0;
        regIdx < context.regionCellIndices.length;
        regIdx++
      ) {
        // 只处理大小为9的区域（行、列、宫、对角线等）
        final region = context.getRegion(regIdx);
        if (region.cells.length != maxNumber) continue;

        int count = 0;
        Cell? lastCell;

        // 遍历区域内的所有单元格，统计候选位置
        for (final cell in region.cells) {
          final cellValue = context.cellValue(cell.row, cell.col);
          // 如果数字已填入该区域，跳过
          if (cellValue == num) {
            count = 0;
            break;
          }
          // 统计候选位置
          if (cellValue == null &&
              context.hasCandidate(cell.row, cell.col, num)) {
            count++;
            lastCell = cell;
            if (count > 1) break;
          }
        }

        // 如果只有一个候选位置，设置为该数字
        if (count == 1 && lastCell != null) {
          final r = lastCell.row;
          final c = lastCell.col;
          final currentCandidates = context.getCandidates(r, c).toSet();
          if (currentCandidates.length != 1 ||
              !currentCandidates.contains(num)) {
            // 将该单元格的候选数设置为只包含这个数字
            context.setCandidates(r, c, {num});
            changed = true;
          }
        }
      }
    }
    return changed;
  }
}

/// 裸双策略
base class NakedPairStrategy extends Strategy {
  const NakedPairStrategy();

  @override
  StrategyType get type => StrategyType.nakedPair;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    bool changed = false;

    for (int regIdx = 0; regIdx < context.regionCellIndices.length; regIdx++) {
      // 只处理大小为9的区域（行、列、宫、对角线等）
      final region = context.getRegion(regIdx);
      if (region.cells.length != context.board.getMaxNumber()) continue;

      // 实时获取候选集，不使用快照
      final cellsWithCandidates = <Cell>[];
      for (final cell in region.cells) {
        if (context.getCandidates(cell.row, cell.col).isNotEmpty) {
          cellsWithCandidates.add(cell);
        }
      }

      for (int i = 0; i < cellsWithCandidates.length - 1; i++) {
        for (int j = i + 1; j < cellsWithCandidates.length; j++) {
          final cell1 = cellsWithCandidates[i];
          final cell2 = cellsWithCandidates[j];

          // 实时获取候选集
          final candidates1 = context
              .getCandidates(cell1.row, cell1.col)
              .toSet();
          final candidates2 = context
              .getCandidates(cell2.row, cell2.col)
              .toSet();

          // 裸双：两个单元格候选数完全相同且大小为2
          if (candidates1.length == 2 && candidates1 == candidates2) {
            for (final cell in region.cells) {
              if (cell == cell1 || cell == cell2) continue;
              final oldCandidates = context
                  .getCandidates(cell.row, cell.col)
                  .toSet();
              final newCandidates = oldCandidates.difference(candidates1);
              if (newCandidates.length != oldCandidates.length && newCandidates.isNotEmpty) {
                context.setCandidates(cell.row, cell.col, newCandidates);
                changed = true;
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// 隐对策略
base class HiddenPairStrategy extends Strategy {
  const HiddenPairStrategy();

  @override
  StrategyType get type => StrategyType.hiddenPair;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    bool changed = false;

    for (int regIdx = 0; regIdx < context.regionCellIndices.length; regIdx++) {
      // 只处理大小为9的区域（行、列、宫、对角线等）
      final region = context.getRegion(regIdx);
      if (region.cells.length != context.board.getMaxNumber()) continue;

      // 遍历所有可能的数字对（共36对）
      final maxNumber = context.board.getMaxNumber();
      for (int num1 = 1; num1 <= maxNumber - 1; num1++) {
        for (int num2 = num1 + 1; num2 <= maxNumber; num2++) {
          // 实时检查这两个数字的位置
          final cellsForNum1 = <Cell>[];
          final cellsForNum2 = <Cell>[];

          for (final cell in region.cells) {
            if (context.hasCandidate(cell.row, cell.col, num1)) {
              cellsForNum1.add(cell);
            }
            if (context.hasCandidate(cell.row, cell.col, num2)) {
              cellsForNum2.add(cell);
            }
          }

          // 检查两个数字是否恰好出现在相同的两个格子中
          if (cellsForNum1.length == 2 && cellsForNum1.toSet() == cellsForNum2.toSet()) {
            final pair = {num1, num2};

            // 设置这两个格子的候选数为这对数字
            for (final cell in cellsForNum1) {
              final currentCandidates = context
                  .getCandidates(cell.row, cell.col)
                  .toSet();
              if (currentCandidates != pair) {
                context.setCandidates(cell.row, cell.col, pair);
                changed = true;
              }
            }

            // 从区域内的其他格子中删除这些数字
            for (final cell in region.cells) {
              if (cellsForNum1.contains(cell)) continue;
              final currentCandidates = context
                  .getCandidates(cell.row, cell.col)
                  .toSet();
              final newCandidates = currentCandidates.difference(pair);
              if (newCandidates.length != currentCandidates.length && newCandidates.isNotEmpty) {
                context.setCandidates(cell.row, cell.col, newCandidates);
                changed = true;
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// 裸三数集策略
base class NakedTripleStrategy extends Strategy {
  const NakedTripleStrategy();

  @override
  StrategyType get type => StrategyType.nakedTriple;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    bool changed = false;

    for (int regIdx = 0; regIdx < context.regionCellIndices.length; regIdx++) {
      // 只处理大小为9的区域（行、列、宫、对角线等）
      final region = context.getRegion(regIdx);
      if (region.cells.length != context.board.getMaxNumber()) continue;

      // 实时获取候选集，只包含候选数个数≤3的单元格
      final cellsWithCandidates = <Cell>[];
      for (final cell in region.cells) {
        final candidates = context.getCandidates(cell.row, cell.col);
        if (candidates.isNotEmpty && candidates.length <= 3) {
          cellsWithCandidates.add(cell);
        }
      }

      for (int i = 0; i < cellsWithCandidates.length - 2; i++) {
        for (int j = i + 1; j < cellsWithCandidates.length - 1; j++) {
          for (int k = j + 1; k < cellsWithCandidates.length; k++) {
            final cell1 = cellsWithCandidates[i];
            final cell2 = cellsWithCandidates[j];
            final cell3 = cellsWithCandidates[k];

            // 实时获取候选集
            final candidates1 = context
                .getCandidates(cell1.row, cell1.col)
                .toSet();
            final candidates2 = context
                .getCandidates(cell2.row, cell2.col)
                .toSet();
            final candidates3 = context
                .getCandidates(cell3.row, cell3.col)
                .toSet();

            final union = <int>{...candidates1, ...candidates2, ...candidates3};
            // 裸三：并集大小为3，且每个单元格的候选数都是并集的子集
            if (union.length == 3 &&
                union.containsAll(candidates1) &&
                union.containsAll(candidates2) &&
                union.containsAll(candidates3)) {
              for (final cell in region.cells) {
                if (cell == cell1 || cell == cell2 || cell == cell3) continue;
                final oldCandidates = context
                    .getCandidates(cell.row, cell.col)
                    .toSet();
                final newCandidates = oldCandidates.difference(union);
                if (newCandidates.length != oldCandidates.length && newCandidates.isNotEmpty) {
                  context.setCandidates(cell.row, cell.col, newCandidates);
                  changed = true;
                }
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// 隐三数集策略
base class HiddenTripleStrategy extends Strategy {
  const HiddenTripleStrategy();

  @override
  StrategyType get type => StrategyType.hiddenTriple;

  @override
  StrategyLevel get level => StrategyLevel.advanced;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    bool changed = false;

    for (int regIdx = 0; regIdx < context.regionCellIndices.length; regIdx++) {
      // 只处理大小为9的区域（行、列、宫、对角线等）
      final region = context.getRegion(regIdx);
      if (region.cells.length != context.board.getMaxNumber()) continue;

      // 遍历所有可能的数字三元组
      final maxNumber = context.board.getMaxNumber();
      for (int num1 = 1; num1 <= maxNumber - 2; num1++) {
        for (int num2 = num1 + 1; num2 <= maxNumber - 1; num2++) {
          for (int num3 = num2 + 1; num3 <= maxNumber; num3++) {
            // 实时检查这三个数字的位置
            final cellsForNum1 = <Cell>[];
            final cellsForNum2 = <Cell>[];
            final cellsForNum3 = <Cell>[];

            for (final cell in region.cells) {
              if (context.hasCandidate(cell.row, cell.col, num1)) {
                cellsForNum1.add(cell);
              }
              if (context.hasCandidate(cell.row, cell.col, num2)) {
                cellsForNum2.add(cell);
              }
              if (context.hasCandidate(cell.row, cell.col, num3)) {
                cellsForNum3.add(cell);
              }
            }

            // 检查三个数字是否都有至少一个候选位置
            if (cellsForNum1.isEmpty || cellsForNum2.isEmpty || cellsForNum3.isEmpty) {
              continue;
            }

            // 收集所有出现这三个数字的格子
            final allCells = <Cell>{}..addAll(cellsForNum1)..addAll(cellsForNum2)..addAll(cellsForNum3);

            // 隐三定义：三个数字的候选位置总共出现在三个格子中
            if (allCells.length == 3) {
              final triple = {num1, num2, num3};

              // 设置这三个格子的候选数为这三个数字的交集
              for (final cell in allCells) {
                final oldCandidates = context
                    .getCandidates(cell.row, cell.col)
                    .toSet();
                final newCandidates = oldCandidates.intersection(triple);
                if (newCandidates.isNotEmpty && newCandidates != oldCandidates) {
                  context.setCandidates(cell.row, cell.col, newCandidates);
                  changed = true;
                }
              }

              // 从区域内的其他格子中删除这些数字
              for (final cell in region.cells) {
                if (allCells.contains(cell)) continue;
                final currentCandidates = context
                    .getCandidates(cell.row, cell.col)
                    .toSet();
                final newCandidates = currentCandidates.difference(triple);
                if (newCandidates != currentCandidates) {
                  context.setCandidates(cell.row, cell.col, newCandidates);
                  changed = true;
                }
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// 锁定候选数策略
base class LockedCandidateStrategy extends Strategy {
  const LockedCandidateStrategy();

  @override
  StrategyType get type => StrategyType.lockedCandidate;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalBlocks) return false;
    bool changed = false;
    final n = context.size;

    // 查找所有宫格区域的索引
    final blockRegionIndices = <int>[];
    for (int i = 0; i < context.board.regions.length; i++) {
      if (context.board.regions[i].type == RegionType.block) {
        blockRegionIndices.add(i);
      }
    }

    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      for (final boxIdx in blockRegionIndices) {
        final region = context.getRegion(boxIdx);

        // 检查该数字是否已经在宫格中被填入
        bool numAlreadyFilled = false;
        for (final cell in region.cells) {
          if (context.cellValue(cell.row, cell.col) == num) {
            numAlreadyFilled = true;
            break;
          }
        }
        if (numAlreadyFilled) continue;

        final rowsInBox = <int>{};
        final colsInBox = <int>{};

        for (final cell in region.cells) {
          if (context.hasCandidate(cell.row, cell.col, num)) {
            rowsInBox.add(cell.row);
            colsInBox.add(cell.col);
          }
        }

        if (rowsInBox.length == 1) {
          final row = rowsInBox.first;
          // 获取当前宫格区域的所有列
          final boxCols = <int>{};
          for (final cell in region.cells) {
            boxCols.add(cell.col);
          }
          for (int c = 0; c < n; c++) {
            if (boxCols.contains(c)) continue;
            // 检查目标单元格是否为空
            if (context.cellValue(row, c) != null) continue;
            // 检查目标单元格是否有该候选数
            if (context.hasCandidate(row, c, num)) {
              // 验证移除后不会导致候选数为空
              final currentCandidates = context.getCandidates(row, c).toSet();
              if (currentCandidates.length > 1) {
                context.removeCandidate(row, c, num);
                changed = true;
              }
            }
          }
        }

        if (colsInBox.length == 1) {
          final col = colsInBox.first;
          // 获取当前宫格区域的所有行
          final boxRows = <int>{};
          for (final cell in region.cells) {
            boxRows.add(cell.row);
          }
          for (int r = 0; r < n; r++) {
            if (boxRows.contains(r)) continue;
            // 检查目标单元格是否为空
            if (context.cellValue(r, col) != null) continue;
            // 检查目标单元格是否有该候选数
            if (context.hasCandidate(r, col, num)) {
              // 验证移除后不会导致候选数为空
              final currentCandidates = context.getCandidates(r, col).toSet();
              if (currentCandidates.length > 1) {
                context.removeCandidate(r, col, num);
                changed = true;
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// X-Wing策略
base class XWingStrategy extends Strategy {
  const XWingStrategy();

  @override
  StrategyType get type => StrategyType.xWing;

  @override
  StrategyLevel get level => StrategyLevel.expert;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns) return false;
    bool changed = false;
    final n = context.size;

    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < n; r++) {
        final positions = <int>[];
        for (int c = 0; c < n; c++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(c);
          }
        }
        if (positions.length == 2) {
          rowPositions[r] = positions;
        }
      }

      final rows = rowPositions.keys.toList();
      for (int i = 0; i < rows.length - 1; i++) {
        for (int j = i + 1; j < rows.length; j++) {
          final r1 = rows[i];
          final r2 = rows[j];
          if (rowPositions[r1]![0] == rowPositions[r2]![0] &&
              rowPositions[r1]![1] == rowPositions[r2]![1]) {
            final c1 = rowPositions[r1]![0];
            final c2 = rowPositions[r1]![1];
            for (int r = 0; r < n; r++) {
              if (r == r1 || r == r2) continue;
              if (_safeRemoveCandidate(context, r, c1, num)) {
                changed = true;
              }
              if (_safeRemoveCandidate(context, r, c2, num)) {
                changed = true;
              }
            }
          }
        }
      }

      final colPositions = <int, List<int>>{};
      for (int c = 0; c < n; c++) {
        final positions = <int>[];
        for (int r = 0; r < n; r++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(r);
          }
        }
        if (positions.length == 2) {
          colPositions[c] = positions;
        }
      }

      final cols = colPositions.keys.toList();
      for (int i = 0; i < cols.length - 1; i++) {
        for (int j = i + 1; j < cols.length; j++) {
          final c1 = cols[i];
          final c2 = cols[j];
          if (colPositions[c1]![0] == colPositions[c2]![0] &&
              colPositions[c1]![1] == colPositions[c2]![1]) {
            final r1 = colPositions[c1]![0];
            final r2 = colPositions[c1]![1];
            for (int c = 0; c < n; c++) {
              if (c == c1 || c == c2) continue;
              if (_safeRemoveCandidate(context, r1, c, num)) {
                changed = true;
              }
              if (_safeRemoveCandidate(context, r2, c, num)) {
                changed = true;
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// Swordfish策略
base class SwordfishStrategy extends Strategy {
  const SwordfishStrategy();

  @override
  StrategyType get type => StrategyType.swordfish;

  @override
  StrategyLevel get level => StrategyLevel.expert;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns) return false;
    bool changed = false;
    final n = context.size;

    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < n; r++) {
        final positions = <int>[];
        for (int c = 0; c < n; c++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(c);
          }
        }
        if (positions.length >= 2 && positions.length <= 3) {
          rowPositions[r] = positions;
        }
      }

      final rows = rowPositions.keys.toList();
      for (int i = 0; i < rows.length - 2; i++) {
        for (int j = i + 1; j < rows.length - 1; j++) {
          for (int k = j + 1; k < rows.length; k++) {
            final r1 = rows[i];
            final r2 = rows[j];
            final r3 = rows[k];
            final cols = <int>{
              ...rowPositions[r1]!,
              ...rowPositions[r2]!,
              ...rowPositions[r3]!,
            };
            
            if (cols.length == 3) {
              // 检查每个列在三行中出现的次数，标准剑鱼要求每个列至少出现2次
              final colCounts = <int, int>{};
              for (final c in rowPositions[r1]!) {
                colCounts[c] = (colCounts[c] ?? 0) + 1;
              }
              for (final c in rowPositions[r2]!) {
                colCounts[c] = (colCounts[c] ?? 0) + 1;
              }
              for (final c in rowPositions[r3]!) {
                colCounts[c] = (colCounts[c] ?? 0) + 1;
              }
              
              // 验证每个列至少出现2次
              bool validSwordfish = true;
              for (final c in cols) {
                if ((colCounts[c] ?? 0) < 2) {
                  validSwordfish = false;
                  break;
                }
              }
              
              if (validSwordfish) {
                for (int r = 0; r < n; r++) {
                  if (r == r1 || r == r2 || r == r3) continue;
                  for (final c in cols) {
                    if (_safeRemoveCandidate(context, r, c, num)) {
                      changed = true;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    return changed;
  }
}

/// 检查在指定单元格设置单候选数后，是否会在同一区域内创建重复的单候选数
/// 返回 true 表示会创建重复（不应移除），返回 false 表示可以安全移除
bool _wouldCreateDuplicateSingle(BoardContext context, int r, int c, int num) {
  // 检查该单元格所属的所有区域
  for (final regIdx in context.cellToRegions[r][c]) {
    final region = context.getRegion(regIdx);
    int singleCount = 0;
    
    for (final cell in region.cells) {
      // 跳过当前单元格
      if (cell.row == r && cell.col == c) continue;
      
      // 如果该单元格已有值且等于num，则说明已经存在冲突
      if (context.cellValue(cell.row, cell.col) == num) {
        return true;
      }
      
      // 检查是否已有单候选数等于num
      final candidates = context.getCandidates(cell.row, cell.col).toSet();
      if (candidates.length == 1 && candidates.contains(num)) {
        singleCount++;
        if (singleCount >= 1) {
          return true;
        }
      }
    }
  }
  return false;
}

/// 安全地移除候选数，如果移除后会导致候选数为空或产生冲突，则不移除
bool _safeRemoveCandidate(BoardContext context, int r, int c, int num) {
  final currentCandidates = context.getCandidates(r, c).toSet();
  
  // 如果当前候选数已经只有一个，不移除（避免空白候选）
  if (currentCandidates.length <= 1) {
    return false;
  }
  
  // 如果没有该候选数，不需要移除
  if (!currentCandidates.contains(num)) {
    return false;
  }
  
  final newCandidates = currentCandidates.toSet()..remove(num);
  
  // 如果移除后候选数为空，不移除
  if (newCandidates.isEmpty) {
    return false;
  }
  
  // 如果移除后变成单候选数，检查是否会产生冲突
  if (newCandidates.length == 1) {
    if (_wouldCreateDuplicateSingle(context, r, c, newCandidates.first)) {
      return false;
    }
  }
  
  // 安全移除
  context.removeCandidate(r, c, num);
  return true;
}
