import 'package:flutter/material.dart';
import 'package:sudoku/constants/app_constants.dart';
import 'package:sudoku/theme/responsive_layout.dart';

/// 通用顶部工具栏组件，提供返回、设置、帮助等通用功能按钮，适用于横屏布局的游戏界面
class TopToolbar extends StatelessWidget implements PreferredSizeWidget {
  const TopToolbar({
    super.key,
    required this.onBack,
    required this.onSettings,
    required this.onHelp,
    required this.title,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onHelp;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final responsiveBorderRadius = ResponsiveLayout.getResponsiveBorderRadius(context);

    return Container(
      height: kToolbarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(responsiveBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: AppConstants.spacingMedium,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: onBack,
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.getResponsiveFontSize(18, context),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              color: Colors.white,
              onPressed: onSettings,
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              color: Colors.white,
              onPressed: onHelp,
            ),
          ],
        ),
      ),
    );
  }
}

/// 通用顶部工具栏按钮组
/// 
/// 适用于需要自定义按钮布局的情况
class TopToolbarButtons extends StatelessWidget {

  const TopToolbarButtons({
    super.key,
    required this.buttons,
  });
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Container(
    height: kToolbarHeight,
    padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMedium),
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(50),
          blurRadius: AppConstants.spacingMedium,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons,
      ),
    ),
  );
}
