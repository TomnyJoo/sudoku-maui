import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/strategy_engine.dart';

/// 通用可见性判断：两个单元格是否共享至少一个区域
bool _shareRegion(BoardContext context, int r1, int c1, int r2, int c2) {
  if (r1 == r2 || c1 == c2) return true; // 同行或同列必然共享区域
  // 检查是否在任意同一个区域（宫、锯齿、对角线、窗口等）
  for (final regIdx in context.cellToRegions[r1][c1]) {
    if (context.cellToRegions[r2][c2].contains(regIdx)) {
      return true;
    }
  }
  return false;
}

/// Jellyfish策略 - 行列方向，无需宫
base class JellyfishStrategy extends Strategy {
  const JellyfishStrategy();

  @override
  StrategyType get type => StrategyType.jellyfish;

  @override
  StrategyLevel get level => StrategyLevel.advanced;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns) return false;
    bool changed = false;
    final n = context.size;

    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      // 行方向
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < n; r++) {
        final positions = <int>[];
        for (int c = 0; c < n; c++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(c);
          }
        }
        if (positions.length >= 2 && positions.length <= 4) {
          rowPositions[r] = positions;
        }
      }

      final rows = rowPositions.keys.toList();
      for (int i = 0; i < rows.length - 3; i++) {
        for (int j = i + 1; j < rows.length - 2; j++) {
          for (int k = j + 1; k < rows.length - 1; k++) {
            for (int l = k + 1; l < rows.length; l++) {
              final r1 = rows[i];
              final r2 = rows[j];
              final r3 = rows[k];
              final r4 = rows[l];
              final cols = <int>{
                ...rowPositions[r1]!,
                ...rowPositions[r2]!,
                ...rowPositions[r3]!,
                ...rowPositions[r4]!,
              };

              if (cols.length == 4) {
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
                for (final c in rowPositions[r4]!) {
                  colCounts[c] = (colCounts[c] ?? 0) + 1;
                }

                bool validJellyfish = true;
                for (final c in cols) {
                  if ((colCounts[c] ?? 0) < 2) {
                    validJellyfish = false;
                    break;
                  }
                }

                if (validJellyfish) {
                  for (int r = 0; r < n; r++) {
                    if (r == r1 || r == r2 || r == r3 || r == r4) continue;
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

      // 列方向
      final colPositions = <int, List<int>>{};
      for (int c = 0; c < n; c++) {
        final positions = <int>[];
        for (int r = 0; r < n; r++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(r);
          }
        }
        if (positions.length >= 2 && positions.length <= 4) {
          colPositions[c] = positions;
        }
      }

      final colsList = colPositions.keys.toList();
      for (int i = 0; i < colsList.length - 3; i++) {
        for (int j = i + 1; j < colsList.length - 2; j++) {
          for (int k = j + 1; k < colsList.length - 1; k++) {
            for (int l = k + 1; l < colsList.length; l++) {
              final c1 = colsList[i];
              final c2 = colsList[j];
              final c3 = colsList[k];
              final c4 = colsList[l];
              final rowSet = <int>{
                ...colPositions[c1]!,
                ...colPositions[c2]!,
                ...colPositions[c3]!,
                ...colPositions[c4]!,
              };

              if (rowSet.length == 4) {
                final rowCountMap = <int, int>{};
                for (final r in colPositions[c1]!) {
                  rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
                }
                for (final r in colPositions[c2]!) {
                  rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
                }
                for (final r in colPositions[c3]!) {
                  rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
                }
                for (final r in colPositions[c4]!) {
                  rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
                }

                bool validJellyfish = true;
                for (final r in rowSet) {
                  if ((rowCountMap[r] ?? 0) < 2) {
                    validJellyfish = false;
                    break;
                  }
                }

                if (validJellyfish) {
                  for (int c = 0; c < n; c++) {
                    if (c == c1 || c == c2 || c == c3 || c == c4) continue;
                    for (final r in rowSet) {
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
    }
    return changed;
  }
}

/// XY-Wing策略 - 使用泛化区域可见性，适用于所有行列完整的变体
base class XYWingStrategy extends Strategy {
  const XYWingStrategy();

  @override
  StrategyType get type => StrategyType.xyWing;

  @override
  StrategyLevel get level => StrategyLevel.expert;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns) return false;
    bool changed = false;
    final n = context.size;

    final bivalueCells = <(int, int, Set<int>)>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (context.cellValue(r, c) != null) continue;
        final candidates = context.getCandidates(r, c);
        if (candidates.length == 2) {
          bivalueCells.add((r, c, candidates.toSet()));
        }
      }
    }

    // 使用泛化区域检查而非硬编码宫
    bool sees(int r1, int c1, int r2, int c2) =>
        _shareRegion(context, r1, c1, r2, c2);

    for (int bIdx = 0; bIdx < bivalueCells.length; bIdx++) {
      final (br, bc, bCands) = bivalueCells[bIdx];
      final bList = bCands.toList();
      final x = bList[0];
      final y = bList[1];

      for (int aIdx = 0; aIdx < bivalueCells.length; aIdx++) {
        if (aIdx == bIdx) continue;
        final (ar, ac, aCands) = bivalueCells[aIdx];
        if (!sees(ar, ac, br, bc)) continue;
        if (!aCands.contains(x) || aCands.contains(y)) continue;
        final aList = aCands.toList();
        final z = aList[0] == x ? aList[1] : aList[0];

        for (int cIdx = 0; cIdx < bivalueCells.length; cIdx++) {
          if (cIdx == bIdx || cIdx == aIdx) continue;
          final (cr, cc, cCands) = bivalueCells[cIdx];
          if (!sees(cr, cc, br, bc)) continue;
          if (!cCands.contains(y) || cCands.contains(x)) continue;
          if (!cCands.contains(z)) continue;

          for (int r = 0; r < n; r++) {
            for (int c = 0; c < n; c++) {
              if (r == ar && c == ac) continue;
              if (r == br && c == bc) continue;
              if (r == cr && c == cc) continue;
              if (context.cellValue(r, c) != null) continue;
              if (!sees(r, c, ar, ac)) continue;
              if (!sees(r, c, cr, cc)) continue;
              if (_safeRemoveCandidate(context, r, c, z)) {
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

/// XYZ-Wing策略 - 使用泛化区域可见性
base class XYZWingStrategy extends Strategy {
  const XYZWingStrategy();

  @override
  StrategyType get type => StrategyType.xyzWing;

  @override
  StrategyLevel get level => StrategyLevel.expert;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns) return false;
    bool changed = false;
    final n = context.size;

    final bivalueCells = <(int, int, Set<int>)>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (context.cellValue(r, c) != null) continue;
        final candidates = context.getCandidates(r, c);
        if (candidates.length == 2) {
          bivalueCells.add((r, c, candidates.toSet()));
        }
      }
    }

    final trivalueCells = <(int, int, Set<int>)>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (context.cellValue(r, c) != null) continue;
        final candidates = context.getCandidates(r, c);
        if (candidates.length == 3) {
          trivalueCells.add((r, c, candidates.toSet()));
        }
      }
    }

    bool sees(int r1, int c1, int r2, int c2) =>
        _shareRegion(context, r1, c1, r2, c2);

    for (final (ar, ac, aCands) in trivalueCells) {
      for (final (br, bc, bCands) in bivalueCells) {
        if (!sees(ar, ac, br, bc)) continue;
        if (!aCands.containsAll(bCands)) continue;

        for (final (cr, cc, cCands) in bivalueCells) {
          if (br == cr && bc == cc) continue;
          if (!sees(ar, ac, cr, cc)) continue;
          if (!aCands.containsAll(cCands)) continue;

          final commonBC = bCands.intersection(cCands);
          if (commonBC.length != 1) continue;
          final z = commonBC.first;

          final unionBC = bCands.union(cCands);
          if (unionBC != aCands) continue;

          for (int r = 0; r < n; r++) {
            for (int c = 0; c < n; c++) {
              if (r == ar && c == ac) continue;
              if (r == br && c == bc) continue;
              if (r == cr && c == cc) continue;
              if (context.cellValue(r, c) != null) continue;
              if (!sees(r, c, ar, ac)) continue;
              if (!sees(r, c, br, bc)) continue;
              if (!sees(r, c, cr, cc)) continue;
              if (_safeRemoveCandidate(context, r, c, z)) {
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

/// 唯一矩形策略 - 仅适用于标准经典数独
base class UniqueRectangleStrategy extends Strategy {
  const UniqueRectangleStrategy();

  @override
  StrategyType get type => StrategyType.uniqueRectangle;

  @override
  StrategyLevel get level => StrategyLevel.expert;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    // 限制只在 StandardBoard 上执行
    if (context.board is! StandardBoard) return false;

    bool changed = false;
    final n = context.size;

    final pairCells = <(int, int, int, int)>[];
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (context.cellValue(r, c) != null) continue;
        final candidates = context.getCandidates(r, c);
        if (candidates.length == 2) {
          final list = candidates.toList()..sort();
          pairCells.add((r, c, list[0], list[1]));
        }
      }
    }

    final pairMap = <(int, int), List<(int, int)>>{};
    for (final (r, c, a, b) in pairCells) {
      pairMap.putIfAbsent((a, b), () => []).add((r, c));
    }

    for (final entry in pairMap.entries) {
      final cells = entry.value;
      if (cells.length < 3) continue;

      for (int i = 0; i < cells.length - 1; i++) {
        for (int j = i + 1; j < cells.length; j++) {
          final (r1, c1) = cells[i];
          final (r2, c2) = cells[j];
          if (r1 == r2 || c1 == c2) continue;

          final cand12 = context.getCandidates(r1, c2).toSet();
          final cand21 = context.getCandidates(r2, c1).toSet();

          final pair = entry.key;
          final pairSet = {pair.$1, pair.$2};

          if (context.cellValue(r1, c2) != null) continue;
          if (context.cellValue(r2, c1) != null) continue;
          if (!cand12.containsAll(pairSet) || !cand21.containsAll(pairSet)) {
            continue;
          }

          final fourCorners = [
            context.getCandidates(r1, c1).toSet(),
            context.getCandidates(r2, c2).toSet(),
            cand12,
            cand21,
          ];

          int exactPairCount = 0;
          int extraIndex = -1;
          for (int idx = 0; idx < 4; idx++) {
            if (fourCorners[idx] == pairSet) {
              exactPairCount++;
            } else if (fourCorners[idx].length > 2 &&
                pairSet.containsAll(fourCorners[idx].intersection(pairSet))) {
              if (extraIndex == -1) {
                extraIndex = idx;
              } else {
                extraIndex = -2;
              }
            }
          }

          if (exactPairCount == 3 && extraIndex >= 0) {
            int er, ec;
            switch (extraIndex) {
              case 0:
                er = r1;
                ec = c1;
                break;  
              case 1:
                er = r2;
                ec = c2;
                break;  
              case 2:
                er = r1;
                ec = c2;
                break;  
              case 3:
                er = r2;
                ec = c1;
                break;  
              default:
                continue;
            }
            final currentCandidates = context.getCandidates(er, ec).toSet();
            if (currentCandidates.length > 1) {
              final newCandidates = currentCandidates.intersection(pairSet);
              if (newCandidates.length != currentCandidates.length) {
                if (newCandidates.length == 1) {
                  if (!_wouldCreateDuplicateSingle(context, er, ec, newCandidates.first)) {
                    context.setCandidates(er, ec, newCandidates);
                    changed = true;
                  }
                } else {
                  context.setCandidates(er, ec, newCandidates);
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

/// 双串风筝策略 - 依赖标准宫
base class TwoStringKiteStrategy extends Strategy {
  const TwoStringKiteStrategy();

  @override
  StrategyType get type => StrategyType.twoStringKite;

  @override
  StrategyLevel get level => StrategyLevel.master;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns || !context.hasGlobalBlocks) return false;
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

      bool sameBlock(int r1, int c1, int r2, int c2) {
        for (final regIdx in context.cellToRegions[r1][c1]) {
          if (context.getRegionType(regIdx) == RegionType.block) {
            final region = context.getRegion(regIdx);
            if (region.containsCoordinate(r2, c2)) return true;
          }
        }
        return false;
      }

      bool sees(int r1, int c1, int r2, int c2) {
        if (r1 == r2 || c1 == c2) return true;
        return sameBlock(r1, c1, r2, c2);
      }

      for (final rowEntry in rowPositions.entries) {
        final row = rowEntry.key;
        final cols = rowEntry.value;
        final c1 = cols[0];
        final c2 = cols[1];

        for (final colEntry in colPositions.entries) {
          final col = colEntry.key;
          if (col == c1 || col == c2) continue;

          final rows = colEntry.value;
          final r1 = rows[0];
          final r2 = rows[1];

          if (sameBlock(r1, c1, r2, c2)) {
            for (int r = 0; r < n; r++) {
              for (int c = 0; c < n; c++) {
                if (r == r1 && c == c1) continue;
                if (r == r2 && c == c2) continue;
                if (r == row && (c == c1 || c == c2)) continue;
                if (c == col && (r == r1 || r == r2)) continue;
                if (context.cellValue(r, c) != null) continue;
                if (!sees(r, c, r1, c1)) continue;
                if (!sees(r, c, r2, c2)) continue;
                if (_safeRemoveCandidate(context, r, c, num)) {
                  changed = true;
                }
              }
            }
          }

          if (sameBlock(r1, c2, r2, c1)) {
            for (int r = 0; r < n; r++) {
              for (int c = 0; c < n; c++) {
                if (r == r1 && c == c2) continue;
                if (r == r2 && c == c1) continue;
                if (r == row && (c == c1 || c == c2)) continue;
                if (c == col && (r == r1 || r == r2)) continue;
                if (context.cellValue(r, c) != null) continue;
                if (!sees(r, c, r1, c2)) continue;
                if (!sees(r, c, r2, c1)) continue;
                if (_safeRemoveCandidate(context, r, c, num)) {
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

/// 摩天大楼策略 - 依赖标准宫
base class SkyscraperStrategy extends Strategy {
  const SkyscraperStrategy();

  @override
  StrategyType get type => StrategyType.skyscraper;

  @override
  StrategyLevel get level => StrategyLevel.master;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns || !context.hasGlobalBlocks) return false;
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
          final cols1 = rowPositions[r1]!;
          final cols2 = rowPositions[r2]!;

          if (cols1.toSet().intersection(cols2.toSet()).isNotEmpty) continue;

          final combinations = [
            (cols1[0], cols2[0]),
            (cols1[0], cols2[1]),
            (cols1[1], cols2[0]),
            (cols1[1], cols2[1]),
          ];

          for (final (baseCol, topCol) in combinations) {
            bool inSameBlock(int rA, int cA, int rB, int cB) {
              for (final regIdx in context.cellToRegions[rA][cA]) {
                if (context.getRegionType(regIdx) == RegionType.block) {
                  final region = context.getRegion(regIdx);
                  if (region.containsCoordinate(rB, cB)) return true;
                }
              }
              return false;
            }

            if (inSameBlock(r1, baseCol, r2, topCol)) {
              for (final regIdx in context.cellToRegions[r2][topCol]) {
                if (context.getRegionType(regIdx) != RegionType.block) continue;
                final region = context.getRegion(regIdx);
                for (final cell in region.cells) {
                  if (cell.col != baseCol) continue;
                  if (cell.row == r1 && cell.col == baseCol) continue;
                  if (context.cellValue(cell.row, cell.col) != null) continue;
                  if (_safeRemoveCandidate(context, cell.row, cell.col, num)) {
                    changed = true;
                  }
                }
              }

              for (final regIdx in context.cellToRegions[r1][baseCol]) {
                if (context.getRegionType(regIdx) != RegionType.block) continue;
                final region = context.getRegion(regIdx);
                for (final cell in region.cells) {
                  if (cell.col != topCol) continue;
                  if (cell.row == r2 && cell.col == topCol) continue;
                  if (context.cellValue(cell.row, cell.col) != null) continue;
                  if (_safeRemoveCandidate(context, cell.row, cell.col, num)) {
                    changed = true;
                  }
                }
              }
            }
          }
        }
      }

      // 列方向
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
          final rows1 = colPositions[c1]!;
          final rows2 = colPositions[c2]!;

          if (rows1.toSet().intersection(rows2.toSet()).isNotEmpty) continue;

          final combinations = [
            (rows1[0], rows2[0]),
            (rows1[0], rows2[1]),
            (rows1[1], rows2[0]),
            (rows1[1], rows2[1]),
          ];

          for (final (baseRow, topRow) in combinations) {
            bool inSameBlock(int rA, int cA, int rB, int cB) {
              for (final regIdx in context.cellToRegions[rA][cA]) {
                if (context.getRegionType(regIdx) == RegionType.block) {
                  final region = context.getRegion(regIdx);
                  if (region.containsCoordinate(rB, cB)) return true;
                }
              }
              return false;
            }

            if (inSameBlock(baseRow, c1, topRow, c2)) {
              for (final regIdx in context.cellToRegions[topRow][c2]) {
                if (context.getRegionType(regIdx) != RegionType.block) continue;
                final region = context.getRegion(regIdx);
                for (final cell in region.cells) {
                  if (cell.row != baseRow) continue;
                  if (cell.row == baseRow && cell.col == c1) continue;
                  if (context.cellValue(cell.row, cell.col) != null) continue;
                  if (_safeRemoveCandidate(context, cell.row, cell.col, num)) {
                    changed = true;
                  }
                }
              }

              for (final regIdx in context.cellToRegions[baseRow][c1]) {
                if (context.getRegionType(regIdx) != RegionType.block) continue;
                final region = context.getRegion(regIdx);
                for (final cell in region.cells) {
                  if (cell.row != topRow) continue;
                  if (cell.row == topRow && cell.col == c2) continue;
                  if (context.cellValue(cell.row, cell.col) != null) continue;
                  if (_safeRemoveCandidate(context, cell.row, cell.col, num)) {
                    changed = true;
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

/// 空矩形策略 - 依赖标准宫
base class EmptyRectangleStrategy extends Strategy {
  const EmptyRectangleStrategy();

  @override
  StrategyType get type => StrategyType.emptyRectangle;

  @override
  StrategyLevel get level => StrategyLevel.master;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalBlocks) return false;
    bool changed = false;
    final n = context.size;

    // 查找所有block区域
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

        // 收集宫格中num的候选位置
        final candidateCells = <(int, int)>[];
        for (final cell in region.cells) {
          if (context.hasCandidate(cell.row, cell.col, num)) {
            candidateCells.add((cell.row, cell.col));
          }
        }

        if (candidateCells.length < 2) continue;

        // 收集宫格中的行和列
        final boxRows = <int>{};
        final boxCols = <int>{};
        for (final cell in region.cells) {
          boxRows.add(cell.row);
          boxCols.add(cell.col);
        }

        // 收集候选数所在的行和列
        final candRows = <int>{};
        final candCols = <int>{};
        for (final (r, c) in candidateCells) {
          candRows.add(r);
          candCols.add(c);
        }

        // 空矩形模式：宫格中num不在某些行/列形成矩形
        final missingRows = boxRows.difference(candRows);
        final missingCols = boxCols.difference(candCols);

        if (missingRows.length >= 2 && missingCols.length >= 2) {
          final missRowList = missingRows.toList();
          final missColList = missingCols.toList();

          for (int i = 0; i < missRowList.length; i++) {
            for (int j = i + 1; j < missRowList.length; j++) {
              final emptyR1 = missRowList[i];
              final emptyR2 = missRowList[j];

              for (int k = 0; k < missColList.length; k++) {
                for (int l = k + 1; l < missColList.length; l++) {
                  final row1Positions = <int>[];
                  for (int c = 0; c < n; c++) {
                    if (boxCols.contains(c)) continue;
                    if (context.hasCandidate(emptyR1, c, num)) {
                      row1Positions.add(c);
                    }
                  }

                  final row2Positions = <int>[];
                  for (int c = 0; c < n; c++) {
                    if (boxCols.contains(c)) continue;
                    if (context.hasCandidate(emptyR2, c, num)) {
                      row2Positions.add(c);
                    }
                  }

                  if (row1Positions.length == 2 &&
                      row2Positions.length == 2 &&
                      row1Positions.toSet() == row2Positions.toSet()) {
                    for (final c in row1Positions) {
                      for (int r = 0; r < n; r++) {
                        if (r == emptyR1 || r == emptyR2) continue;
                        if (boxRows.contains(r)) continue;
                        if (context.hasCandidate(r, c, num)) {
                          final currentCandidates =
                              context.getCandidates(r, c).toSet();
                          if (currentCandidates.length > 1) {
                            final newCandidates = currentCandidates..remove(num);
                            if (newCandidates.length == 1) {
                              if (!_wouldCreateDuplicateSingle(context, r, c, newCandidates.first)) {
                                context.removeCandidate(r, c, num);
                                changed = true;
                              }
                            } else {
                              context.removeCandidate(r, c, num);
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
          }
        }
      }
    }
    return changed;
  }
}

/// 带鳍X-Wing策略 - 依赖标准宫
base class FinnedXWingStrategy extends Strategy {
  const FinnedXWingStrategy();

  @override
  StrategyType get type => StrategyType.finnedXWing;

  @override
  StrategyLevel get level => StrategyLevel.master;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns || !context.hasGlobalBlocks) return false;
    bool changed = false;
    final n = context.size;

    final blockRegionIndices = <int>[];
    for (int i = 0; i < context.board.regions.length; i++) {
      if (context.board.regions[i].type == RegionType.block) {
        blockRegionIndices.add(i);
      }
    }

    final cellToBlock = <(int, int), int>{};
    for (final boxIdx in blockRegionIndices) {
      final region = context.getRegion(boxIdx);
      for (final cell in region.cells) {
        cellToBlock[(cell.row, cell.col)] = boxIdx;
      }
    }

    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      // 行方向
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < n; r++) {
        final positions = <int>[];
        for (int c = 0; c < n; c++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(c);
          }
        }
        if (positions.length == 2 || positions.length == 3) {
          rowPositions[r] = positions;
        }
      }

      final rows = rowPositions.keys.toList();
      for (int i = 0; i < rows.length - 1; i++) {
        for (int j = i + 1; j < rows.length; j++) {
          final r1 = rows[i];
          final r2 = rows[j];
          final cols1 = rowPositions[r1]!;
          final cols2 = rowPositions[r2]!;

          final commonCols = cols1.toSet().intersection(cols2.toSet());
          if (commonCols.length != 1) continue;

          final baseCol = commonCols.first;
          final fin1 = cols1.where((c) => c != baseCol).toList();
          final fin2 = cols2.where((c) => c != baseCol).toList();

          if (fin1.isEmpty && fin2.length == 1) {
            final finCol = fin2[0];
            final blockOfBase1 = cellToBlock[(r1, baseCol)];
            final blockOfFin = cellToBlock[(r2, finCol)];
            if (blockOfBase1 != null && blockOfBase1 == blockOfFin) {
              for (int r = 0; r < n; r++) {
                if (r == r1 || r == r2) continue;
                final blockOfR = cellToBlock[(r, baseCol)];
                if (blockOfR != null && blockOfR == blockOfBase1) continue;
                if (_safeRemoveCandidate(context, r, baseCol, num)) {
                  changed = true;
                }
              }
            }
          } else if (fin2.isEmpty && fin1.length == 1) {
            final finCol = fin1[0];
            final blockOfBase2 = cellToBlock[(r2, baseCol)];
            final blockOfFin = cellToBlock[(r1, finCol)];
            if (blockOfBase2 != null && blockOfBase2 == blockOfFin) {
              for (int r = 0; r < n; r++) {
                if (r == r1 || r == r2) continue;
                final blockOfR = cellToBlock[(r, baseCol)];
                if (blockOfR != null && blockOfR == blockOfBase2) continue;
                if (_safeRemoveCandidate(context, r, baseCol, num)) {
                  changed = true;
                }
              }
            }
          }
        }
      }

      // 列方向
      final colPositions = <int, List<int>>{};
      for (int c = 0; c < n; c++) {
        final positions = <int>[];
        for (int r = 0; r < n; r++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(r);
          }
        }
        if (positions.length == 2 || positions.length == 3) {
          colPositions[c] = positions;
        }
      }

      final colsList = colPositions.keys.toList();
      for (int i = 0; i < colsList.length - 1; i++) {
        for (int j = i + 1; j < colsList.length; j++) {
          final c1 = colsList[i];
          final c2 = colsList[j];
          final rows1 = colPositions[c1]!;
          final rows2 = colPositions[c2]!;

          final commonRows = rows1.toSet().intersection(rows2.toSet());
          if (commonRows.length != 1) continue;

          final baseRow = commonRows.first;
          final fin1 = rows1.where((r) => r != baseRow).toList();
          final fin2 = rows2.where((r) => r != baseRow).toList();

          if (fin1.isEmpty && fin2.length == 1) {
            final finRow = fin2[0];
            final blockOfBase1 = cellToBlock[(baseRow, c1)];
            final blockOfFin = cellToBlock[(finRow, c2)];
            if (blockOfBase1 != null && blockOfBase1 == blockOfFin) {
              for (int c = 0; c < n; c++) {
                if (c == c1 || c == c2) continue;
                final blockOfC = cellToBlock[(baseRow, c)];
                if (blockOfC != null && blockOfC == blockOfBase1) continue;
                if (_safeRemoveCandidate(context, baseRow, c, num)) {
                  changed = true;
                }
              }
            }
          } else if (fin2.isEmpty && fin1.length == 1) {
            final finRow = fin1[0];
            final blockOfBase2 = cellToBlock[(baseRow, c2)];
            final blockOfFin = cellToBlock[(finRow, c1)];
            if (blockOfBase2 != null && blockOfBase2 == blockOfFin) {
              for (int c = 0; c < n; c++) {
                if (c == c1 || c == c2) continue;
                final blockOfC = cellToBlock[(baseRow, c)];
                if (blockOfC != null && blockOfC == blockOfBase2) continue;
                if (_safeRemoveCandidate(context, baseRow, c, num)) {
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

/// 带鳍Swordfish策略 - 依赖标准宫
base class FinnedSwordfishStrategy extends Strategy {
  const FinnedSwordfishStrategy();

  @override
  StrategyType get type => StrategyType.finnedSwordfish;

  @override
  StrategyLevel get level => StrategyLevel.master;

  @override
  Set<GameType> get applicableGames => GameType.values.toSet();

  @override
  bool apply(BoardContext context) {
    if (!context.hasGlobalRowsAndColumns || !context.hasGlobalBlocks) return false;
    bool changed = false;
    final n = context.size;

    final blockRegionIndices = <int>[];
    for (int i = 0; i < context.board.regions.length; i++) {
      if (context.board.regions[i].type == RegionType.block) {
        blockRegionIndices.add(i);
      }
    }

    final cellToBlock = <(int, int), int>{};
    for (final boxIdx in blockRegionIndices) {
      final region = context.getRegion(boxIdx);
      for (final cell in region.cells) {
        cellToBlock[(cell.row, cell.col)] = boxIdx;
      }
    }

    final maxNumber = context.board.getMaxNumber();
    for (int num = 1; num <= maxNumber; num++) {
      // 行方向
      final rowPositions = <int, List<int>>{};
      for (int r = 0; r < n; r++) {
        final positions = <int>[];
        for (int c = 0; c < n; c++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(c);
          }
        }
        if (positions.length >= 2 && positions.length <= 4) {
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
            final allCols = <int>{
              ...rowPositions[r1]!,
              ...rowPositions[r2]!,
              ...rowPositions[r3]!,
            };

            if (allCols.length < 3 || allCols.length > 4) continue;
            if (allCols.length == 3) continue; // 标准Swordfish已在别处处理

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

            final finCols = <int>[];
            final baseCols = <int>[];
            for (final c in allCols) {
              if ((colCounts[c] ?? 0) == 1) {
                finCols.add(c);
              } else {
                baseCols.add(c);
              }
            }

            if (finCols.length != 1 || baseCols.length != 3) continue;

            final finCol = finCols.first;
            int? finRow;
            if (rowPositions[r1]!.contains(finCol)) {
              finRow = r1;
            } else if (rowPositions[r2]!.contains(finCol)) {
              finRow = r2;
            } else {
              finRow = r3;
            }

            bool validFinned = false;
            int? finBlock;
            for (final baseC in baseCols) {
              final blockOfFin = cellToBlock[(finRow, finCol)];
              final blockOfBase = cellToBlock[(finRow, baseC)];
              if (blockOfFin != null && blockOfBase != null && blockOfFin == blockOfBase) {
                validFinned = true;
                finBlock = blockOfFin;
                break;
              }
            }

            if (!validFinned || finBlock == null) continue;

            for (final c in baseCols) {
              for (int r = 0; r < n; r++) {
                if (r == r1 || r == r2 || r == r3) continue;
                final blockOfR = cellToBlock[(r, c)];
                if (blockOfR != null && blockOfR == finBlock) continue;
                if (_safeRemoveCandidate(context, r, c, num)) {
                  changed = true;
                }
              }
            }
          }
        }
      }

      // 列方向
      final colPositions = <int, List<int>>{};
      for (int c = 0; c < n; c++) {
        final positions = <int>[];
        for (int r = 0; r < n; r++) {
          if (context.hasCandidate(r, c, num)) {
            positions.add(r);
          }
        }
        if (positions.length >= 2 && positions.length <= 4) {
          colPositions[c] = positions;
        }
      }

      final colsList = colPositions.keys.toList();
      for (int i = 0; i < colsList.length - 2; i++) {
        for (int j = i + 1; j < colsList.length - 1; j++) {
          for (int k = j + 1; k < colsList.length; k++) {
            final c1 = colsList[i];
            final c2 = colsList[j];
            final c3 = colsList[k];
            final allRows = <int>{
              ...colPositions[c1]!,
              ...colPositions[c2]!,
              ...colPositions[c3]!,
            };

            if (allRows.length < 3 || allRows.length > 4) continue;
            if (allRows.length == 3) continue;

            final rowCountMap = <int, int>{};
            for (final r in colPositions[c1]!) {
              rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
            }
            for (final r in colPositions[c2]!) {
              rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
            }
            for (final r in colPositions[c3]!) {
              rowCountMap[r] = (rowCountMap[r] ?? 0) + 1;
            }

            final finRows = <int>[];
            final baseRows = <int>[];
            for (final r in allRows) {
              if ((rowCountMap[r] ?? 0) == 1) {
                finRows.add(r);
              } else {
                baseRows.add(r);
              }
            }

            if (finRows.length != 1 || baseRows.length != 3) continue;

            final finRow = finRows.first;
            int? finCol;
            if (colPositions[c1]!.contains(finRow)) {
              finCol = c1;
            } else if (colPositions[c2]!.contains(finRow)) {
              finCol = c2;
            } else {
              finCol = c3;
            }

            bool validFinned = false;
            int? finBlock;
            for (final baseR in baseRows) {
              final blockOfFin = cellToBlock[(finRow, finCol)];
              final blockOfBase = cellToBlock[(baseR, finCol)];
              if (blockOfFin != null && blockOfBase != null && blockOfFin == blockOfBase) {
                validFinned = true;
                finBlock = blockOfFin;
                break;
              }
            }

            if (!validFinned || finBlock == null) continue;

            for (final r in baseRows) {
              for (int c = 0; c < n; c++) {
                if (c == c1 || c == c2 || c == c3) continue;
                final blockOfC = cellToBlock[(r, c)];
                if (blockOfC != null && blockOfC == finBlock) continue;
                if (_safeRemoveCandidate(context, r, c, num)) {
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

/// 检查在指定单元格设置单候选数后，是否会在同一区域内创建重复的单候选数
bool _wouldCreateDuplicateSingle(BoardContext context, int r, int c, int num) {
  for (final regIdx in context.cellToRegions[r][c]) {
    final region = context.getRegion(regIdx);
    int singleCount = 0;
    for (final cell in region.cells) {
      if (cell.row == r && cell.col == c) continue;
      if (context.cellValue(cell.row, cell.col) == num) return true;
      final candidates = context.getCandidates(cell.row, cell.col).toSet();
      if (candidates.length == 1 && candidates.contains(num)) {
        singleCount++;
        if (singleCount >= 1) return true;
      }
    }
  }
  return false;
}

/// 安全地移除候选数
bool _safeRemoveCandidate(BoardContext context, int r, int c, int num) {
  final currentCandidates = context.getCandidates(r, c).toSet();
  if (currentCandidates.length <= 1) return false;
  if (!currentCandidates.contains(num)) return false;
  final newCandidates = currentCandidates.toSet()..remove(num);
  if (newCandidates.isEmpty) return false;
  if (newCandidates.length == 1) {
    if (_wouldCreateDuplicateSingle(context, r, c, newCandidates.first)) {
      return false;
    }
  }
  context.removeCandidate(r, c, num);
  return true;
}
