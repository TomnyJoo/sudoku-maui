namespace SudoKu.Controls;

using Microsoft.Maui.Controls;

public class OverlayManager
{
    private readonly List<View> _overlays = new();
    private readonly AbsoluteLayout _container;

    public OverlayManager(AbsoluteLayout container)
    {
        _container = container;
    }

    public void AddOverlay(View overlay, double left = 0, double top = 0, double right = 1, double bottom = 1)
    {
        if (!_overlays.Contains(overlay))
        {
            _overlays.Add(overlay);
            AbsoluteLayout.SetLayoutBounds(overlay, new Rect(left, top, right - left, bottom - top));
            AbsoluteLayout.SetLayoutFlags(overlay, Microsoft.Maui.Layouts.AbsoluteLayoutFlags.PositionProportional);
            _container.Add(overlay);
        }
    }

    public void RemoveOverlay(View overlay)
    {
        if (_overlays.Remove(overlay))
        {
            _container.Remove(overlay);
        }
    }

    public void ClearOverlays()
    {
        foreach (var overlay in _overlays.ToList())
        {
            _container.Remove(overlay);
        }
        _overlays.Clear();
    }

    public void SetOverlaysEnabled(bool enabled)
    {
        foreach (var overlay in _overlays)
        {
            overlay.IsVisible = enabled;
        }
    }

    public IReadOnlyList<View> GetOverlays() => _overlays.AsReadOnly();

    public bool HasOverlay(View overlay) => _overlays.Contains(overlay);
}
