using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving.Solvers;

/// <summary>
/// DLX（Dancing Links X）精确覆盖求解器
/// 
/// 参照 Donald Knuth 的 Dancing Links 算法实现
/// 用于高效求解精确覆盖问题，大幅提升数独生成效率
/// </summary>
public class DLXSolver
{
    #region DLX Node Structure

    private class Node
    {
        public Node Left, Right, Up, Down;
        public ColumnHeader Column = null!;
        public int Row, Col;

        public Node()
        {
            Left = Right = Up = Down = this;
        }

        public Node(ColumnHeader column, int row, int columnIndex) : this()
        {
            Column = column;
            Row = row;
            Col = columnIndex;
        }
    }

    private class ColumnHeader : Node
    {
        public int Size;
        public int Index;

        public ColumnHeader(int index)
        {
            Size = 0;
            Index = index;
            Column = this;
        }
    }

    #endregion

    private ColumnHeader _root = null!;
    private List<int[]> _solutions = null!;
    private int _maxSolutions;
    private Func<bool>? _isCancelled;
    private bool _cancelled;

    /// <summary>
    /// 求解数独，返回所有解
    /// </summary>
    public List<int[,]> Solve(Board board, int maxSolutions = 2, Func<bool>? isCancelled = null)
    {
        _solutions = [];
        _maxSolutions = maxSolutions;
        _isCancelled = isCancelled;
        _cancelled = false;

        var grid = DLXSolver.BoardToGrid(board);
        var matrix = BuildExactCoverMatrix(grid);
        
        if (matrix == null)
            return ConvertSolutions(grid.GetLength(0));

        BuildDLXStructure(matrix);
        Search([], 0);

        return ConvertSolutions(grid.GetLength(0));
    }

    /// <summary>
    /// 计算解的数量
    /// </summary>
    public int CountSolutions(Board board, int maxCount = 2, Func<bool>? isCancelled = null)
    {
        _solutions = [];
        _maxSolutions = maxCount;
        _isCancelled = isCancelled;
        _cancelled = false;

        var grid = DLXSolver.BoardToGrid(board);
        var matrix = BuildExactCoverMatrix(grid);
        
        if (matrix == null)
            return 0;

        BuildDLXStructure(matrix);
        Search([], 0);
        
        return _solutions.Count;
    }

    /// <summary>
    /// 检查是否有唯一解
    /// </summary>
    public bool HasUniqueSolution(Board board, Func<bool>? isCancelled = null)
    {
        return CountSolutions(board, 2, isCancelled) == 1;
    }

    #region Private Methods

