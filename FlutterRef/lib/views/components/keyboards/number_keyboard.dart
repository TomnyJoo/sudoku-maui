import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

class NumberKeyboard extends StatefulWidget {
  const NumberKeyboard({
    required this.onNumberSelected,
    required this.buttonSize,
    this.getNumberCount,
    super.key,
  });
  final Function(int?) onNumberSelected;
  final double buttonSize;
  final int? Function(BuildContext, int)? getNumberCount;

  @override
  State<NumberKeyboard> createState() => _NumberKeyboardState();
}

class _NumberKeyboardState extends State<NumberKeyboard> {
  @override
  Widget build(final BuildContext context) {
    final buttonSize = widget.buttonSize;
    const spacing = AppConstants.keyboardButtonSpacing;
    const padding = AppConstants.keyboardPadding;

    return Container(
      padding: const EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (final row) => Padding(
            padding: EdgeInsets.only(
              bottom: row < 2 ? spacing : 0,
            ),
            child: SizedBox(
              height: buttonSize,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (final col) {
                  final number = row * 3 + col + 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: col < 2 ? spacing : 0,
                    ),
                    child: _buildButton(number, number.toString(), buttonSize),
                  );
                }),
              ),
            ),
          )),
      ),
    );
  }

  Widget _buildButton(final int number, final String label, final double buttonSize) {
    final fontSize = buttonSize * AppConstants.keyboardFontScale;
    final count = widget.getNumberCount?.call(context, number);

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.primaryColor.withAlpha(AppConstants.gradientAlpha), context.secondaryColor.withAlpha(AppConstants.gradientAlpha)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(AppConstants.shadowLightAlpha),
              blurRadius: AppConstants.spacingSmall,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: context.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: () => widget.onNumberSelected(number),
          child: Stack(
            children: [
              Center(
                child: Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: context.primaryColor,
                  ),
                  semanticsLabel: label,
                ),
              ),
              if (count != null && count > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: buttonSize * AppConstants.badgeHorizontalPaddingScale,
                      vertical: buttonSize * AppConstants.badgeVerticalPaddingScale,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
                      border: Border.all(
                        color: Colors.white.withAlpha(AppConstants.shadowDarkAlpha),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(AppConstants.shadowMediumAlpha),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: buttonSize * AppConstants.badgeFontScale,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
