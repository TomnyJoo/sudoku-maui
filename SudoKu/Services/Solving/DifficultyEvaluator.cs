namespace SudoKu.Services.Solving;

using SudoKu.Models;

/// <summary>
/// 难度评估器，根据谜题分析结果评估谜题的实际难度。
/// 综合考虑所需策略等级、策略种类和空单元格数量。
/// </summary>
public class DifficultyEvaluator
{
    /// <summary>
    /// 根据策略使用情况评估谜题难度。
    /// </summary>
    /// <param name="usedStrategies">求解过程中使用的策略类型列表。</param>
    /// <param name="emptyCellCount">谜题中空单元格的数量。</param>
    /// <returns>评估出的难度等级。</returns>
    public static Difficulty EvaluateDifficulty(List<StrategyType> usedStrategies, int emptyCellCount)
    {
        if (usedStrategies.Count == 0)
            return Difficulty.Beginner;

        var maxLevel = GetMaxStrategyLevel(usedStrategies);
        var strategyVariety = usedStrategies.Distinct().Count();

        return maxLevel switch
        {
            StrategyLevel.Basic when strategyVariety <= 2 => Difficulty.Beginner,
            StrategyLevel.Basic => Difficulty.Easy,
            StrategyLevel.Intermediate when strategyVariety <= 3 => Difficulty.Medium,
            StrategyLevel.Intermediate => Difficulty.Hard,
            StrategyLevel.Advanced when strategyVariety <= 3 => Difficulty.Hard,
            StrategyLevel.Advanced => Difficulty.Expert,
            StrategyLevel.Expert => Difficulty.Expert,
            StrategyLevel.Master => Difficulty.Master,
            _ => Difficulty.Medium
        };
    }

    /// <summary>
    /// 根据难度等级获取对应的策略等级范围。
    /// </summary>
    /// <param name="difficulty">难度等级。</param>
    /// <returns>该难度对应的最低和最高策略等级元组。</returns>
    public static (StrategyLevel minLevel, StrategyLevel maxLevel) GetStrategyLevelRange(Difficulty difficulty)
    {
        return difficulty switch
        {
            Difficulty.Beginner => (StrategyLevel.Basic, StrategyLevel.Basic),
            Difficulty.Easy => (StrategyLevel.Basic, StrategyLevel.Intermediate),
            Difficulty.Medium => (StrategyLevel.Basic, StrategyLevel.Intermediate),
            Difficulty.Hard => (StrategyLevel.Intermediate, StrategyLevel.Advanced),
            Difficulty.Expert => (StrategyLevel.Advanced, StrategyLevel.Expert),
            Difficulty.Master => (StrategyLevel.Expert, StrategyLevel.Master),
            _ => (StrategyLevel.Basic, StrategyLevel.Intermediate)
        };
    }

    /// <summary>
    /// 获取策略列表中的最高策略等级。
    /// </summary>
    /// <param name="strategies">策略类型列表。</param>
    /// <returns>最高策略等级。</returns>
    private static StrategyLevel GetMaxStrategyLevel(List<StrategyType> strategies)
    {
        var maxLevel = StrategyLevel.Basic;

        foreach (var strategyType in strategies)
        {
            try
            {
                var info = StrategyMetadata.GetInfo(strategyType);
                if ((int)info.Level > (int)maxLevel)
                    maxLevel = info.Level;
            }
            catch
            {
                // 忽略未注册的策略类型
            }
        }

        return maxLevel;
    }
}
