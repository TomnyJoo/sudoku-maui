import 'dart:math';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/candidate_calculator.dart';
import 'package:sudoku/services/solving/strategy_engine.dart';

class KillerCombinationChecker {
  static final Map<String, List<List<int>>> _comboCache = {};

  static List<List<int>> getCombinations(int k, int sum, {int maxNumber = 9}) {
    if (k <= 0 || sum <= 0) return [];
    final cacheKey = '$k,$sum,$maxNumber';
    var cached = _comboCache[cacheKey];
    if (cached != null) return cached;
    cached = <List<int>>[];
    _enumerateCombinations(
      startNum: 1,
      remaining: k,
      targetSum: sum,
      current: <int>[],
      result: cached,
      maxNumber: maxNumber,
    );
    _comboCache[cacheKey] = cached;
    return cached;
  }

  static void _enumerateCombinations({
    required int startNum,
    required int remaining,
    required int targetSum,
    required List<int> current,
    required List<List<int>> result,
    required int maxNumber,
  }) {
    if (remaining == 0) {
      if (targetSum == 0) result.add(List.from(current));
      return;
    }
    final minPossible = startNum * remaining + remaining * (remaining - 1) ~/ 2;
    if (minPossible > targetSum) return;
    final maxPossible = maxNumber * remaining - remaining * (remaining - 1) ~/ 2;
    if (maxPossible < targetSum) return;
    for (int num = startNum; num <= maxNumber; num++) {
      if (num > targetSum) break;
      current.add(num);
      _enumerateCombinations(
        startNum: num + 1,
        remaining: remaining - 1,
        targetSum: targetSum - num,
        current: current,
        result: result,
        maxNumber: maxNumber,
      );
      current.removeLast();
    }
  }

  static List<Set<int>> getAssignments(
    List<int> combo,
    List<Set<int>> candidates,
  ) {
    final k = combo.length;
    final assignment = List<int>.filled(k, -1);
    final positionDigits = List<List<int>>.generate(k, (_) => <int>[]);
    _enumerateAssignments(0, combo, candidates, assignment, positionDigits);
    if (positionDigits.every((d) => d.isEmpty)) return [];
    return positionDigits.map((d) => d.toSet()).toList();
  }

  static void _enumerateAssignments(
    int index,
    List<int> combo,
    List<Set<int>> candidates,
    List<int> assignment,
    List<List<int>> positionDigits,
  ) {
    if (index == combo.length) {
      for (int i = 0; i < combo.length; i++) {
        positionDigits[assignment[i]].add(combo[i]);
      }
      return;
    }
    final num = combo[index];
    for (int pos = 0; pos < candidates.length; pos++) {
      if (assignment[pos] != -1) continue;
      if (!candidates[pos].contains(num)) continue;
      assignment[pos] = index;
      _enumerateAssignments(index + 1, combo, candidates, assignment, positionDigits);
      assignment[pos] = -1;
    }
  }

  static Set<int> getBasicPossibleDigits(int k, int sum, Set<int> excluded, {int maxNumber = 9}) {
    if (k <= 0 || sum <= 0) return <int>{};
    final combos = getCombinations(k, sum, maxNumber: maxNumber);
    final digits = <int>{};
    for (final combo in combos) {
      digits.addAll(combo);
    }
    return digits.difference(excluded);
  }

