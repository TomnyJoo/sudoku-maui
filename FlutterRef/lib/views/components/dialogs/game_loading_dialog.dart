import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 通用游戏加载对话框
/// 
/// 显示加载进度和状态信息
class GameLoadingDialog extends StatelessWidget {

  const GameLoadingDialog({
    super.key,
    this.message,
    this.showProgressIndicator = true,
  });
  final String? message;
  final bool showProgressIndicator;

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
          children: [
            if (showProgressIndicator)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingLarge),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            Text(
              message ?? LocalizationUtils.app(context).loading,
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(16, context),
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 通用异步操作加载对话框
/// 
/// 可以根据异步操作的结果显示不同状态
class AsyncOperationDialog extends StatefulWidget {

  const AsyncOperationDialog({
    super.key,
    required this.operation,
    this.loadingMessage,
    this.successMessage,
    this.errorMessage,
    this.onSuccess,
    this.onError,
  });
  final Future<void> operation;
  final String? loadingMessage;
  final String? successMessage;
  final String? errorMessage;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  @override
  State<AsyncOperationDialog> createState() => _AsyncOperationDialogState();
}

class _AsyncOperationDialogState extends State<AsyncOperationDialog> {
  String _currentMessage = '';
  bool _operationCompleted = false;
  bool _operationSuccessful = false;

  @override
  void initState() {
    super.initState();
    _operationCompleted = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = LocalizationUtils.app(context);
    _currentMessage = widget.loadingMessage ?? l10n.processing;
    _executeOperation();
  }

  Future<void> _executeOperation() async {
    final l10n = LocalizationUtils.app(context);
    try {
      await widget.operation;
      setState(() {
        _currentMessage = widget.successMessage ?? l10n.operationSuccess;
        _operationCompleted = true;
        _operationSuccessful = true;
      });
      if (widget.onSuccess != null) {
        // ignore: prefer_null_aware_method_calls
        widget.onSuccess!();
      }
      // 成功后自动关闭对话框
      Future.delayed(AppConstants.loadingDialogDelay, () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      setState(() {
        _currentMessage = '${widget.errorMessage ?? l10n.operationFailed}: ${e.toString()}';
        _operationCompleted = true;
        _operationSuccessful = false;
      });
      if (widget.onError != null) {
        // ignore: prefer_null_aware_method_calls
        widget.onError!();
      }
    }
  }

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
          children: [
            if (!_operationCompleted)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingLarge),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            Icon(
              _operationCompleted
                  ? (_operationSuccessful ? Icons.check_circle : Icons.error)
                  : Icons.hourglass_empty,
              size: AppConstants.iconSizeLarge,
              color: _operationCompleted
                  ? (_operationSuccessful ? Colors.green : Colors.red)
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveLayout.getResponsiveFontSize(16, context),
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_operationCompleted && !_operationSuccessful)
              Padding(
                padding: const EdgeInsets.only(top: AppConstants.spacingLarge),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(LocalizationUtils.app(context).ok),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
