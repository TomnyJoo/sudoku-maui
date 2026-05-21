using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.Models.Boards;

namespace SudoKu.Services.Solving.Solvers;

public class SamuraiBitSolver
{
    private const int BoardSize = SamuraiConstants.BoardSize;
    private const int SubGridSize = SamuraiConstants.SubGridSize;
    private const int BoxSize = StandardConstants.BoxSize;
    private const uint FullMask = StandardConstants.FullMask;

    // 内部可变棋盘
    private readonly int[,] _cells = new int[BoardSize, BoardSize];
    private readonly List<int>[,] _cellSubGrids;
    private readonly uint[][] _subRowMask;
    private readonly uint[][] _subColMask;
    private readonly uint[][] _subBoxMask;

    public SamuraiBitSolver()
    {
        _cellSubGrids = new List<int>[BoardSize, BoardSize];
        InitializeSubGrids();

        _subRowMask = new uint[5][];
        _subColMask = new uint[5][];
        _subBoxMask = new uint[5][];
        for (int i = 0; i < 5; i++)
        {
            _subRowMask[i] = new uint[SubGridSize];
            _subColMask[i] = new uint[SubGridSize];
            _subBoxMask[i] = new uint[SubGridSize];
        }
    }

    private void InitializeSubGrids()
    {
        for (int r = 0; r < BoardSize; r++)
        {
            for (int c = 0; c < BoardSize; c++)
            {
                if (_cellSubGrids[r, c] == null)
                {
                    _cellSubGrids[r, c] = [];
                }
                else
                {
                    _cellSubGrids[r, c].Clear();
                }
            }
        }

        for (int sg = 0; sg < 5; sg++)
        {
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[sg];
            for (int r = 0; r < SubGridSize; r++)
            {
                for (int c = 0; c < SubGridSize; c++)
                {
                    int gr = startRow + r;
                    int gc = startCol + c;
                    if (gr >= 0 && gr < BoardSize && gc >= 0 && gc < BoardSize)
                    {
                        _cellSubGrids[gr, gc].Add(sg);
                    }
                }
            }
        }
    }

    /// <summary>
    /// 生成武士数独终盘（支持中心子盘模板）
    /// </summary>
    public SamuraiBoard? GenerateSolution(
        List<List<int>>? centerTemplate = null,
        Random? random = null,
        Func<bool>? isCancelled = null)
    {
        random ??= new Random();
        Array.Clear(_cells, 0, _cells.Length);
        ClearMasks();

        // 1. 处理中心子盘（索引4）模板
        if (centerTemplate != null && centerTemplate.Count == SubGridSize)
        {
            int[] mapping = [.. Enumerable.Range(1, 9).OrderBy(_ => random.Next())];
            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[4]; // (6,6)

            for (int r = 0; r < SubGridSize; r++)
            {
                for (int c = 0; c < SubGridSize; c++)
                {
                    int val = centerTemplate[r][c];
                    if (val >= 1 && val <= 9)
                    {
                        int mappedVal = mapping[val - 1];
                        int gr = startRow + r;
                        int gc = startCol + c;
                        _cells[gr, gc] = mappedVal;

                        uint bit = 1u << (mappedVal - 1);
                        int boxIdx = (r / BoxSize) * BoxSize + (c / BoxSize);
                        _subRowMask[4][r] |= bit;
                        _subColMask[4][c] |= bit;
                        _subBoxMask[4][boxIdx] |= bit;
                    }
                }
            }
        }

        // 生成顺序：中心 → 左上 → 右上 → 左下 → 右下
        int[] order = [ 4, 0, 1, 2, 3 ];
        foreach (int sg in order)
        {
            if (isCancelled?.Invoke() ?? false) return null;
            var matrix = ExtractSubgridMatrix(sg);
            if (!SolveSubgrid(matrix, sg, isCancelled))
                return null;
            ApplySubgridSolution(sg, matrix);
        }

        return BuildBoardFromCells();
    }

    private void ClearMasks()
    {
        for (int sg = 0; sg < 5; sg++)
        {
            Array.Clear(_subRowMask[sg], 0, SubGridSize);
            Array.Clear(_subColMask[sg], 0, SubGridSize);
            Array.Clear(_subBoxMask[sg], 0, SubGridSize);
        }
    }