  static void applyCageConstraint(
    int sum,
    List<(int, int)> cellCoordinates,
    Set<int> Function(int, int) getCandidates,
    void Function(int, int, Set<int>) setCandidates,
    int? Function(int, int) getCellValue, {
    int maxNumber = 9,
  }) {
    final filled = <int>{};
    int filledSum = 0;
    final emptyIndices = <int>[];
    final emptyCandidates = <Set<int>>[];

    for (int i = 0; i < cellCoordinates.length; i++) {
      final (r, c) = cellCoordinates[i];
      final val = getCellValue(r, c);
      if (val != null) {
        filled.add(val);
        filledSum += val;
      } else {
        emptyIndices.add(i);
        emptyCandidates.add(getCandidates(r, c));
      }
    }

    final remainingSum = sum - filledSum;
    if (remainingSum < 0 || emptyIndices.isEmpty) return;

    final k = emptyIndices.length;

    // 快速路径：所有空单元格候选集均为完整 {1..maxNumber}
    final fullSet = Set<int>.from(List.generate(maxNumber, (i) => i + 1));
    final allFull = emptyCandidates.every((cands) =>
        cands.length == maxNumber && cands.containsAll(fullSet));

    if (allFull) {
      final basicPossible = getBasicPossibleDigits(k, remainingSum, filled, maxNumber: maxNumber);
      for (int i = 0; i < k; i++) {
        final (r, c) = cellCoordinates[emptyIndices[i]];
        final newCandidates = emptyCandidates[i].intersection(basicPossible);
        if (newCandidates.isNotEmpty) {
          setCandidates(r, c, newCandidates);
        }
      }
      return;
    }

    final allCombos = getCombinations(k, remainingSum, maxNumber: maxNumber);
    final positionPossible = List<Set<int>>.generate(k, (_) => <int>{});
    bool hasValidCombo = false;

    for (final combo in allCombos) {
      bool valid = true;
      for (final num in combo) {
        if (filled.contains(num)) {
          valid = false;
          break;
        }
      }
      if (!valid) continue;

      final assignments = getAssignments(combo, emptyCandidates);
      if (assignments.isEmpty) continue;

      hasValidCombo = true;
      for (int i = 0; i < k; i++) {
        positionPossible[i].addAll(assignments[i]);
      }
    }

    if (!hasValidCombo) return;

    final updates = <(int, int, Set<int>)>[];
    for (int i = 0; i < k; i++) {
      final (r, c) = cellCoordinates[emptyIndices[i]];
      final newCandidates = emptyCandidates[i].intersection(positionPossible[i]);
      if (newCandidates.isEmpty) continue;
      updates.add((r, c, newCandidates));
    }

    for (final (r, c, candidates) in updates) {
      setCandidates(r, c, candidates);
    }
  }
}

/// 杀手笼子约束
class KillerCageConstraintStrategy extends Strategy {
  const KillerCageConstraintStrategy();

  @override
  StrategyType get type => StrategyType.killerCageConstraint;

  @override
  StrategyLevel get level => StrategyLevel.basic;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    final cages = context.killerCages;
    if (cages == null) return false;

    bool changed = false;
    for (final cage in cages) {
      final oldCandidates = _captureCandidates(context, cage);
      _applyCageConstraint(context, cage);
      if (_candidatesChanged(context, cage, oldCandidates)) {
        changed = true;
      }
    }
    return changed;
  }

  Set<int> _captureCandidates(BoardContext context, KillerCage cage) {
    final result = <int>{};
    for (final (r, c) in cage.cellCoordinates) {
      result.addAll(context.getCandidates(r, c));
    }
    return result;
  }

  bool _candidatesChanged(BoardContext context, KillerCage cage, Set<int> oldCandidates) {
    final current = <int>{};
    for (final (r, c) in cage.cellCoordinates) {
      current.addAll(context.getCandidates(r, c));
    }
    return !setEquals(oldCandidates, current);
  }

  static bool setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  void _applyCageConstraint(BoardContext context, KillerCage cage) {
    final maxNumber = context.board.getMaxNumber();
    KillerCombinationChecker.applyCageConstraint(
      cage.sum,
      cage.cellCoordinates,
      (r, c) => context.getCandidates(r, c),
      (r, c, candidates) => context.setCandidates(r, c, candidates),
      (r, c) => context.board.getCell(r, c).value,
      maxNumber: maxNumber,
    );
  }
}

/// 杀手45法则（仅单 innie/outie）
class Killer45RuleStrategy extends Strategy {
  const Killer45RuleStrategy();

