

using CommunityToolkit.Mvvm.Input;
using SudoKu.Helpers;
using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Resources;
using SudoKu.Services;
using SudoKu.Services.Interfaces;

namespace SudoKu.ViewModels;




/// <summary>
/// 自定义游戏页面 ViewModel，管理自定义棋盘的编辑、验证和保存。
/// 参照Flutter CustomGameScreenState实现，支持所有游戏类型的自定义输入。
/// </summary>
public partial class CustomGameViewModel : BaseViewModel
{
    #region 服务依赖

    /// <summary>游戏服务接口，用于验证棋盘。</summary>
    private readonly IGameService<Board> _gameService;

    /// <summary>游戏存储服务实例，用于保存自定义游戏。</summary>
    private readonly GameStorageService _storageService;

    #endregion
    #region 私有字段

    /// <summary>当前编辑的棋盘。</summary>
    private Board? _board;

    /// <summary>当前选中的单元格。</summary>
    private SudokuCell? _selectedCell;

    /// <summary>是否正在验证中。</summary>
    private bool _isValidating;

    /// <summary>是否可以开始游戏。</summary>
    private bool _canStartGame;

    /// <summary>验证消息。</summary>
    private string _validationMessage = string.Empty;

    /// <summary>当前游戏类型。</summary>
    private GameType _gameType = GameType.Standard;

    /// <summary>棋盘尺寸（9x9标准数独）。</summary>
    private int _boardSize = Constants.StandardBoardSize;

    /// <summary>宫格尺寸（3x3标准数独）。</summary>
    private int _boxSize = Constants.StandardBlockSize;

    /// <summary>最小填入单元格数量（用于验证）。</summary>
    private int _minFilledCells = 17;

    /// <summary>最大解数量检查（用于唯一解验证）。</summary>
    private readonly int _maxSolutionsToCheck = 2;

    #endregion

    #region 构造函数

    /// <summary>
    /// 初始化自定义游戏 ViewModel 的新实例。
    /// </summary>
    /// <param name="gameService">游戏服务实例。</param>
    /// <param name="storageService">游戏存储服务实例。</param>
    public CustomGameViewModel(IGameService<Board> gameService, GameStorageService storageService)
    {
        _gameService = gameService;
        _storageService = storageService;
        Title = AppResources.CustomSudoku;
    }

    #endregion

    #region 绑定属性

    /// <summary>
    /// 获取或设置当前编辑的棋盘。
    /// </summary>
    public Board? Board
    {
        get => _board;
        private set
        {
            if (SetProperty(ref _board, value))
            {
                UpdateBoardStats();
                UpdateCanStartGame();
            }
        }
    }

    /// <summary>
    /// 获取当前游戏类型。
    /// </summary>
    public GameType GameType => _gameType;

    /// <summary>
    /// 获取或设置是否正在验证中。
    /// </summary>
    public bool IsValidating
    {
        get => _isValidating;
        private set => SetProperty(ref _isValidating, value);
    }

    /// <summary>
    /// 获取或设置是否可以开始游戏。
    /// </summary>
    public bool CanStartGame
    {
        get => _canStartGame;
        private set => SetProperty(ref _canStartGame, value);
    }

    /// <summary>
    /// 获取或设置验证消息。
    /// </summary>
    public string ValidationMessage
    {
        get => _validationMessage;
        private set => SetProperty(ref _validationMessage, value);
    }

    /// <summary>
    /// 获取验证中的显示文本。
    /// </summary>
    public static string ValidatingText => AppResources.Gen_Validating;

    /// <summary>
    /// 获取说明文本1：点击选择单元格。
    /// </summary>
    public static string InstructionText1 => "点击选择单元格";

    /// <summary>
    /// 获取说明文本2：输入数字。
    /// </summary>
    public static string InstructionText2 => "输入数字";

    /// <summary>
    /// 获取数字使用次数统计。
    /// </summary>
    public Dictionary<int, int> NumberCounts => Board?.CalculateNumberCounts() ?? [];

    #endregion

    #region 初始化方法

