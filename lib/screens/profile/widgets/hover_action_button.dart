import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HoverActionButton extends StatefulWidget {
  final Widget? child;
  final IconData? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const HoverActionButton({
    super.key,
    this.child,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  State<HoverActionButton> createState() => _HoverActionButtonState();
}

class _HoverActionButtonState extends State<HoverActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isHovered
                ? context.theme.colorScheme.primaryContainer.withOpacity(0.4)
                : Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: _isHovered
                ? Border.all(
                    color: context.theme.colorScheme.primary.withOpacity(0.5),
                  )
                : null,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: context.theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: widget.child ??
              Icon(
                widget.icon,
                size: 18,
                color: _isHovered
                    ? context.theme.colorScheme.primary
                    : Colors.white,
              ),
        ),
      ),
    );
  }
}