  @override
  StrategyType get type => StrategyType.killer45Rule;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    bool changed = false;
    for (int i = 0; i < context.size; i++) {
      if (_apply45RuleToLine(context, i, true)) changed = true;
      if (_apply45RuleToLine(context, i, false)) changed = true;
      if (_apply45RuleToBlock(context, i)) changed = true;
    }
    return changed;
  }

  bool _apply45RuleToLine(BoardContext context, int index, bool isRow) {
    final cells = <(int, int)>[];
    for (int i = 0; i < context.size; i++) {
      cells.add(isRow ? (index, i) : (i, index));
    }
    return _apply45RuleToCells(context, cells);
  }

  bool _apply45RuleToBlock(BoardContext context, int blockIndex) {
    final maxNumber = context.board.getMaxNumber();
    final blockSize = sqrt(maxNumber).toInt();
    final boxRow = (blockIndex ~/ blockSize) * blockSize;
    final boxCol = (blockIndex % blockSize) * blockSize;
    final cells = <(int, int)>[];
    for (int r = boxRow; r < boxRow + blockSize; r++) {
      for (int c = boxCol; c < boxCol + blockSize; c++) {
        cells.add((r, c));
      }
    }
    return _apply45RuleToCells(context, cells);
  }

  bool _apply45RuleToCells(BoardContext context, List<(int, int)> cells) {
    final maxNumber = context.board.getMaxNumber();
    final targetSum = maxNumber * (maxNumber + 1) ~/ 2;

    int filledSum = 0;
    final unfilled = <(int, int)>[];
    for (final (r, c) in cells) {
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filledSum += val;
      } else {
        unfilled.add((r, c));
      }
    }

    final cages = context.killerCages ?? [];
    final Set<KillerCage> fullyInside = {};
    final Set<KillerCage> partiallyInside = {};

    for (final cage in cages) {
      int inside = 0;
      for (final coord in cage.cellCoordinates) {
        if (cells.contains(coord)) inside++;
      }
      if (inside == cage.cellCoordinates.length) {
        fullyInside.add(cage);
      } else if (inside > 0) {
        partiallyInside.add(cage);
      }
    }

    int internalCageRemainingSum = 0;
    for (final cage in fullyInside) {
      int cageFilled = 0;
      for (final coord in cage.cellCoordinates) {
        final val = context.board.getCell(coord.$1, coord.$2).value;
        if (val != null) cageFilled += val;
      }
      internalCageRemainingSum += cage.sum - cageFilled;
    }

    // 自由单元格：不在任何笼子内的空单元格
    final freeCells = <(int, int)>[];
    for (final cell in unfilled) {
      bool inAnyCage = false;
      for (final cage in cages) {
        if (cage.cellCoordinates.any((c) => c == cell)) {
          inAnyCage = true;
          break;
        }
      }
      if (!inAnyCage) {
        freeCells.add(cell);
      }
    }

    if (partiallyInside.isNotEmpty) {
      return false; // 存在部分覆盖笼子，安全跳过
    }

    final remainingSum = targetSum - filledSum - internalCageRemainingSum;
    if (remainingSum < 0) return false;

    if (freeCells.length == 1) {
      final (r, c) = freeCells.first;
      final oldCandidates = context.getCandidates(r, c).toSet();
      if (remainingSum >= 1 && remainingSum <= maxNumber) {
        final newCandidates = oldCandidates.intersection({remainingSum});
        if (newCandidates.isNotEmpty && newCandidates.length != oldCandidates.length) {
          context.setCandidates(r, c, newCandidates);
          return true;
        }
      }
    }
    return false;
  }
}

/// 杀手数独交叉排除策略（保持不变）
class KillerOverlapEliminationStrategy extends Strategy {
  const KillerOverlapEliminationStrategy();

  @override
  StrategyType get type => StrategyType.killerOverlapElimination;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    bool changed = false;
    final Map<int, Set<int>> adjacency = {};
    final cages = context.killerCages ?? [];
    for (int i = 0; i < cages.length; i++) {
      adjacency[i] = {};
      for (int j = i + 1; j < cages.length; j++) {
        if (_cagesOverlap(cages[i], cages[j])) {
          adjacency[i]!.add(j);
          adjacency[j]!.add(i);
        }
      }
    }

