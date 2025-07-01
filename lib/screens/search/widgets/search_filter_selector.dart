import 'package:flutter/material.dart';

class FutureisticOptionTile extends StatefulWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const FutureisticOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  @override
  State<FutureisticOptionTile> createState() => _FutureisticOptionTileState();
}

class _FutureisticOptionTileState extends State<FutureisticOptionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FutureisticOptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.isSelected
                  ? LinearGradient(
                      colors: [
                        widget.colorScheme.primary.withOpacity(0.1),
                        widget.colorScheme.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: widget.isSelected
                    ? widget.colorScheme.primary
                    : widget.colorScheme.outline.withOpacity(0.2),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.colorScheme.primary
                            .withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 12 * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onTap,
                onHover: (hovered) {
                  setState(() {
                    _isHovered = hovered;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Custom futuristic selector
                      _buildFuturisticSelector(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.option,
                          style: widget.theme.textTheme.bodyLarge?.copyWith(
                            color: widget.isSelected
                                ? widget.colorScheme.primary
                                : widget.colorScheme.onSurface,
                            fontWeight: widget.isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      // Selection indicator
                      if (widget.isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: widget.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    widget.colorScheme.primary.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: widget.colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuturisticSelector() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isSelected
              ? widget.colorScheme.primary
              : widget.colorScheme.outline.withOpacity(0.4),
          width: 2,
        ),
        gradient: widget.isSelected
            ? RadialGradient(
                colors: [
                  widget.colorScheme.primary.withOpacity(0.8),
                  widget.colorScheme.primary.withOpacity(0.2),
                ],
              )
            : null,
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: widget.colorScheme.primary
                      .withOpacity(0.4 * _glowAnimation.value),
                  blurRadius: 8 * _glowAnimation.value,
                  spreadRadius: 1 * _glowAnimation.value,
                ),
              ]
            : null,
      ),
      child: widget.isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: widget.colorScheme.primary.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
