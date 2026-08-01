import 'package:flutter/material.dart';

class ModernHoverWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final double scale;
  final double? margin;
  final Color? bgColor;
  final Color? focusedBorderColor;
  final double borderWidth;

  const ModernHoverWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
    this.scale = 1.00,
    this.margin = 5.0,
    this.bgColor,
    this.focusedBorderColor,
    this.borderWidth = 2.0,
  });

  @override
  State<ModernHoverWrapper> createState() => _ModernHoverWrapperState();
}

class _ModernHoverWrapperState extends State<ModernHoverWrapper> {
  bool _isHovering = false;

  void _onHover(bool isHovering) {
    if (_isHovering != isHovering) {
      setState(() {
        _isHovering = isHovering;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale(_isHovering ? widget.scale : 1.0),
          padding: EdgeInsets.symmetric(
            vertical: _isHovering ? (widget.margin ?? 5) : 0,
          ),
          margin: EdgeInsets.only(
            left: _isHovering ? (widget.margin ?? 5) : 0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isHovering
                ? (widget.bgColor ?? colorScheme.secondaryContainer)
                : Colors.transparent,
            border: Border.all(
              color: _isHovering
                  ? (widget.focusedBorderColor ?? colorScheme.primary)
                  : Colors.transparent,
              width: widget.borderWidth,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
