import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool compact;
  final bool isPrimary;

  const ControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.compact = false,
    this.isPrimary = false,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late bool enabled;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    enabled = widget.onPressed != null;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (enabled) {
      _animationController.forward();
    }
  }

  void _handleTapUp() {
    if (enabled) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (enabled) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 36.0 : (widget.isPrimary ? 48.0 : 44.0);
    final iconSize = widget.compact ? 20.0 : (widget.isPrimary ? 26.0 : 24.0);

    Widget button = AnymexOnTap(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: widget.isPrimary
                      ? (_isHovered
                          ? context.theme.colorScheme.primary.withOpacity(0.15)
                          : context.theme.colorScheme.primary.withOpacity(0.08))
                      : (_isHovered
                          ? context.theme.colorScheme.primary.withOpacity(0.1)
                          : context.theme.colorScheme.surfaceVariant
                              .withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(
                      widget.compact ? 12 : (widget.isPrimary ? 18 : 16)),
                  border: Border.all(
                    color: widget.isPrimary
                        ? (_isHovered
                            ? context.theme.colorScheme.primary.withOpacity(0.4)
                            : context.theme.colorScheme.primary
                                .withOpacity(0.2))
                        : (_isHovered
                            ? context.theme.colorScheme.primary.withOpacity(0.3)
                            : context.theme.colorScheme.outline
                                .withOpacity(0.1)),
                    width: _isHovered ? 1.0 : 0.5,
                  ),
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.isPrimary
                                ? context.theme.colorScheme.primary
                                    .withOpacity(0.3)
                                : context.theme.colorScheme.primary
                                    .withOpacity(0.2),
                            blurRadius: widget.isPrimary ? 12 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      size: iconSize,
                      color: enabled
                          ? (widget.isPrimary
                              ? context.theme.colorScheme.primary
                              : (_isHovered
                                  ? context.theme.colorScheme.primary
                                  : context.theme.colorScheme.onSurface))
                          : context.theme.colorScheme.onSurface
                              .withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        preferBelow: true,
        decoration: BoxDecoration(
          color: context.theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: context.theme.textTheme.bodySmall?.copyWith(
          color: context.theme.colorScheme.onInverseSurface,
        ),
        child: button,
      );
    }

    return button;
  }
}