    /// <summary>
    /// 异步初始化自定义游戏页面，创建空白棋盘。
    /// 参照Flutter initState和_initializeBoard方法。
    /// </summary>
    /// <param name="parameter">导航参数，可包含GameType。</param>
    /// <returns>初始化完成的任务。</returns>
    public override Task InitializeAsync(object? parameter = null)
    {
        // 解析导航参数
        if (parameter is Dictionary<string, object> dict)
        {
            if (dict.TryGetValue("GameType", out var gt) && gt is GameType gameType)
            {
                _gameType = gameType;
            }
        }

        // 根据游戏类型设置参数
        SetGameTypeParameters(_gameType);

        // 初始化棋盘
        InitializeBoard();

        return Task.CompletedTask;
    }

    /// <summary>
    /// 根据游戏类型设置参数。
    /// </summary>
    private void SetGameTypeParameters(GameType gameType)
    {
        switch (gameType)
        {
            case GameType.Standard:
            case GameType.Diagonal:
            case GameType.Window:
                _boardSize = 9;
                _boxSize = 3;
                _minFilledCells = 17;
                break;
            case GameType.Jigsaw:
                _boardSize = 9;
                _boxSize = 3;
                _minFilledCells = 17;
                break;
            case GameType.Killer:
                _boardSize = 9;
                _boxSize = 3;
                _minFilledCells = 0; // 杀手数独可以有更少预填数字
                break;
            case GameType.Samurai:
                _boardSize = 21;
                _boxSize = 3;
                _minFilledCells = 50; // 武士数独需要更多预填数字
                break;
            default:
                _boardSize = 9;
                _boxSize = 3;
                _minFilledCells = 17;
                break;
        }
    }

    /// <summary>
    /// 初始化空白棋盘。
    /// 参照Flutter _initializeBoard方法。
    /// </summary>
    private void InitializeBoard()
    {
        var cells = new List<List<SudokuCell>>();
        for (int r = 0; r < _boardSize; r++)
        {
            var row = new List<SudokuCell>();
            for (int c = 0; c < _boardSize; c++)
            {
                row.Add(new SudokuCell(r, c));
            }
            cells.Add(row);
        }

        // 创建区域
        var regions = CreateRegions(cells);

        Board = new CustomGameBoard(_boardSize, cells, regions, _gameType);
        _selectedCell = null;
    }

    /// <summary>
    /// 创建棋盘区域。
    /// </summary>
    private List<SudokuRegion> CreateRegions(List<List<SudokuCell>> cells)
    {
        var regions = new List<SudokuRegion>();

        // 标准数独、对角线数独、窗口数独创建宫格区域
        if (_gameType is GameType.Standard or GameType.Diagonal or GameType.Window)
        {
            regions.AddRange(CreateBlockRegions(cells));
        }

        // 锯齿数独创建不规则区域（简化版本，使用预设模板）
        if (_gameType == GameType.Jigsaw)
        {
            regions.AddRange(CreateJigsawRegions(cells));
        }

        // 杀手数独创建笼子区域（简化版本）
        if (_gameType == GameType.Killer)
        {
            regions.AddRange(CustomGameViewModel.CreateKillerCages(cells));
        }

        // 所有类型都创建行和列区域
        regions.AddRange(CreateRowAndColumnRegions(cells));

        return regions;
    }

    /// <summary>
    /// 创建宫格区域（3x3）。
    /// </summary>
    private List<SudokuRegion> CreateBlockRegions(List<List<SudokuCell>> cells)
    {
        var regions = new List<SudokuRegion>();
        for (int blockRow = 0; blockRow < _boxSize; blockRow++)
        {
            for (int blockCol = 0; blockCol < _boxSize; blockCol++)
            {
                var blockCells = new List<SudokuCell>();
                for (int r = blockRow * _boxSize; r < blockRow * _boxSize + _boxSize; r++)
                {
                    for (int c = blockCol * _boxSize; c < blockCol * _boxSize + _boxSize; c++)
                    {
                        if (r < _boardSize && c < _boardSize)
                        {
                            blockCells.Add(cells[r][c]);
                        }
                    }
                }
                regions.Add(new SudokuRegion(
                    $"block_{blockRow}_{blockCol}",
                    RegionType.Block,
                    $"宫格({blockRow + 1},{blockCol + 1})",
                    blockCells));
            }
        }
        return regions;
    }

    /// <summary>
    /// 创建锯齿数独的不规则区域（简化实现）。
    /// </summary>
    private List<SudokuRegion> CreateJigsawRegions(List<List<SudokuCell>> cells)
    {
        _ = new List<SudokuRegion>();
        // 简化实现：使用标准的3x3宫格作为基础
        // 实际应用中应该从模板加载
        return CreateBlockRegions(cells);
    }

