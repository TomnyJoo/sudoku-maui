namespace SudoKu.Controls;

/// <summary>
/// 游戏标题栏控件，显示返回按钮、游戏名称和功能按钮。
/// </summary>
public partial class GameTitleBar : ContentView
{
    /// <summary>
    /// 标识 BackCommand 绑定属性。
    /// </summary>
    public static readonly BindableProperty BackCommandProperty =
        BindableProperty.Create(nameof(BackCommand), typeof(Command), typeof(GameTitleBar), null);

    /// <summary>
    /// 标识 RulesCommand 绑定属性。
    /// </summary>
    public static readonly BindableProperty RulesCommandProperty =
        BindableProperty.Create(nameof(RulesCommand), typeof(Command), typeof(GameTitleBar), null);

    /// <summary>
    /// 标识 SettingsCommand 绑定属性。
    /// </summary>
    public static readonly BindableProperty SettingsCommandProperty =
        BindableProperty.Create(nameof(SettingsCommand), typeof(Command), typeof(GameTitleBar), null);

    /// <summary>
    /// 标识 PauseCommand 绑定属性。
    /// </summary>
    public static readonly BindableProperty PauseCommandProperty =
        BindableProperty.Create(nameof(PauseCommand), typeof(Command), typeof(GameTitleBar), null);

    /// <summary>
    /// 标识 Title 绑定属性。
    /// </summary>
    public static readonly BindableProperty TitleProperty =
        BindableProperty.Create(nameof(Title), typeof(string), typeof(GameTitleBar), string.Empty);

    /// <summary>获取或设置返回命令。</summary>
    public Command? BackCommand
    {
        get => (Command?)GetValue(BackCommandProperty);
        set => SetValue(BackCommandProperty, value);
    }

    /// <summary>获取或设置规则命令。</summary>
    public Command? RulesCommand
    {
        get => (Command?)GetValue(RulesCommandProperty);
        set => SetValue(RulesCommandProperty, value);
    }

    /// <summary>获取或设置设置命令。</summary>
    public Command? SettingsCommand
    {
        get => (Command?)GetValue(SettingsCommandProperty);
        set => SetValue(SettingsCommandProperty, value);
    }

    /// <summary>获取或设置暂停命令。</summary>
    public Command? PauseCommand
    {
        get => (Command?)GetValue(PauseCommandProperty);
        set => SetValue(PauseCommandProperty, value);
    }

    /// <summary>获取或设置标题文本。</summary>
    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    /// <summary>
    /// 初始化游戏标题栏的新实例。
    /// </summary>
    public GameTitleBar()
    {
        var grid = new Grid
        {
            Padding = new Thickness(16, 8),
            ColumnSpacing = 16,
            BackgroundColor = (Color)Application.Current!.Resources["TitleBarBackgroundColor"]
        };

        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Star });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Back button
        var backButton = new Button
        {
            Text = "&lt;",
            FontSize = 20,
            Style = (Style)Application.Current!.Resources["IconButton"]
        };
        backButton.SetBinding(Button.CommandProperty, new Binding(nameof(BackCommand), source: this));
        grid.Add(backButton, 0, 0);

        // Title label
        var titleLabel = new Label
        {
            FontSize = 16,
            FontAttributes = FontAttributes.Bold,
            VerticalOptions = LayoutOptions.Center,
            HorizontalOptions = LayoutOptions.Center
        };
        titleLabel.SetBinding(Label.TextProperty, new Binding(nameof(Title), source: this));
        grid.Add(titleLabel, 1, 0);

        // Right side buttons
        var rightStack = new HorizontalStackLayout { Spacing = 8 };

        var rulesButton = new Button
        {
            Text = "?",
            FontSize = 16,
            Style = (Style)Application.Current!.Resources["IconButton"]
        };
        rulesButton.SetBinding(Button.CommandProperty, new Binding(nameof(RulesCommand), source: this));
        rightStack.Add(rulesButton);

        var settingsButton = new Button
        {
            Text = "⚙",
            FontSize = 16,
            Style = (Style)Application.Current!.Resources["IconButton"]
        };
        settingsButton.SetBinding(Button.CommandProperty, new Binding(nameof(SettingsCommand), source: this));
        rightStack.Add(settingsButton);

        grid.Add(rightStack, 2, 0);

        Content = grid;
    }
}
