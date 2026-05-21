namespace SudoKu.Services;

using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Serialization;
using SudoKu.Services.Storage.Database;
using System.Text.Json;

/// <summary>
/// 游戏存储服务实现类，使用 SQLite-net-pcl 持久化游戏存档和自定义游戏。
/// 通过 SudokuDatabase 管理数据库连接，使用 System.Text.Json 序列化游戏状态。
/// </summary>
public class GameStorageService
{
    private readonly SudokuDatabase _database;
    private readonly JsonSerializerOptions _jsonOptions;

    /// <summary>
    /// 初始化游戏存储服务的新实例。
    /// </summary>
    /// <param name="database">数独数据库实例，通过依赖注入提供。</param>
    public GameStorageService(SudokuDatabase database)
    {
        _database = database;
        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = false,
            Converters = { new BoardJsonConverter() }
        };
    }

    /// <inheritdoc/>
    public async Task SaveGameAsync(GameState<Board> gameState)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var json = JsonSerializer.Serialize(gameState, _jsonOptions);
        
        var gameTypeStr = gameState.GameType.ToString();
        var difficultyStr = gameState.Difficulty.ToString();

        var existing = await SudokuDatabase.Database
            .Table<GameSaveEntity>()
            .Where(e => e.GameTypeStr == gameTypeStr
                      && e.DifficultyStr == difficultyStr)
            .FirstOrDefaultAsync();

        if (existing is not null)
        {
            existing.GameStateJson = json;
            existing.LastPlayedAt = DateTime.Now;
            await SudokuDatabase.Database.UpdateAsync(existing);
        }
        else
        {
            var entity = new GameSaveEntity
            {
                GameTypeStr = gameState.GameType.ToString(),
                DifficultyStr = gameState.Difficulty.ToString(),
                GameStateJson = json,
                SavedAt = DateTime.Now,
                LastPlayedAt = DateTime.Now
            };
            await SudokuDatabase.Database.InsertAsync(entity);
        }
    }

    /// <inheritdoc/>
    public async Task<GameState<Board>?> LoadGameAsync(GameType type, Difficulty difficulty)
    {
        await SudokuDatabase.InitializationCompletedTask;
        
        var gameTypeStr = type.ToString();
        var difficultyStr = difficulty.ToString();
        
        var entity = await SudokuDatabase.Database
            .Table<GameSaveEntity>()
            .Where(e => e.GameTypeStr == gameTypeStr
                      && e.DifficultyStr == difficultyStr)
            .FirstOrDefaultAsync();

        if (entity is null)
            return null;

        try
        {
            return JsonSerializer.Deserialize<GameState<Board>>(entity.GameStateJson, _jsonOptions);
        }
        catch (JsonException)
        {
            return null;
        }
    }

    /// <inheritdoc/>
    public static async Task<bool> HasSavedGameAsync(GameType type, Difficulty difficulty)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var entity = await SudokuDatabase.Database
            .Table<GameSaveEntity>()
            .Where(e => e.GameTypeStr == type.ToString()
                      && e.DifficultyStr == difficulty.ToString())
            .FirstOrDefaultAsync();

        return entity is not null;
    }

    /// <inheritdoc/>
    public static async Task DeleteGameAsync(GameType type, Difficulty difficulty)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var entity = await SudokuDatabase.Database
            .Table<GameSaveEntity>()
            .Where(e => e.GameTypeStr == type.ToString()
                      && e.DifficultyStr == difficulty.ToString())
            .FirstOrDefaultAsync();

        if (entity is not null)
        {
            await SudokuDatabase.Database.DeleteAsync(entity);
        }
    }

    /// <inheritdoc/>
    public static async Task SaveCustomGameAsync(GameType type, string puzzleJson, string solutionJson, string? name = null)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var entity = new CustomGameEntity
        {
            GameTypeStr = type.ToString(),
            PuzzleJson = puzzleJson,
            SolutionJson = solutionJson,
            CreatedAt = DateTime.Now,
            Name = name
        };

        await SudokuDatabase.Database.InsertAsync(entity);
    }

    /// <inheritdoc/>
    public static async Task<List<GameInfo>> LoadCustomGamesAsync(GameType type)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var entities = await SudokuDatabase.Database
            .Table<CustomGameEntity>()
            .Where(e => e.GameTypeStr == type.ToString())
            .OrderByDescending(e => e.CreatedAt)
            .ToListAsync();

        return [.. entities.Select(e => new GameInfo
        {
            Id = e.Id,
            GameType = Enum.Parse<GameType>(e.GameTypeStr),
            PuzzleJson = e.PuzzleJson,
            SolutionJson = e.SolutionJson,
            CreatedAt = e.CreatedAt,
            Name = e.Name!
        })];
    }

    /// <inheritdoc/>
    public static async Task DeleteCustomGameAsync(int id)
    {
        await SudokuDatabase.InitializationCompletedTask;
        await SudokuDatabase.Database.DeleteAsync<CustomGameEntity>(id);
    }

    /// <inheritdoc/>
    public static async Task<bool> HasAnySavedGameAsync(GameType type)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var db = SudokuDatabase.Database;
        var count = await db.Table<GameSaveEntity>()
            .Where(e => e.GameTypeStr == type.ToString())
            .CountAsync();
        return count > 0;
    }

    /// <inheritdoc/>
    public async Task<(Difficulty, DateTime)? > GetSavedGameInfoAsync(GameType type)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var db = SudokuDatabase.Database;
        var entity = await db.Table<GameSaveEntity>()
            .Where(e => e.GameTypeStr == type.ToString())
            .OrderByDescending(e => e.LastPlayedAt)
            .FirstOrDefaultAsync();
        if (entity == null) return null;
        return (Enum.Parse<Difficulty>(entity.DifficultyStr), entity.LastPlayedAt);
    }
}