    /// <summary>
    /// 创建杀手数独的笼子区域（简化实现）。
    /// </summary>
    private static List<SudokuRegion> CreateKillerCages(List<List<SudokuCell>> _)
    {
        var regions = new List<SudokuRegion>();
        // 简化实现：不创建预定义笼子，由用户自由输入
        // 实际应用中应该从模板加载
        return regions;
    }

    /// <summary>
    /// 创建行和列区域。
    /// </summary>
    private List<SudokuRegion> CreateRowAndColumnRegions(List<List<SudokuCell>> cells)
    {
        var regions = new List<SudokuRegion>();

        // 行区域
        for (int r = 0; r < _boardSize; r++)
        {
            regions.Add(new SudokuRegion(
                $"row_{r}",
                RegionType.Row,
                $"第{r + 1}行",
                [.. cells[r]]));
        }

        // 列区域
        for (int c = 0; c < _boardSize; c++)
        {
            var colCells = new List<SudokuCell>();
            for (int r = 0; r < _boardSize; r++)
            {
                colCells.Add(cells[r][c]);
            }
            regions.Add(new SudokuRegion(
                $"col_{c}",
                RegionType.Column,
                $"第{c + 1}列",
                colCells));
        }

        return regions;
    }

    #endregion

    #region 单元格操作命令

    /// <summary>
    /// 选中单元格命令。
    /// 参照Flutter _onCellSelected方法。
    /// </summary>
    /// <param name="cell">选中的单元格。</param>
    [RelayCommand]
    private void SelectCell(SudokuCell cell)
    {
        if (Board is null) return;

        _selectedCell = cell;
        Board = UpdateSelection(Board, cell);
    }

    /// <summary>
    /// 输入数字命令，在选中单元格填入数字。
    /// 参照Flutter _onNumberSelected方法。
    /// </summary>
    /// <param name="number">要填入的数字（1-9）。</param>
    [RelayCommand]
    private void InputNumber(int number)
    {
        if (_selectedCell is null || Board is null) return;

        var row = _selectedCell.Row;
        var col = _selectedCell.Col;

        // 如果输入的数字与当前值相同，则清除
        int? newValue = Board.Cells[row][col].Value == number ? null : number;

        var newCells = DeepCopyCells();
        newCells[row][col] = newCells[row][col].SetValue(newValue);

        Board = new CustomGameBoard(_boardSize, newCells, [.. Board.Regions], _gameType);
        Board = UpdateSelection(Board, _selectedCell);
        ValidationMessage = string.Empty;
    }

    /// <summary>
    /// 更新选中状态和高亮状态。
    /// 参照Flutter _updateSelection方法。
    /// </summary>
    private CustomGameBoard UpdateSelection(Board board, SudokuCell? selectedCell)
    {
        var selectedValue = selectedCell != null
            ? board.Cells[selectedCell.Row][selectedCell.Col].Value
            : null;

        var newCells = new List<List<SudokuCell>>();
        for (int r = 0; r < _boardSize; r++)
        {
            var row = new List<SudokuCell>();
            for (int c = 0; c < _boardSize; c++)
            {
                var cell = board.Cells[r][c];
                bool isSelected = selectedCell != null && r == selectedCell.Row && c == selectedCell.Col;
                bool isHighlighted = selectedValue != null && cell.Value == selectedValue;

                row.Add(cell.CopyWith(
                    isSelected: isSelected,
                    isHighlighted: isHighlighted));
            }
            newCells.Add(row);
        }

        return new CustomGameBoard(_boardSize, newCells, [.. board.Regions], _gameType);
    }

    #endregion

    #region 功能命令

    /// <summary>
    /// 清除棋盘命令，显示确认对话框后清除所有单元格。
    /// 参照Flutter _showClearConfirmDialog方法。
    /// </summary>
    [RelayCommand]
    private async Task ClearBoard()
    {
        bool confirm = await Shell.Current.DisplayAlertAsync(
            AppResources.CustomGame,
            "确定要清除棋盘吗？",
            AppResources.OK,
            AppResources.Cancel);

        if (confirm)
        {
            InitializeBoard();
            ValidationMessage = string.Empty;
        }
    }

