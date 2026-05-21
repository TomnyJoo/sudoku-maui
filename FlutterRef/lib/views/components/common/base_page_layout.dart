import 'package:flutter/material.dart';
import 'package:sudoku/theme/index.dart';

/// 基础页面布局
class BasePageLayout extends StatelessWidget {
  const BasePageLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final iconColor = isDarkMode ? Colors.white.withAlpha(200) : AppColors.mutedText;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: iconColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? AppColors.homeBackgroundGradientDark
                  : AppColors.homeBackgroundGradientLight,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppTextStyles.fontSizeSubtitle,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.darkText,
          ),
        ),
        centerTitle: true,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
            : leading,
        actions: actions,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? AppColors.homeBackgroundGradientDark
                : AppColors.homeBackgroundGradientLight,
          ),
        ),
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}
