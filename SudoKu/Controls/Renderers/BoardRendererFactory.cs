namespace SudoKu.Controls.Renderers;

using SudoKu.Models;

public static class BoardRendererFactory
{
    // RegisterRenderer 已移除：工厂返回新实例，且不支持运行时注册。
    // 为每个请求创建一个新的渲染器实例。渲染器保存瞬态视图状态（类似于 _cellViews）
    // 因此返回单例对象可能会导致状态过时和索引错误
    // 在切换游戏类型或棋盘时。
    public static IBoardRenderer GetRenderer(GameType gameType)
    {
        return gameType switch
        {
            GameType.Standard => new StandardBoardRenderer(),
            GameType.Diagonal => new DiagonalBoardRenderer(),
            GameType.Jigsaw => new JigsawBoardRenderer(),
            GameType.Killer => new KillerBoardRenderer(),
            GameType.Samurai => new SamuraiBoardRenderer(),
            GameType.Window => new WindowBoardRenderer(),
            _ => new StandardBoardRenderer()
        };
    }

}
