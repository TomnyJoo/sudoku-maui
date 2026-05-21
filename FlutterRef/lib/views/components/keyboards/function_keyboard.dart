import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 功能键盘组件
///
/// 按钮顺序（3×3 网格）：
/// [撤销] [重做] [提示]
/// [标记] [自动标记] [清除]
/// [答案] [重置] [新游戏]
class FunctionKeyboard extends StatefulWidget {
  const FunctionKeyboard({
    required this.onUndo,
    required this.onRedo,
    required this.onHint,
    required this.onMark,
    required this.onErase,
    required this.onReset,
    required this.onAutoMark,
    required this.onSolution,
    required this.onNew,
    required this.buttonSize,
    this.isMarkMode,
    this.isAutoMarkMode,
    this.canUndo,
    this.canRedo,
    this.isShowingSolution,
    super.key,
  });
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onHint;
  final VoidCallback onMark;
  final VoidCallback onErase;
  final VoidCallback onReset;
  final VoidCallback onAutoMark;
  final VoidCallback onSolution;
  final VoidCallback onNew;
  final double buttonSize;
  final bool Function()? isMarkMode;
  final bool Function()? isAutoMarkMode;
  final bool Function()? canUndo;
  final bool Function()? canRedo;
  final bool Function()? isShowingSolution;

  @override
  State<FunctionKeyboard> createState() => _FunctionKeyboardState();
}

class _FunctionKeyboardState extends State<FunctionKeyboard> {
  @override
  Widget build(final BuildContext context) {
    final buttonSize = widget.buttonSize;
    const spacing = AppConstants.keyboardButtonSpacing;
    const padding = AppConstants.keyboardPadding;

    return Container(
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (final row) => Padding(
            padding: EdgeInsets.only(bottom: row < 2 ? spacing : 0),
            child: SizedBox(
              height: buttonSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (final col) {
                  final index = row * 3 + col;
                  return Padding(
                    padding: EdgeInsets.only(right: col < 2 ? spacing : 0),
                    child: _buildControlButton(
                      _getIconForIndex(index),
                      _getLabelForIndex(index),
                      _getCallbackForIndex(index),
                      index,
                      buttonSize,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 按钮顺序：
  /// 0:撤销 1:重做 2:提示
  /// 3:标记 4:自动标记 5:清除
  /// 6:答案 7:重置 8:新游戏
  IconData _getIconForIndex(final int index) {
    switch (index) {
      case 0:
        return Icons.undo; // 撤销
      case 1:
        return Icons.redo; // 重做
      case 2:
        return Icons.lightbulb_outline; // 提示
      case 3:
        return Icons.edit; // 标记
      case 4:
        return Icons.auto_fix_high; // 自动标记
      case 5:
        return Icons.clear; // 清除
      case 6:
        return Icons.visibility; // 答案
      case 7:
        return Icons.refresh; // 重置
      case 8:
        return Icons.add; // 新游戏
      default:
        return Icons.error;
    }
  }

  String _getLabelForIndex(final int index) {
    final localization = LocalizationUtils.app(context);
    switch (index) {
      case 0:
        return localization.undo; // 撤销
      case 1:
        return localization.redo; // 重做
      case 2:
        return localization.hint; // 提示
      case 3:
        return localization.mark; // 标记
      case 4:
        return localization.autoMark; // 自动标记
      case 5:
        return localization.erase; // 清除
      case 6:
        return localization.solution; // 答案
      case 7:
        return localization.reset; // 重置
      case 8:
        return localization.newGame; // 新游戏
      default:
        return localization.error;
    }
  }

  VoidCallback _getCallbackForIndex(final int index) {
    switch (index) {
      case 0:
        return widget.onUndo; // 撤销
      case 1:
        return widget.onRedo; // 重做
      case 2:
        return widget.onHint; // 提示
      case 3:
        return widget.onMark; // 标记
      case 4:
        return widget.onAutoMark; // 自动标记
      case 5:
        return widget.onErase; // 清除
      case 6:
        return widget.onSolution; // 答案
      case 7:
        return widget.onReset; // 重置
      case 8:
        return widget.onNew; // 新游戏
      default:
        return () {};
    }
  }

  /// 标记按钮（索引3）和自动标记按钮（索引4）需要高亮状态反馈
  static const int _markButtonIndex = 3;
  static const int _autoMarkButtonIndex = 4;
  /// 撤销按钮索引
  static const int _undoButtonIndex = 0;
  /// 重做按钮索引
  static const int _redoButtonIndex = 1;
  /// 答案按钮索引
  static const int _solutionButtonIndex = 6;
  /// 重置按钮索引
  static const int _resetButtonIndex = 7;
  /// 新游戏按钮索引
  static const int _newGameButtonIndex = 8;

  Widget _buildControlButton(
    final IconData icon,
    final String label,
    final VoidCallback onPressed,
    final int index,
    final double buttonSize, {
    final bool isEnabled = true,
  }) {
    final isTargetButton = index == _markButtonIndex || index == _autoMarkButtonIndex;
    final isPressed =
        isTargetButton &&
        (index == _markButtonIndex
            ? (widget.isMarkMode?.call() ?? false)
            : (widget.isAutoMarkMode?.call() ?? false));

    // 检查是否在查看答案状态
    final showingSolution = widget.isShowingSolution?.call() ?? false;
    
    // 在查看答案状态下，只允许：答案按钮、重置按钮、新游戏按钮
    final bool isButtonEnabledInSolutionMode = 
        index == _solutionButtonIndex || 
        index == _resetButtonIndex || 
        index == _newGameButtonIndex;

    final bool isButtonEnabled;
    if (showingSolution) {
      // 在查看答案状态下，只有特定按钮启用
      isButtonEnabled = isButtonEnabledInSolutionMode;
    } else if (index == _undoButtonIndex) {
      // 撤销按钮：检查 canUndo
      isButtonEnabled = isEnabled && (widget.canUndo?.call() ?? true);
    } else if (index == _redoButtonIndex) {
      // 重做按钮：检查 canRedo
      isButtonEnabled = isEnabled && (widget.canRedo?.call() ?? true);
    } else {
      // 其他按钮默认启用
      isButtonEnabled = isEnabled;
    }

    final iconSize = buttonSize * AppConstants.keyboardIconScale;
    final disabledColor = Colors.grey.shade400;
    final iconColor = isButtonEnabled
        ? (isPressed ? Colors.white : context.primaryColor)
        : disabledColor;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isPressed && isButtonEnabled
              ? LinearGradient(
                  colors: [context.primaryColor, context.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isButtonEnabled
                      ? [
                          context.primaryColor.withAlpha(AppConstants.gradientAlpha),
                          context.secondaryColor.withAlpha(AppConstants.gradientAlpha),
                        ]
                      : [
                          Colors.grey.withAlpha(AppConstants.gradientAlpha),
                          Colors.grey.shade300.withAlpha(AppConstants.gradientAlpha),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(AppConstants.shadowLightAlpha),
              blurRadius: isPressed ? 6 : AppConstants.spacingSmall,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: iconColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: isButtonEnabled
              ? () {
                  onPressed();
                  if (isTargetButton || index == _solutionButtonIndex) {
                    setState(() {});
                  }
                }
              : null,
          child: Icon(
            icon,
            size: iconSize,
            semanticLabel: label,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
