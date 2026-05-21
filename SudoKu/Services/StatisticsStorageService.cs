namespace SudoKu.Services;

using SudoKu.Models;
using SudoKu.Models.Boards;
using SudoKu.Services.Storage.Database;

/// <summary>
/// 统计存储服务实现类，使用 SQLite-net-pcl 持久化游戏统计数据。
/// 提供游戏记录的插入、查询和聚合统计功能。
/// </summary>
/// <remarks>
/// 初始化统计存储服务的新实例。
/// </remarks>
/// <param name="database">数独数据库实例，通过依赖注入提供。</param>
public class StatisticsStorageService(SudokuDatabase database)
{
    private readonly SudokuDatabase _database = database;

    /// <inheritdoc/>
    public async Task<GameStatistics> GetStatisticsAsync()
    {
        await SudokuDatabase.InitializationCompletedTask;
        var allRecords = await SudokuDatabase.Database.Table<GameRecordEntity>().ToListAsync();

        var completedRecords = allRecords.Where(r => r.IsCompleted).ToList();
        var totalGames = allRecords.Count;
        var totalWon = completedRecords.Count;
        var winRate = totalGames > 0 ? (double)totalWon / totalGames : 0.0;
        var totalPlayTime = allRecords.Sum(r => (long)r.ElapsedTime);
        var totalHints = allRecords.Sum(r => r.HintsUsed);
        var totalErrors = allRecords.Sum(r => r.Mistakes);

        // 计算连胜
        var sortedCompleted = completedRecords
            .OrderByDescending(r => r.CompletedAt)
            .ToList();

        var currentStreak = 0;
        foreach (var record in sortedCompleted)
        {
            if (record.IsCompleted)
                currentStreak++;
            else
                break;
        }

        var bestStreak = CalculateBestStreak(allRecords);

        // 按游戏类型统计
        var gameTypeStats = new Dictionary<GameType, GameTypeStats>();
        foreach (GameType gameType in Enum.GetValues<GameType>())
        {
            var typeRecords = allRecords.Where(r => r.GameTypeStr == gameType.ToString()).ToList();
            var typeCompleted = typeRecords.Where(r => r.IsCompleted).ToList();

            if (typeRecords.Count == 0)
                continue;

            var typeWinRate = (double)typeCompleted.Count / typeRecords.Count;
            var bestTime = typeCompleted.Count > 0 ? typeCompleted.Min(r => r.Time) : 0;
            var avgTime = typeCompleted.Count > 0 ? typeCompleted.Average(r => r.Time) : 0.0;

            var bestScores = new Dictionary<Difficulty, BestScore>();
            foreach (Difficulty diff in Enum.GetValues<Difficulty>())
            {
                var diffBest = await GetBestScoreAsync(gameType, diff);
                if (diffBest is not null)
                {
                    bestScores[diff] = diffBest;
                }
            }

            gameTypeStats[gameType] = new GameTypeStats
            {
                Type = gameType,
                GamesPlayed = typeRecords.Count,
                GamesWon = typeCompleted.Count,
                WinRate = typeWinRate,
                BestTime = bestTime,
                AvgCompletionTime = avgTime,
                BestScores = bestScores
            };
        }

        return new GameStatistics
        {
            TotalGamesPlayed = totalGames,
            TotalGamesWon = totalWon,
            WinRate = winRate,
            CurrentStreak = currentStreak,
            BestStreak = bestStreak,
            TotalPlayTime = totalPlayTime,
            TotalHintsUsed = totalHints,
            TotalErrors = totalErrors,
            GameTypeStats = gameTypeStats
        };
    }

    /// <inheritdoc/>
    public async Task RecordGameAsync(GameType type, Difficulty difficulty, int time, int mistakes, int hintsUsed, bool isCompleted)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var entity = new GameRecordEntity
        {
            GameTypeStr = type.ToString(),
            DifficultyStr = difficulty.ToString(),
            Time = time,
            Mistakes = mistakes,
            HintsUsed = hintsUsed,
            IsCompleted = isCompleted,
            CompletedAt = DateTime.Now,
            ElapsedTime = time,
            Accuracy = 1.0
        };

        await SudokuDatabase.Database.InsertAsync(entity);
        StatisticsUpdated?.Invoke();
    }

    /// <inheritdoc/>
    public Task RecordGameAsync(GameType type, Difficulty difficulty, GameState<Board> result)
    {
        var time = result.ElapsedTime > 0 ? result.ElapsedTime
            : (int)(DateTime.Now - result.StartTime).TotalSeconds;
        return RecordGameAsync(type, difficulty, time, result.Mistakes, result.HintsUsed,
            result.Status == GameStatus.Completed);
    }

    /// <inheritdoc/>
    public async Task<BestScore?> GetBestScoreAsync(GameType type, Difficulty difficulty)
    {
        await SudokuDatabase.InitializationCompletedTask;
        
        var gameTypeStr = type.ToString();
        var difficultyStr = difficulty.ToString();
        
        var entity = await SudokuDatabase.Database
            .Table<GameRecordEntity>()
            .Where(e => e.GameTypeStr == gameTypeStr
                      && e.DifficultyStr == difficultyStr
                      && e.IsCompleted)
            .OrderBy(e => e.Time)
            .FirstOrDefaultAsync();

        if (entity is null)
            return null;

        return new BestScore(entity.Time, entity.Mistakes, entity.CompletedAt);
    }

    /// <inheritdoc/>
    public async Task<bool> IsNewBestScoreAsync(GameType type, Difficulty difficulty, int time, int mistakes)
    {
        await SudokuDatabase.InitializationCompletedTask;
        var best = await GetBestScoreAsync(type, difficulty);
        if (best is null)
            return true;

        // 时间更短或时间相同但错误更少则视为新最佳
        return time < best.Time || (time == best.Time && mistakes < best.Mistakes);
    }

    /// <inheritdoc/>
    public async Task ClearStatisticsAsync()
    {
        await SudokuDatabase.InitializationCompletedTask;
        await SudokuDatabase.Database.DeleteAllAsync<GameRecordEntity>();
        StatisticsUpdated?.Invoke();
    }

    /// <inheritdoc/>
    public event Action? StatisticsUpdated;

    /// <summary>
    /// 计算历史最佳连胜次数。
    /// </summary>
    /// <param name="records">所有游戏记录，按时间升序排列。</param>
    /// <returns>最佳连胜次数。</returns>
    private static int CalculateBestStreak(List<GameRecordEntity> records)
    {
        var sorted = records.OrderBy(r => r.CompletedAt).ToList();
        var bestStreak = 0;
        var currentStreak = 0;

        foreach (var record in sorted)
        {
            if (record.IsCompleted)
            {
                currentStreak++;
                bestStreak = Math.Max(bestStreak, currentStreak);
            }
            else
            {
                currentStreak = 0;
            }
        }

        return bestStreak;
    }
}
