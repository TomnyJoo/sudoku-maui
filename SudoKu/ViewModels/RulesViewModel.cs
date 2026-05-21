namespace SudoKu.ViewModels;

using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.Input;
using SudoKu.Models;

/// <summary>
/// 规则页面 ViewModel，展示各游戏类型的规则说明。
/// </summary>
public partial class RulesViewModel : BaseViewModel
{
    private GameType _selectedGameType = GameType.Standard;

    /// <summary>
    /// 初始化规则 ViewModel 的新实例。
    /// </summary>
    public RulesViewModel()
    {
        Title = "游戏规则";
        LoadRules();
    }

    /// <summary>获取或设置当前选中的游戏类型。</summary>
    public GameType SelectedGameType
    {
        get => _selectedGameType;
        set => SetProperty(ref _selectedGameType, value);
    }

    /// <summary>获取游戏规则列表。</summary>
    public ObservableCollection<GameRuleDisplay> GameRules { get; } = new();

    /// <summary>返回上一页面导航命令</summary>
    [RelayCommand]
    private static async Task Back()
    {
        if (Shell.Current.Navigation.NavigationStack.Count > 1)
            await Shell.Current.Navigation.PopAsync();
        else
            await Shell.Current.GoToAsync("//home");
    }

    /// <summary>
    /// 选择游戏类型命令，筛选显示对应类型的规则。
    /// </summary>
    [RelayCommand]
    private void SelectGameType(GameType type)
    {
        SelectedGameType = type;
    }

    /// <summary>
    /// 加载所有游戏类型的规则说明。
    /// </summary>
    private void LoadRules()
    {
        GameRules.Clear();

        GameRules.Add(new GameRuleDisplay
        {
            GameType = GameType.Standard,
            Title = "标准数独",
            Description = "在9x9的棋盘中填入1-9的数字，使每行、每列和每个3x3宫格内的数字不重复。",
            Rules = new List<string>
            {
                "每行包含1-9的所有数字，不重复",
                "每列包含1-9的所有数字，不重复",
                "每个3x3宫格包含1-9的所有数字，不重复",
                "部分数字已预先填入作为提示",
                "目标是用逻辑推理填满整个棋盘"
            }
        });

        GameRules.Add(new GameRuleDisplay
        {
            GameType = GameType.Jigsaw,
            Title = "锯齿数独",
            Description = "与标准数独类似，但宫格形状为不规则的多边形区域。",
            Rules = new List<string>
            {
                "每行包含1-9的所有数字，不重复",
                "每列包含1-9的所有数字，不重复",
                "每个不规则宫格包含1-9的所有数字，不重复",
                "宫格的形状和大小各不相同",
                "需要根据宫格边界进行推理"
            }
        });

        GameRules.Add(new GameRuleDisplay
        {
            GameType = GameType.Diagonal,
            Title = "对角线数独",
            Description = "在标准数独的基础上，增加两条主对角线的约束条件。",
            Rules = new List<string>
            {
                "满足标准数独的所有规则",
                "主对角线（左上到右下）包含1-9的所有数字，不重复",
                "副对角线（右上到左下）包含1-9的所有数字，不重复",
                "对角线约束提供了额外的推理线索",
                "适合已经熟悉标准数独的玩家"
            }
        });

        GameRules.Add(new GameRuleDisplay
        {
            GameType = GameType.Window,
            Title = "窗口数独（Windoku）",
            Description = "在标准数独的基础上，增加四个窗口区域的约束条件。",
            Rules = new List<string>
            {
                "满足标准数独的所有规则",
                "四个窗口区域（位于棋盘内部）各包含1-9的数字，不重复",
                "窗口区域为固定的3x3区域，位于宫格交叉处",
                "窗口约束与宫格约束相互补充",
                "需要综合考虑多种约束进行推理"
            }
        });

        GameRules.Add(new GameRuleDisplay
        {
            GameType = GameType.Killer,
            Title = "杀手数独",
            Description = "不提供预填数字，而是通过笼子（Cage）的数字之和作为提示。",
            Rules = new List<string>
            {
                "每行包含1-9的所有数字，不重复",
                "每列包含1-9的所有数字，不重复",
                "每个3x3宫格包含1-9的所有数字，不重复",
                "每个虚线笼子内的数字之和等于标注的数值",
                "同一笼子内的数字不能重复",
                "需要通过和值推理来确定数字"
            }
        });

        GameRules.Add(new GameRuleDisplay
        {
            GameType = GameType.Samurai,
            Title = "武士数独",
            Description = "由五个9x9标准数独棋盘重叠组成的超大谜题。",
            Rules = new List<string>
            {
                "由五个标准9x9数独棋盘组成",
                "中央一个完整棋盘，四个角落各一个棋盘",
                "角落棋盘与中央棋盘有3x3的重叠区域",
                "每个子棋盘都满足标准数独规则",
                "重叠区域的数字必须同时满足两个棋盘的约束",
                "棋盘总尺寸为21x21",
                "难度较高，适合高级玩家"
            }
        });
    }
}

/// <summary>
/// 游戏规则显示模型，用于UI层展示游戏规则信息。
/// </summary>
public class GameRuleDisplay
{
    /// <summary>获取或设置游戏类型。</summary>
    public GameType GameType { get; set; }

    /// <summary>获取或设置规则标题。</summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>获取或设置规则简要描述。</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>获取或设置详细规则列表。</summary>
    public List<string> Rules { get; set; } = new();
}
