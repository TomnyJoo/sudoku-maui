import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';
import 'package:vector_math/vector_math_64.dart';

/// 动画工具类 - 提供常用的动画效果和过渡动画
class AnimationUtils {
  /// 页面切换动画 - 淡入淡出
  static PageRouteBuilder fadeTransition(final Widget page) => PageRouteBuilder(
      pageBuilder: (final context, final animation, final secondaryAnimation) => page,
      transitionsBuilder: (final context, final animation, final secondaryAnimation, final child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
    );

  /// 页面切换动画 - 从右侧滑入
  static PageRouteBuilder slideFromRight(final Widget page) => PageRouteBuilder(
      pageBuilder: (final context, final animation, final secondaryAnimation) => page,
      transitionsBuilder: (final context, final animation, final secondaryAnimation, final child) {
        const begin = Offset(1, 0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: AppConstants.pageTransitionDuration),
    );

  /// 页面切换动画 - 缩放效果
  static PageRouteBuilder scaleTransition(final Widget page) => PageRouteBuilder(
      pageBuilder: (final context, final animation, final secondaryAnimation) => page,
      transitionsBuilder: (final context, final animation, final secondaryAnimation, final child) => ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutBack,
          ),
          child: child,
        ),
      transitionDuration: const Duration(milliseconds: AppConstants.slowAnimationDuration),
    );

  /// 按钮点击动画 - 缩放反馈
  static Widget scaleOnTap({
    required final Widget child,
    required final VoidCallback onTap,
    final double scale = 0.95,
    final Duration duration = const Duration(milliseconds: AppConstants.fastAnimationDuration),
  }) => GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: duration,
        transform: Matrix4.identity()..scaleByVector3(Vector3(scale, scale, 1)),
        child: child,
      ),
    );

  /// 悬停动画 - 轻微放大效果
  static Widget hoverAnimation({
    required final Widget child,
    final double hoverScale = 1.05,
    final Duration duration = const Duration(milliseconds: AppConstants.fastAnimationDuration),
  }) => _HoverAnimationWidget(
      hoverScale: hoverScale,
      duration: duration,
      child: child,
    );

  /// 脉冲动画 - 用于吸引注意力
  static Widget pulseAnimation({
    required final Widget child,
    final Duration duration = const Duration(milliseconds: AppConstants.defaultAnimationDuration),
  }) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (final context, final value, final child) => Transform.scale(
          scale: 1.0 + 0.1 * (0.5 + 0.5 * sin(value * 2 * pi)),
          child: child,
        ),
      child: child,
    );

  /// 渐入动画 - 用于列表项或卡片
  static Widget fadeInAnimation({
    required final Widget child,
    final Duration duration = const Duration(milliseconds: AppConstants.defaultAnimationDuration),
    final int index = 0,
  }) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: index * 100),
      builder: (final context, final value, final child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20.0 * (1 - value)),
            child: child,
          ),
        ),
      child: child,
    );

  /// 庆祝动画 - 用于游戏完成等场景
  static Widget celebrationAnimation({
    required final Widget child,
    final Duration duration = const Duration(milliseconds: AppConstants.fadeAnimationDuration),
  }) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (final context, final value, final child) => Transform(
          transform: Matrix4.identity()
            ..scaleByVector3(Vector3(0.5 + 0.5 * value, 0.5 + 0.5 * value, 1))
            ..rotateZ(0.1 * sin(value * 2 * pi)),
          alignment: Alignment.center,
          child: child,
        ),
      child: child,
    );

  /// 打字机效果 - 用于文本显示
  static Widget typewriterAnimation({
    required final String text,
    required final TextStyle style,
    final Duration duration = const Duration(milliseconds: AppConstants.defaultAnimationDuration),
  }) => TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: duration,
      builder: (final context, final value, final child) => Text(text.substring(0, value), style: style),
    );

  /// 进度条动画 - 用于加载或进度显示
  static Widget progressAnimation({
    required final double progress,
    required final Color color,
    final Duration duration = const Duration(milliseconds: AppConstants.slowAnimationDuration),
  }) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: duration,
      curve: Curves.easeOut,
      builder: (final context, final value, final child) => LinearProgressIndicator(
          value: value,
          backgroundColor: color.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
    );
}

/// 悬停动画组件
class _HoverAnimationWidget extends StatefulWidget {

  const _HoverAnimationWidget({
    required this.child,
    required this.hoverScale,
    required this.duration,
  });
  final Widget child;
  final double hoverScale;
  final Duration duration;

  @override
  _HoverAnimationWidgetState createState() => _HoverAnimationWidgetState();
}

class _HoverAnimationWidgetState extends State<_HoverAnimationWidget> {
  bool _isHovering = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: widget.duration,
        transform: Matrix4.identity()
          ..scaleByVector3(
            Vector3(
              _isHovering ? widget.hoverScale : 1.0,
              _isHovering ? widget.hoverScale : 1.0,
              1,
            ),
          ),
        child: widget.child,
      ),
    );
}

/// 动画常量
class AnimationConstants {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}
