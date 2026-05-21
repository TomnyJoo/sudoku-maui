using SQLite;

namespace SudoKu.Services.Storage.Database;

/// <summary>
/// 数独数据库类，管理SQLite数据库的初始化和连接。
/// 使用单例模式确保全局唯一的数据库连接。
/// </summary>
public class SudokuDatabase
{
    private static SQLiteAsyncConnection? _database;
    private static readonly SemaphoreSlim _initLock = new(1, 1);
    private static bool _isInitialized;
    private static Task? _initializationTask;

    /// <summary>
    /// 获取数据库异步连接实例，延迟初始化。
    /// 如果初始化尚未完成，将等待初始化完成。
    /// </summary>
    public static SQLiteAsyncConnection Database
    {
        get
        {
            if (_database == null)
            {
                throw new InvalidOperationException("数据库尚未初始化。请先调用 InitializeAsync() 方法。");
            }
            return _database;
        }
    }

    /// <summary>
    /// 获取一个任务，该任务在数据库初始化完成时完成。
    /// 供服务层在访问数据库前等待使用。
    /// </summary>
    public static Task InitializationCompletedTask
    {
        get
        {
            if (_isInitialized)
                return Task.CompletedTask;
            return _initializationTask ?? InitializeAsync().ContinueWith(_ => { });
        }
    }

    /// <summary>
    /// 异步初始化数据库连接。
    /// 如果已经正在初始化，则返回现有任务，不会重复初始化。
    /// </summary>
    public static Task InitializeAsync()
    {
        if (_isInitialized)
            return Task.CompletedTask;

        if (_initializationTask != null)
            return _initializationTask;

        _initializationTask = DoInitializeAsync();
        return _initializationTask;
    }

    private static async Task DoInitializeAsync()
    {
        await _initLock.WaitAsync();
        try
        {
            if (_isInitialized)
                return;

            await InitAsync();
            _isInitialized = true;
        }
        finally
        {
            _initLock.Release();
        }
    }

    /// <summary>
    /// 初始化数据库连接，创建必要的表和索引。
    /// </summary>
    private static async Task InitAsync()
    {
        var path = Path.Combine(FileSystem.AppDataDirectory, "sudokucollection.db");
        
        // 确保目录存在
        var directory = Path.GetDirectoryName(path);
        if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
        {
            Directory.CreateDirectory(directory);
        }

        _database = new SQLiteAsyncConnection(
            path,
            SQLiteOpenFlags.ReadWrite | SQLiteOpenFlags.Create | SQLiteOpenFlags.FullMutex);

        // 使用 QueryAsync 替代 ExecuteAsync 来执行 PRAGMA，因为 PRAGMA 有时会返回结果导致 ExecuteAsync 报错
        try 
        {
            await _database.QueryAsync<int>("PRAGMA journal_mode=WAL;");
        }
        catch (Exception ex)
        {
            // 如果 WAL 模式开启失败，记录日志但继续执行，避免程序崩溃
            System.Diagnostics.Debug.WriteLine($"SQLite WAL mode failed: {ex.Message}");
        }

        await _database.CreateTableAsync<GameSaveEntity>();
        await _database.CreateTableAsync<GameRecordEntity>();
        await _database.CreateTableAsync<CustomGameEntity>();

        // 注意：字段名必须与实体类中 [Column] 特性定义的名称或属性名一致
        await _database.ExecuteAsync("CREATE UNIQUE INDEX IF NOT EXISTS idx_gamesave_type_diff ON GameSave(GameType, DifficultyStr)");
        await _database.ExecuteAsync("CREATE INDEX IF NOT EXISTS idx_gamerecord_type_diff ON GameRecord(GameTypeStr, DifficultyStr)");
        await _database.ExecuteAsync("CREATE INDEX IF NOT EXISTS idx_gamerecord_completed ON GameRecord(IsCompleted)");
    }
}