    final visited = <int>{};
    for (int i = 0; i < cages.length; i++) {
      if (visited.contains(i)) continue;
      final component = <int>[];
      final queue = [i];
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        if (visited.contains(cur)) continue;
        visited.add(cur);
        component.add(cur);
        for (final neighbor in adjacency[cur]!) {
          if (!visited.contains(neighbor)) {
            queue.add(neighbor);
          }
        }
      }
      if (component.length > 1) {
        if (_applyCrossEliminationForCageGroup(context, component, cages)) {
          changed = true;
        }
      }
    }
    return changed;
  }

  bool _cagesOverlap(KillerCage a, KillerCage b) {
    for (final cellA in a.cellCoordinates) {
      for (final cellB in b.cellCoordinates) {
        if (cellA == cellB) return true;
      }
    }
    return false;
  }

  bool _applyCrossEliminationForCageGroup(
    BoardContext context,
    List<int> cageIndices,
    List<KillerCage> cages,
  ) {
    bool changed = false;
    final cageGroup = cageIndices.map((i) => cages[i]).toList();
    final Map<KillerCage, Set<int>> cagePossibleDigits = {};
    for (final cage in cageGroup) {
      cagePossibleDigits[cage] = _getPossibleDigitsForCage(context, cage);
    }

    final allCells = <(int, int)>{};
    for (final cage in cageGroup) {
      allCells.addAll(cage.cellCoordinates);
    }
    final cellList = allCells.toList();

    for (final (r, c) in cellList) {
      final relevantCages = cageGroup
          .where((cage) => cage.cellCoordinates.contains((r, c)))
          .toList();
      if (relevantCages.length < 2) continue;

      final oldSet = context.getCandidates(r, c).toSet();
      if (oldSet.isEmpty) continue;

      Set<int>? intersection;
      for (final cage in relevantCages) {
        final possibleDigits = cagePossibleDigits[cage]!;
        if (intersection == null) {
          intersection = possibleDigits;
        } else {
          intersection = intersection.intersection(possibleDigits);
        }
        if (intersection.isEmpty) break;
      }

      if (intersection != null && intersection.isNotEmpty) {
        final newSet = oldSet.intersection(intersection);
        if (newSet.isNotEmpty && newSet.length != oldSet.length) {
          context.setCandidates(r, c, newSet);
          changed = true;
        }
      }
    }
    return changed;
  }

  Set<int> _getPossibleDigitsForCage(BoardContext context, KillerCage cage) {
    final cells = cage.cellCoordinates;
    final sum = cage.sum;
    final maxNumber = context.board.getMaxNumber();

    final filled = <int>{};
    int filledSum = 0;
    final emptyIndices = <int>[];
    final emptyCandidates = <Set<int>>[];

    for (int i = 0; i < cells.length; i++) {
      final (r, c) = cells[i];
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filled.add(val);
        filledSum += val;
      } else {
        emptyIndices.add(i);
        emptyCandidates.add(context.getCandidates(r, c));
      }
    }

    final remainingSum = sum - filledSum;
    if (remainingSum < 0 || emptyIndices.isEmpty) return <int>{};

    final basicPossible = KillerCombinationChecker.getBasicPossibleDigits(
      emptyIndices.length, remainingSum, filled, maxNumber: maxNumber,
    );
    if (basicPossible.isEmpty) return <int>{};

    bool hasConstraint = false;
    for (final cands in emptyCandidates) {
      if (cands.length < maxNumber) {
        hasConstraint = true;
        break;
      }
    }
    if (!hasConstraint) return basicPossible;

    final allCombos = KillerCombinationChecker.getCombinations(
      emptyIndices.length, remainingSum, maxNumber: maxNumber,
    );

    final possibleDigits = <int>{};
    for (final combo in allCombos) {
      bool valid = true;
      for (final num in combo) {
        if (filled.contains(num)) {
          valid = false;
          break;
        }
      }
      if (!valid) continue;

      final assignments = KillerCombinationChecker.getAssignments(combo, emptyCandidates);
      if (assignments.isEmpty) continue;

      for (final posDigits in assignments) {
        possibleDigits.addAll(posDigits);
      }
    }
    return possibleDigits;
  }
}

/// 杀手数独笼子区块策略（保持不变）
class KillerCageBlockingStrategy extends Strategy {
  const KillerCageBlockingStrategy();

  @override
  StrategyType get type => StrategyType.killerCageBlocking;

  @override
  StrategyLevel get level => StrategyLevel.intermediate;

  @override
  Set<GameType> get applicableGames => {GameType.killer};

  @override
  bool apply(BoardContext context) {
    final cages = context.killerCages;
    if (cages == null) return false;

    bool changed = false;
    for (final cage in cages) {
      if (_applyCageBlocking(context, cage)) changed = true;
    }
    return changed;
  }

