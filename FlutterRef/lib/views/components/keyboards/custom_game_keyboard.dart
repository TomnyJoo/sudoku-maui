import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

class CustomFunKeyboard extends StatelessWidget {
  const CustomFunKeyboard({
    required this.onStartGame,
    required this.onClearBoard,
    required this.isValidating,
    required this.buttonSize,
    super.key,
  });

  final VoidCallback onStartGame;
  final VoidCallback onClearBoard;
  final bool isValidating;
  final double buttonSize;

  @override
  Widget build(final BuildContext context) {
    const spacing = AppConstants.spacingExtraLarge;
    const padding = AppConstants.spacingLarge;

    return Container(
      padding: const EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.successColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              onPressed: isValidating ? null : onStartGame,
              child: isValidating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: AppConstants.loadingIndicatorStrokeWidth,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: AppConstants.spacingHuge),
            ),
          ),
          const SizedBox(width: spacing),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.errorColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              onPressed: onClearBoard,
              child: const Icon(Icons.clear, size: AppConstants.spacingHuge),
            ),
          ),
        ],
      ),
    );
  }
}
