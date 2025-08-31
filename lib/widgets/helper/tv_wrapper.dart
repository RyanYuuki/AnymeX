import 'package:anymex/controllers/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AnymexOnTap extends StatelessWidget {
  final VoidCallback? onTap;
  final GestureTapUpCallback? onTapUp;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCancelCallback? onTapCancel;
  final Widget child;
  final double scale;
  final Duration animationDuration;
  final Color? focusedBorderColor;
  final bool? inkWell;
  final Color? bgColor;
  final double borderWidth;
  final double? margin;

  const AnymexOnTap({
    super.key,
    this.onTap,
    required this.child,
    this.scale = 1.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.focusedBorderColor,
    this.borderWidth = 2.0,
    this.margin,
    this.bgColor,
    this.inkWell,
    this.onTapUp,
    this.onTapDown,
    this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isTV = Get.find<Settings>().isTV.value;
    if (isTV) {
      return FocusableActionDetector(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) => onTap?.call(),
          ),
        },
        child: Builder(
          builder: (BuildContext context) {
            final bool isFocused = Focus.of(context).hasFocus;
            return GestureDetector(
              onTap: onTap,
              onTapUp: onTapUp,
              onTapDown: onTapDown,
              onTapCancel: onTapCancel,
              child: AnimatedContainer(
                duration: animationDuration,
                transform: Matrix4.identity()..scale(isFocused ? scale : 1.0),
                padding: EdgeInsets.symmetric(
                    vertical: isFocused ? (margin ?? 5) : 0),
                margin: EdgeInsets.only(left: isFocused ? (margin ?? 5) : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isFocused
                      ? (bgColor ??
                          Theme.of(context).colorScheme.secondaryContainer)
                      : Colors.transparent,
                  border: Border.all(
                    color: isFocused
                        ? (focusedBorderColor ??
                            Theme.of(context).colorScheme.primary)
                        : Colors.transparent,
                    width: borderWidth,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      if (inkWell ?? false) {
        return InkWell(
          onTap: onTap,
          child: child,
        );
      } else {
        return GestureDetector(
          onTap: onTap,
          child: child,
        );
      }
    }
  }
}

class AnymexOnTapAdv extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double scale;
  final Duration animationDuration;
  final Color? focusedBorderColor;
  final double borderWidth;
  final double? margin;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  const AnymexOnTapAdv({
    super.key,
    this.onTap,
    required this.child,
    this.scale = 1.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.focusedBorderColor,
    this.borderWidth = 2.0,
    this.margin,
    this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.enter &&
            event.logicalKey == LogicalKeyboardKey.space) {
          if (onTap != null) {
            onTap!.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        return onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
      },
      child: Builder(
        builder: (BuildContext context) {
          final bool isFocused = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: animationDuration,
              transform: Matrix4.identity()..scale(isFocused ? scale : 1.0),
              padding:
                  EdgeInsets.symmetric(vertical: isFocused ? (margin ?? 5) : 0),
              margin: EdgeInsets.only(left: isFocused ? (margin ?? 5) : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isFocused
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Colors.transparent,
                border: Border.all(
                  color: isFocused
                      ? (focusedBorderColor ??
                          Theme.of(context).colorScheme.primary)
                      : Colors.transparent,
                  width: borderWidth,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
