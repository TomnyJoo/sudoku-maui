import 'package:flutter/material.dart';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/l10n/localization_utils.dart';
import 'package:sudoku/theme/responsive_layout.dart';

/// 通用新游戏确认对话框，确认用户是否要开始新游戏（可能会丢失当前进度）
class NewGameConfirmDialog extends StatelessWidget {

  const NewGameConfirmDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final responsiveBorderRadius = ResponsiveLayout.getResponsiveBorderRadius(context);
    final dialogBackgroundColor = Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;
    final l10n = LocalizationUtils.app(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
      ),
      backgroundColor: dialogBackgroundColor,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.dialogPadding),
        decoration: BoxDecoration(
          color: dialogBackgroundColor,
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber,
              size: AppConstants.iconSizeLarge,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              l10n.newGameConfirm,
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(18, context),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              l10n.newGameConfirmContent,
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(14, context),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppConstants.spacingHuge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMedium),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 通用确认对话框
/// 
/// 适用于各种需要用户确认的操作
class GenericConfirmDialog extends StatelessWidget {

  const GenericConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    required this.onCancel,
    this.icon,
    this.iconColor,
  });
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final responsiveBorderRadius = ResponsiveLayout.getResponsiveBorderRadius(context);
    final dialogBackgroundColor = Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsiveBorderRadius),
      ),
      backgroundColor: dialogBackgroundColor,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.dialogPadding),
        decoration: BoxDecoration(
          color: dialogBackgroundColor,
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: AppConstants.iconSizeLarge,
                color: iconColor ?? Theme.of(context).colorScheme.error,
              ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(18, context),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              message,
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(14, context),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppConstants.spacingHuge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    cancelText,
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMedium),
                ElevatedButton(
                  onPressed: onConfirm,
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
