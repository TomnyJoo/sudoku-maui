import 'package:flutter/material.dart';
import 'package:sudoku/index.dart';

/// 动画卡片
class AnimatedCard extends StatefulWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = Colors.transparent,
    this.elevation = 8,
    this.borderRadius = 16,
    this.padding = 12,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double elevation;
  final double borderRadius;
  final double padding;

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

/// 动画卡片状态管理
class _AnimatedCardState extends State<AnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppConstants.fastAnimationDuration),
          transform: Matrix4.diagonal3Values(
            _isHovered ? 1.02 : 1.0,
            _isHovered ? 1.02 : 1.0,
            1.0,
          ),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(77),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: _isHovered ? 12 : widget.elevation,
                offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.padding),
            child: widget.child,
          ),
        ),
      ),
    );
}
