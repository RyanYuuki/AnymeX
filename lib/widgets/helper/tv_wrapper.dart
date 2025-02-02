import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVWrapper extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double scale;
  final Duration animationDuration;
  final Color? focusedBorderColor;
  final double borderWidth;

  const TVWrapper({
    super.key,
    this.onTap,
    required this.child,
    this.scale = 1.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.focusedBorderColor,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) => onTap?.call(),
        ),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Builder(
        builder: (BuildContext context) {
          final bool isFocused = Focus.of(context).hasFocus;

          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: animationDuration,
              transform: Matrix4.identity()..scale(isFocused ? scale : 1.0),
              padding: EdgeInsets.symmetric(vertical: isFocused ? 5 : 0),
              margin: EdgeInsets.only(left: isFocused ? 5 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isFocused
                        ? (focusedBorderColor ??
                            Theme.of(context).colorScheme.primary)
                        : Colors.transparent,
                    width: borderWidth,
                    strokeAlign: BorderSide.strokeAlignOutside),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