    /// <summary>
    /// 验证并开始游戏命令。
    /// 参照Flutter _validateAndStartGame方法。
    /// </summary>
    [RelayCommand]
    private async Task StartGame()
    {
        if (IsValidating || Board is null) return;

        IsValidating = true;

        try
        {
            // 1. 检查最小填入数量
            var filledCells = Board.GetFilledCells().Count;
            if (filledCells < _minFilledCells)
            {
                await CustomGameViewModel.ShowErrorDialog($"请至少填入 {_minFilledCells} 个数字");
                return;
            }

            // 2. 验证棋盘有效性
            if (!_gameService.ValidateBoard(Board))
            {
                await CustomGameViewModel.ShowErrorDialog("棋盘存在冲突，请检查是否有重复数字");
                return;
            }

            // 3. 检查唯一解
            bool hasUniqueSolution = await CheckUniqueSolutionAsync();
            if (!hasUniqueSolution)
            {
                await CustomGameViewModel.ShowErrorDialog("当前棋盘没有唯一解，请调整数字");
                return;
            }

            // 4. 创建游戏初始状态（将填入的数字标记为固定）
            var initialCells = new List<List<SudokuCell>>();
            for (int r = 0; r < _boardSize; r++)
            {
                var row = new List<SudokuCell>();
                for (int c = 0; c < _boardSize; c++)
                {
                    var cell = Board.Cells[r][c];
                    row.Add(cell.CopyWith(isFixed: cell.Value != null));
                }
                initialCells.Add(row);
            }

            var initialBoard = new CustomGameBoard(_boardSize, initialCells, [.. Board.Regions], _gameType);

            // 5. 保存并开始游戏
            await SaveAndNavigateToGameAsync(initialBoard);
        }
        finally
        {
            IsValidating = false;
        }
    }

    /// <summary>
    /// 检查棋盘是否有唯一解。
    /// 参照Flutter _checkUniqueSolution和_countSolutions方法。
    /// </summary>
    private async Task<bool> CheckUniqueSolutionAsync()
    {
        if (Board is null) return false;

        // 将棋盘转换为求解器格式
        var boardArray = new int[_boardSize, _boardSize];
        for (int r = 0; r < _boardSize; r++)
        {
            for (int c = 0; c < _boardSize; c++)
            {
                boardArray[r, c] = Board.Cells[r][c].Value ?? 0;
            }
        }

        // 在后台线程计算解的数量
        return await Task.Run(() =>
        {
            int solutionCount = 0;
            CountSolutions(boardArray, 0, 0, ref solutionCount);
            return solutionCount == 1;
        });
    }

    /// <summary>
    /// 递归计算解的数量。
    /// 参照Flutter _countSolutions方法。
    /// </summary>
    private void CountSolutions(int[,] board, int row, int col, ref int solutionCount)
    {
        if (solutionCount >= _maxSolutionsToCheck) return;

        if (row == _boardSize)
        {
            solutionCount++;
            return;
        }

        int nextRow = col == _boardSize - 1 ? row + 1 : row;
        int nextCol = col == _boardSize - 1 ? 0 : col + 1;

        if (board[row, col] != 0)
        {
            CountSolutions(board, nextRow, nextCol, ref solutionCount);
            return;
        }

        for (int num = 1; num <= _boardSize; num++)
        {
            if (IsValidPlacement(board, row, col, num))
            {
                board[row, col] = num;
                CountSolutions(board, nextRow, nextCol, ref solutionCount);
                board[row, col] = 0;

                if (solutionCount >= _maxSolutionsToCheck) return;
            }
        }
    }

    /// <summary>
    /// 检查数字放置是否有效。
    /// </summary>
    private bool IsValidPlacement(int[,] board, int row, int col, int num)
    {
        // 检查行
        for (int c = 0; c < _boardSize; c++)
        {
            if (board[row, c] == num) return false;
        }

        // 检查列
        for (int r = 0; r < _boardSize; r++)
        {
            if (board[r, col] == num) return false;
        }

        // 检查宫格
        int startRow = (row / _boxSize) * _boxSize;
        int startCol = (col / _boxSize) * _boxSize;
        for (int r = startRow; r < startRow + _boxSize; r++)
        {
            for (int c = startCol; c < startCol + _boxSize; c++)
            {
                if (r < _boardSize && c < _boardSize && board[r, c] == num) return false;
            }
        }

        return true;
    }

