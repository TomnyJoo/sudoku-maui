namespace SudoKu.ViewModels.Mixins;

public class GamePropertyNotificationHandler
{
    private readonly Action<string> _notifyPropertyChanged;
    private readonly Action _notifyAllCommands;

    public GamePropertyNotificationHandler(
        Action<string> notifyPropertyChanged,
        Action notifyAllCommands)
    {
        _notifyPropertyChanged = notifyPropertyChanged;
        _notifyAllCommands = notifyAllCommands;
    }

    public void NotifyGameStateChanged()
    {
        var props = new[] {
            nameof(ViewModels.GameViewModel.Board),
            nameof(ViewModels.GameViewModel.CanUndo),
            nameof(ViewModels.GameViewModel.CanRedo),
            nameof(ViewModels.GameViewModel.CanSelectCell),
            nameof(ViewModels.GameViewModel.IsMarkMode),
            nameof(ViewModels.GameViewModel.IsAutoMarkMode),
            nameof(ViewModels.GameViewModel.NumberCounts),
            nameof(ViewModels.GameViewModel.LocalizedDifficulty)
        };

        foreach (var prop in props)
            _notifyPropertyChanged(prop);

        _notifyAllCommands();
    }

    public void NotifyTimerTick()
    {
        _notifyPropertyChanged(nameof(ViewModels.GameViewModel.ElapsedTimeDisplay));
    }

    public void NotifyPropertyChanged(string propertyName)
    {
        _notifyPropertyChanged(propertyName);
    }
}