    private static int[,] BoardToGrid(Board board)
    {
        var n = board.Size;
        var grid = new int[n, n];
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                grid[r, c] = board.GetCell(r, c).Value ?? 0;
            }
        }
        return grid;
    }

    /// <summary>
    /// 构建精确覆盖矩阵
    /// 标准数独：729行 × 324列
    /// 行：(row, col, value) 组合
    /// 列：行约束(81) + 列约束(81) + 宫格约束(81) + 单元格约束(81)
    /// </summary>
    private static bool[][]? BuildExactCoverMatrix(int[,] grid)
    {
        int n = grid.GetLength(0);
        int boxSize = (int)Math.Sqrt(n);
        
        int numRows = n * n * n;      // 每个单元格有 n 种可能值
        int numCols = n * n * 4;      // 4种约束类型 × n²
        
        var matrix = new bool[numRows][];
        
        for (int r = 0; r < n; r++)
        {
            for (int c = 0; c < n; c++)
            {
                int value = grid[r, c];
                
                for (int v = 1; v <= n; v++)
                {
                    int rowIdx = r * n * n + c * n + (v - 1);
                    matrix[rowIdx] = new bool[numCols];
                    
                    // 如果已有固定值，只考虑该值
                    if (value != 0 && v != value)
                        continue;
                    
                    // 行约束：行 r 包含值 v
                    int rowConstraint = r * n + (v - 1);
                    // 列约束：列 c 包含值 v
                    int colConstraint = n * n + c * n + (v - 1);
                    // 宫格约束：宫格 (r/boxSize, c/boxSize) 包含值 v
                    int boxR = r / boxSize;
                    int boxC = c / boxSize;
                    int boxConstraint = 2 * n * n + (boxR * boxSize + boxC) * n + (v - 1);
                    // 单元格约束：单元格 (r, c) 被填充
                    int cellConstraint = 3 * n * n + r * n + c;
                    
                    matrix[rowIdx][rowConstraint] = true;
                    matrix[rowIdx][colConstraint] = true;
                    matrix[rowIdx][boxConstraint] = true;
                    matrix[rowIdx][cellConstraint] = true;
                }
            }
        }
        
        return matrix;
    }

    private void BuildDLXStructure(bool[][] matrix)
    {
        int numCols = matrix[0].Length;
        
        // 创建列头
        _root = new ColumnHeader(-1);
        var headers = new ColumnHeader[numCols];
        
        ColumnHeader current = _root;
        for (int i = 0; i < numCols; i++)
        {
            var header = new ColumnHeader(i);
            headers[i] = header;
            current.Right = header;
            header.Left = current;
            current = header;
        }
        current.Right = _root;
        _root.Left = current;
        
        // 创建数据行
        for (int rowIdx = 0; rowIdx < matrix.Length; rowIdx++)
        {
            Node? firstInRow = null;
            Node? lastInRow = null;
            
            for (int colIdx = 0; colIdx < numCols; colIdx++)
            {
                if (matrix[rowIdx][colIdx])
                {
                    var header = headers[colIdx];
                    var node = new Node(header, rowIdx, colIdx)
                    {
                        // 垂直链接
                        Up = header.Up,
                        Down = header
                    };
                    header.Up.Down = node;
                    header.Up = node;
                    header.Size++;
                    
                    // 水平链接
                    if (firstInRow == null)
                    {
                        firstInRow = node;
                        lastInRow = node;
                        node.Left = node;
                        node.Right = node;
                    }
                    else
                    {
                        lastInRow?.Right = node;
                        node.Left = lastInRow!;
                        node.Right = firstInRow;
                        firstInRow.Left = node;
                        lastInRow = node;
                    }
                }
            }
        }
    }

    private void Search(List<Node> solution, int k)
    {
        // 检查取消
        if (_cancelled || (_isCancelled?.Invoke() ?? false))
        {
            _cancelled = true;
            return;
        }
        
        // 检查是否达到最大解数
        if (_solutions.Count >= _maxSolutions)
            return;
        
        // 如果没有列可选，找到一个解
        if (_root.Right == _root)
        {
            var sol = new int[solution.Count];
            for (int i = 0; i < solution.Count; i++)
            {
                sol[i] = solution[i].Row;
            }
            _solutions.Add(sol);
            return;
        }
        
        // 选择列（MRV 启发式）
        ColumnHeader col = SelectColumn();
        DLXSolver.Cover(col);
        
        for (Node row = col.Down; row != col; row = row.Down)
        {
            solution.Add(row);
            
            // 覆盖所有相关列
            for (Node j = row.Right; j != row; j = j.Right)
            {
                DLXSolver.Cover(j.Column);
            }
            
            Search(solution, k + 1);
            
            // 恢复
            row = solution[^1];
            solution.RemoveAt(solution.Count - 1);
            col = row.Column;
            
            for (Node j = row.Left; j != row; j = j.Left)
            {
                Uncover(j.Column);
            }
        }
        
        Uncover(col);
    }

    private ColumnHeader SelectColumn()
    {
        // MRV（Minimum Remaining Values）启发式
        int minSize = int.MaxValue;
        ColumnHeader? selected = null;
        
        for (ColumnHeader col = (ColumnHeader)_root.Right; col != _root; col = (ColumnHeader)col.Right)
        {
            if (col.Size < minSize)
            {
                minSize = col.Size;
                selected = col;
            }
        }
        
        return selected!;
    }

    private static void Cover(ColumnHeader col)
    {
        col.Right.Left = col.Left;
        col.Left.Right = col.Right;
        
        for (Node row = col.Down; row != col; row = row.Down)
        {
            for (Node j = row.Right; j != row; j = j.Right)
            {
                j.Down.Up = j.Up;
                j.Up.Down = j.Down;
                j.Column.Size--;
            }
        }
    }

    private static void Uncover(ColumnHeader col)
    {
        for (Node row = col.Up; row != col; row = row.Up)
        {
            for (Node j = row.Left; j != row; j = j.Left)
            {
                j.Column.Size++;
                j.Down.Up = j;
                j.Up.Down = j;
            }
        }
        
        col.Right.Left = col;
        col.Left.Right = col;
    }

    private List<int[,]> ConvertSolutions(int size)
    {
        var result = new List<int[,]>();
        
        foreach (var sol in _solutions)
        {
            var grid = new int[size, size];
            foreach (int rowIdx in sol)
            {
                int r = rowIdx / (size * size);
                int remainder = rowIdx % (size * size);
                int c = remainder / size;
                int v = remainder % size + 1;
                grid[r, c] = v;
            }
            result.Add(grid);
        }
        
        return result;
    }

    #endregion
}