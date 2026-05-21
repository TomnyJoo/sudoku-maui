import 'package:sudoku/models/board.dart';
import 'package:sudoku/models/index.dart';
import 'package:sudoku/services/solving/solvers/dlx_solver.dart';
import 'package:sudoku/services/solving/solvers/jigsaw_bit_solver.dart';

/// Jigsaw DLX 求解器适配器
///
/// 将 JigsawBitSolver 适配为 DLXSudokuSolver 接口，
/// 使 JigsawGenerator 能使用统一的 DiggingAlgorithm 挖空系统。
class JigsawDlxSolverAdapter extends DLXSudokuSolver {
  JigsawDlxSolverAdapter()
      : super(
          size: 9,
          extraRegions: null,
        );

  @override
  int countSolutions(
    Board puzzle, {
    int maxCount = 2,
    bool Function()? isCancelled,
  }) {
    final jigsawBoard = puzzle as JigsawBoard;
    final bitSolver = JigsawBitSolver(
      regionMatrix: jigsawBoard.regionMatrix!,
    );
    return bitSolver.countSolutions(
      puzzle,
      maxCount: maxCount,
      isCancelled: isCancelled,
    );
  }
}