    private int[,] ExtractSubgridMatrix(int subgridIndex)
    {
        var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subgridIndex];
        var matrix = new int[SubGridSize, SubGridSize];
        for (int r = 0; r < SubGridSize; r++)
            for (int c = 0; c < SubGridSize; c++)
                matrix[r, c] = _cells[startRow + r, startCol + c];
        return matrix;
    }

    private void ApplySubgridSolution(int subgridIndex, int[,] matrix)
    {
        var (startRow, startCol) = SamuraiConstants.SubGridOffsets[subgridIndex];
        for (int r = 0; r < SubGridSize; r++)
        {
            for (int c = 0; c < SubGridSize; c++)
            {
                int val = matrix[r, c];
                if (val == 0) continue;
                int gr = startRow + r, gc = startCol + c;
                _cells[gr, gc] = val;

                uint bit = 1u << (val - 1);
                int boxIdx = (r / BoxSize) * BoxSize + (c / BoxSize);
                _subRowMask[subgridIndex][r] |= bit;
                _subColMask[subgridIndex][c] |= bit;
                _subBoxMask[subgridIndex][boxIdx] |= bit;
            }
        }
    }

    private bool SolveSubgrid(int[,] matrix, int subgridIndex, Func<bool>? isCancelled)
    {
        var rowMask = new uint[SubGridSize];
        var colMask = new uint[SubGridSize];
        var boxMask = new uint[SubGridSize];

        for (int r = 0; r < SubGridSize; r++)
        {
            for (int c = 0; c < SubGridSize; c++)
            {
                int val = matrix[r, c];
                if (val != 0)
                {
                    uint bit = 1u << (val - 1);
                    rowMask[r] |= bit;
                    colMask[c] |= bit;
                    boxMask[(r / BoxSize) * BoxSize + (c / BoxSize)] |= bit;
                }
            }
        }

        bool found = false;
        SamuraiBitSolver.DfsSubgrid(matrix, rowMask, colMask, boxMask, ref found, isCancelled);
        return found;
    }

    private static void DfsSubgrid(int[,] matrix, uint[] rowMask, uint[] colMask, uint[] boxMask,
                            ref bool found, Func<bool>? isCancelled)
    {
        if (found || (isCancelled?.Invoke() ?? false)) return;

        int bestR = -1, bestC = -1;
        uint bestBits = 0;
        int minCount = 10;

        for (int r = 0; r < SubGridSize; r++)
        {
            for (int c = 0; c < SubGridSize; c++)
            {
                if (matrix[r, c] != 0) continue;
                uint bits = FullMask & ~(rowMask[r] | colMask[c] | boxMask[(r / BoxSize) * BoxSize + (c / BoxSize)]);
                if (bits == 0) return;
                int cnt = BitOperations.PopCount(bits);
                if (cnt < minCount)
                {
                    minCount = cnt;
                    bestR = r;
                    bestC = c;
                    bestBits = bits;
                    if (cnt == 1) break;
                }
            }
            if (bestR != -1 && minCount == 1) break;
        }

        if (bestR == -1) { found = true; return; }

        uint bitsRemaining = bestBits;
        while (bitsRemaining != 0)
        {
            uint lowestBit = bitsRemaining & ~(bitsRemaining - 1);
            int value = BitOperations.TrailingZeroCount(lowestBit) + 1;
            bitsRemaining &= ~lowestBit;

            int boxIdx = (bestR / BoxSize) * BoxSize + (bestC / BoxSize);
            uint bit = 1u << (value - 1);

            uint oldRow = rowMask[bestR];
            uint oldCol = colMask[bestC];
            uint oldBox = boxMask[boxIdx];

            matrix[bestR, bestC] = value;
            rowMask[bestR] |= bit;
            colMask[bestC] |= bit;
            boxMask[boxIdx] |= bit;

            SamuraiBitSolver.DfsSubgrid(matrix, rowMask, colMask, boxMask, ref found, isCancelled);
            if (found) return;

            matrix[bestR, bestC] = 0;
            rowMask[bestR] = oldRow;
            colMask[bestC] = oldCol;
            boxMask[boxIdx] = oldBox;
        }
    }

    private SamuraiBoard BuildBoardFromCells()
    {
        var cells = new List<IReadOnlyList<SudokuCell>>(BoardSize);
        for (int r = 0; r < BoardSize; r++)
        {
            var row = new List<SudokuCell>(BoardSize);
            for (int c = 0; c < BoardSize; c++)
                row.Add(new SudokuCell(r, c, _cells[r, c] == 0 ? null : _cells[r, c], isFixed: _cells[r, c] != 0));
            cells.Add(row);
        }
        return new SamuraiBoard(cells);
    }

    // ========== 唯一解验证方法 ==========
    public int CountSolutions(Board board, int maxCount, Func<bool>? isCancelled = null)
    {
        Array.Clear(_cells, 0, _cells.Length);
        ClearMasks();

        for (int r = 0; r < BoardSize; r++)
        {
            for (int c = 0; c < BoardSize; c++)
            {
                int val = board.GetCell(r, c).Value ?? 0;
                if (val != 0)
                {
                    _cells[r, c] = val;
                    uint bit = 1u << (val - 1);
                    var subGridList = _cellSubGrids[r, c];
                    if (subGridList != null)
                    {
                        foreach (int sg in subGridList)
                        {
                            if (sg < 0 || sg >= 5) continue;
                            
                            var (startRow, startCol) = SamuraiConstants.SubGridOffsets[sg];
                            int localR = r - startRow;
                            int localC = c - startCol;
                            
                            if (localR < 0 || localR >= SubGridSize || localC < 0 || localC >= SubGridSize) continue;
                            
                            int boxIdx = (localR / BoxSize) * BoxSize + (localC / BoxSize);
                            if (boxIdx < 0 || boxIdx >= SubGridSize) continue;
                            
                            _subRowMask[sg][localR] |= bit;
                            _subColMask[sg][localC] |= bit;
                            _subBoxMask[sg][boxIdx] |= bit;
                        }
                    }
                }
            }
        }

        int solutionsFound = 0;
        DfsCount(ref solutionsFound, maxCount, isCancelled);
        return solutionsFound;
    }

    public bool HasUniqueSolution(Board board, Func<bool>? isCancelled = null)
    {
        return CountSolutions(board, 2, isCancelled) == 1;
    }

    private void DfsCount(ref int count, int maxCount, Func<bool>? isCancelled)
    {
        if (count >= maxCount || (isCancelled?.Invoke() ?? false)) return;

        int bestR = -1, bestC = -1;
        uint bestCandidates = 0;
        int minCount = 10;

        for (int r = 0; r < BoardSize; r++)
        {
            for (int c = 0; c < BoardSize; c++)
            {
                if (_cells[r, c] != 0) continue;
                if (_cellSubGrids[r, c] == null || _cellSubGrids[r, c].Count == 0) continue;

                uint candidates = FullMask;
                bool valid = true;
                
                foreach (int sg in _cellSubGrids[r, c])
                {
                    if (sg < 0 || sg >= 5)
                    {
                        valid = false;
                        break;
                    }
                    
                    var (startRow, startCol) = SamuraiConstants.SubGridOffsets[sg];
                    int localR = r - startRow;
                    int localC = c - startCol;
                    
                    if (localR < 0 || localR >= SubGridSize || localC < 0 || localC >= SubGridSize)
                    {
                        valid = false;
                        break;
                    }
                        
                    int boxIdx = (localR / BoxSize) * BoxSize + (localC / BoxSize);
                    if (boxIdx < 0 || boxIdx >= SubGridSize)
                    {
                        valid = false;
                        break;
                    }
                    
                    candidates &= ~_subRowMask[sg][localR];
                    candidates &= ~_subColMask[sg][localC];
                    candidates &= ~_subBoxMask[sg][boxIdx];
                }
                
                if (!valid) continue;
                if (candidates == 0) continue;

                int cnt = BitOperations.PopCount(candidates);
                if (cnt < minCount)
                {
                    minCount = cnt;
                    bestR = r;
                    bestC = c;
                    bestCandidates = candidates;
                    if (cnt == 1) break;
                }
            }
            if (bestR != -1 && minCount == 1) break;
        }

        if (bestR == -1)
        {
            count++;
            return;
        }

        uint bitsRemaining = bestCandidates;
        while (bitsRemaining != 0)
        {
            uint lowestBit = bitsRemaining & ~(bitsRemaining - 1);
            int value = BitOperations.TrailingZeroCount(lowestBit) + 1;
            bitsRemaining &= ~lowestBit;

            var savedMasks = new List<(int sg, int localR, int localC, int boxIdx, uint row, uint col, uint box)>();
            
            foreach (int sg in _cellSubGrids[bestR, bestC])
            {
                var (startRow, startCol) = SamuraiConstants.SubGridOffsets[sg];
                int localR = bestR - startRow;
                int localC = bestC - startCol;
                int boxIdx = (localR / BoxSize) * BoxSize + (localC / BoxSize);
                
                if (sg < 0 || sg >= 5 || localR < 0 || localR >= SubGridSize || 
                    localC < 0 || localC >= SubGridSize || boxIdx < 0 || boxIdx >= SubGridSize)
                    continue;
                
                savedMasks.Add((sg, localR, localC, boxIdx,
                    _subRowMask[sg][localR],
                    _subColMask[sg][localC],
                    _subBoxMask[sg][boxIdx]));

                uint bit = 1u << (value - 1);
                _subRowMask[sg][localR] |= bit;
                _subColMask[sg][localC] |= bit;
                _subBoxMask[sg][boxIdx] |= bit;
            }
            _cells[bestR, bestC] = value;

            DfsCount(ref count, maxCount, isCancelled);
            if (count >= maxCount) return;

            _cells[bestR, bestC] = 0;
            foreach (var (sg, localR, localC, boxIdx, row, col, box) in savedMasks)
            {
                _subRowMask[sg][localR] = row;
                _subColMask[sg][localC] = col;
                _subBoxMask[sg][boxIdx] = box;
            }
        }
    }
}