    /// <summary>
    /// 显示错误对话框。
    /// 参照Flutter _showErrorDialog方法。
    /// </summary>
    private static async Task ShowErrorDialog(string message)
    {
        await Shell.Current.DisplayAlertAsync(
            AppResources.Error,
            message,
            AppResources.OK);
    }

    /// <summary>
    /// 保存自定义游戏并导航到游戏页面。
    /// </summary>
    private async Task SaveAndNavigateToGameAsync(Board initialBoard)
    {
        try
        {
            // 序列化棋盘
            var boardJson = SerializeBoard(initialBoard);

            // 保存到存储
            await GameStorageService.SaveCustomGameAsync(
                _gameType,
                boardJson,
                string.Empty,
                "自定义游戏");

            // 导航到游戏页面
            await NavigationService.GoToAsync(nameof(Views.GamePage), new Dictionary<string, object>
            {
                { "GameType", _gameType },
                { "Difficulty", Difficulty.Custom },
                { "IsNewGame", true },
                { "CustomBoardJson", boardJson }
            });
        }
        catch (Exception ex)
        {
            await CustomGameViewModel.ShowErrorDialog($"保存失败：{ex.Message}");
        }
    }

    /// <summary>
    /// 返回菜单命令。
    /// </summary>
    [RelayCommand]
    private static async Task BackToMenu()
    {
        await NavigationService.GoBackAsync();
    }

    /// <summary>
    /// 设置页面导航命令。
    /// </summary>
    [RelayCommand]
    private static async Task Settings()
    {
        await Shell.Current.Navigation.PushAsync(new Views.SettingsPage());
    }

    #endregion

    #region 辅助方法

    /// <summary>
    /// 深拷贝单元格列表。
    /// </summary>
    private List<List<SudokuCell>> DeepCopyCells()
    {
        if (Board is null) return [];

        var newCells = new List<List<SudokuCell>>();
        for (int r = 0; r < _boardSize; r++)
        {
            var row = new List<SudokuCell>();
            for (int c = 0; c < _boardSize; c++)
            {
                row.Add(Board.Cells[r][c]);
            }
            newCells.Add(row);
        }
        return newCells;
    }

    /// <summary>
    /// 更新棋盘统计信息。
    /// </summary>
    private void UpdateBoardStats()
    {
        OnPropertyChanged(nameof(NumberCounts));
    }

    /// <summary>
    /// 更新是否可以开始游戏。
    /// </summary>
    private void UpdateCanStartGame()
    {
        if (Board is null)
        {
            CanStartGame = false;
            return;
        }

        var filledCells = Board.GetFilledCells().Count;
        CanStartGame = filledCells >= _minFilledCells;
    }

    /// <summary>
    /// 序列化棋盘为JSON字符串。
    /// </summary>
    private static string SerializeBoard(Board board)
    {
        var cells = new List<List<int?>>();
        for (int r = 0; r < board.Size; r++)
        {
            var row = new List<int?>();
            for (int c = 0; c < board.Size; c++)
            {
                row.Add(board.Cells[r][c].Value);
            }
            cells.Add(row);
        }
        return System.Text.Json.JsonSerializer.Serialize(cells);
    }

    #endregion
}

/// <summary>
/// 自定义游戏棋盘实现类。
/// </summary>
public sealed record CustomGameBoard : Board
{
    /// <summary>
    /// 初始化自定义游戏棋盘。
    /// </summary>
    public CustomGameBoard(int size, List<List<SudokuCell>> cells, List<SudokuRegion> regions, GameType gameType)
        : base(size, cells.Select(r => r.Cast<SudokuCell>().ToList()).ToList(), regions)
    {
        GameTypeValue = gameType;
    }

    /// <summary>
    /// 获取游戏类型。
    /// </summary>
    public override string GameType => GameTypeValue.ToString();

    /// <summary>
    /// 获取游戏类型值。
    /// </summary>
    public GameType GameTypeValue { get; }

    /// <summary>
    /// 创建新实例。
    /// </summary>
    public override Board CreateInstance(IReadOnlyList<IReadOnlyList<SudokuCell>> newCells, IReadOnlyList<SudokuRegion>? regions)
    {
        var cells = newCells.Select(r => r.ToList()).ToList();
        return new CustomGameBoard(Size, cells, regions?.ToList() ?? [], GameTypeValue);
    }
}
