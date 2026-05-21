namespace SudoKu.ViewModels;

using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

/// <summary>
/// ViewModel 基类，提供通用的属性和初始化接口。
/// 所有 ViewModel 均继承此类以获得 IsBusy 和 Title 的绑定支持。
/// 参照 Flutter 的 ChangeNotifier 模式实现。
/// </summary>
public abstract partial class BaseViewModel : ObservableObject
{
    /// <summary>
    /// 是否正在执行异步操作的后备字段。
    /// </summary>
    private bool _isBusy;

    /// <summary>
    /// 页面标题的后备字段。
    /// </summary>
    private string _title = string.Empty;

    /// <summary>
    /// 获取或设置是否正在执行异步操作。
    /// </summary>
    public bool IsBusy
    {
        get => _isBusy;
        set => SetProperty(ref _isBusy, value);
    }

    /// <summary>
    /// 获取或设置页面标题。
    /// </summary>
    public string Title
    {
        get => _title;
        set => SetProperty(ref _title, value);
    }

    /// <summary>
    /// 异步初始化 ViewModel 数据，在页面导航到时调用。
    /// </summary>
    /// <param name="parameter">导航参数，可为 null。</param>
    /// <returns>初始化完成的任务。</returns>
    public virtual Task InitializeAsync(object? parameter = null) => Task.CompletedTask;

    /// <summary>
    /// 异步清理 ViewModel 资源，在页面离开时调用。
    /// </summary>
    /// <returns>清理完成的任务。</returns>
    public virtual Task CleanupAsync() => Task.CompletedTask;

    /// <summary>
    /// 通知所有属性已更改。
    /// 用于在复杂状态更新后统一刷新 UI。
    /// </summary>
    protected void NotifyAllPropertiesChanged()
    {
        OnPropertyChanged(string.Empty);
    }
}