  bool _applyCageBlocking(BoardContext context, KillerCage cage) {
    final cells = cage.cellCoordinates;
    if (cells.isEmpty) return false;

    final maxNumber = context.board.getMaxNumber();
    final blockSize = sqrt(maxNumber).toInt();

    final firstRow = cells.first.$1;
    final firstCol = cells.first.$2;
    final firstBlock = (firstRow ~/ blockSize) * blockSize + (firstCol ~/ blockSize);
    final sameRow = cells.every((c) => c.$1 == firstRow);
    final sameCol = cells.every((c) => c.$2 == firstCol);
    final sameBlock = cells.every((c) => (c.$1 ~/ blockSize) * blockSize + (c.$2 ~/ blockSize) == firstBlock);
    if (!sameRow && !sameCol && !sameBlock) return false;

    final combos = _getCageCombos(context, cage);
    if (combos == null) return false;

    if (combos.isEmpty) return false;

    Set<int>? commonDigits;
    for (final combo in combos) {
      if (commonDigits == null) {
        commonDigits = Set.from(combo);
      } else {
        commonDigits.retainAll(combo);
      }
      if (commonDigits.isEmpty) break;
    }
    if (commonDigits == null || commonDigits.isEmpty) return false;

    final modifications = <(int, int, Set<int>)>[];
    if (sameRow) {
      final row = firstRow;
      for (int c = 0; c < context.size; c++) {
        if (cells.any((cell) => cell.$2 == c)) continue;
        final oldSet = context.getCandidates(row, c).toSet();
        final newSet = oldSet.difference(commonDigits);
        if (newSet.isEmpty) continue;
        if (newSet.length != oldSet.length) {
          modifications.add((row, c, newSet));
        }
      }
    } else if (sameCol) {
      final col = firstCol;
      for (int r = 0; r < context.size; r++) {
        if (cells.any((cell) => cell.$1 == r)) continue;
        final oldSet = context.getCandidates(r, col).toSet();
        final newSet = oldSet.difference(commonDigits);
        if (newSet.isEmpty) continue;
        if (newSet.length != oldSet.length) {
          modifications.add((r, col, newSet));
        }
      }
    } else if (sameBlock) {
      final blockRow = firstRow ~/ blockSize;
      final blockCol = firstCol ~/ blockSize;
      for (int r = blockRow * blockSize; r < (blockRow + 1) * blockSize; r++) {
        for (int c = blockCol * blockSize; c < (blockCol + 1) * blockSize; c++) {
          if (cells.any((cell) => cell.$1 == r && cell.$2 == c)) continue;
          final oldSet = context.getCandidates(r, c).toSet();
          final newSet = oldSet.difference(commonDigits);
          if (newSet.isEmpty) continue;
          if (newSet.length != oldSet.length) {
            modifications.add((r, c, newSet));
          }
        }
      }
    }

    if (modifications.isEmpty) return false;

    for (final (r, c, newSet) in modifications) {
      context.setCandidates(r, c, newSet);
    }
    return true;
  }

  Set<Set<int>>? _getCageCombos(BoardContext context, KillerCage cage) {
    final sum = cage.sum;
    final cells = cage.cellCoordinates;
    final maxNumber = context.board.getMaxNumber();
    final filled = <int>{};
    int filledSum = 0;
    final emptyIndices = <int>[];
    final emptyCandidates = <Set<int>>[];

    for (int i = 0; i < cells.length; i++) {
      final (r, c) = cells[i];
      final val = context.board.getCell(r, c).value;
      if (val != null) {
        filled.add(val);
        filledSum += val;
      } else {
        emptyIndices.add(i);
        emptyCandidates.add(context.getCandidates(r, c));
      }
    }

    final remainingSum = sum - filledSum;
    if (remainingSum < 0) return <Set<int>>{};
    if (remainingSum == 0) {
      if (emptyIndices.isNotEmpty) return <Set<int>>{};
      return null;
    }

    if (emptyIndices.isEmpty) return null;

    final allCombos = KillerCombinationChecker.getCombinations(
      emptyIndices.length, remainingSum, maxNumber: maxNumber,
    );

    const maxComboCount = 100;
    final validCombos = <Set<int>>{};
    for (final combo in allCombos) {
      if (validCombos.length >= maxComboCount) break;
      bool valid = true;
      for (final num in combo) {
        if (filled.contains(num)) {
          valid = false;
          break;
        }
      }
      if (!valid) continue;

      final assignments = KillerCombinationChecker.getAssignments(combo, emptyCandidates);
      if (assignments.isEmpty) continue;
      validCombos.add(combo.toSet());
    }
    return validCombos.isEmpty ? null : validCombos;
  }
}
