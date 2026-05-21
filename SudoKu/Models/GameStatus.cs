namespace SudoKu.Models;

/// <summary>
/// 游戏状态枚举，表示当前游戏的基本状态。
/// </summary>
public enum GameStatus
{
    /// <summary>游戏尚未开始。</summary>
    NotStarted,

    /// <summary>游戏正在进行中。</summary>
    Playing,

    /// <summary>游戏已暂停。</summary>
    Paused,

    /// <summary>游戏已完成。</summary>
    Completed
}

/// <summary>
/// 游戏生命周期状态枚举，表示游戏在生成和游玩过程中的详细阶段。
/// </summary>
public enum GameLifecycleState
{
    /// <summary>空闲状态，无活跃游戏。</summary>
    Idle,

    /// <summary>正在生成谜题。</summary>
    Generating,

    /// <summary>正在游玩中。</summary>
    Playing,

    /// <summary>游戏已暂停。</summary>
    Paused,

    /// <summary>游戏已完成。</summary>
    Completed,

    /// <summary>生成或加载失败。</summary>
    Failed
}
