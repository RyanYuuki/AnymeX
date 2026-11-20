import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

abstract class AnymeXMenuEntry<T> {
  const AnymeXMenuEntry();
}

class AnymeXMenuItem<T> extends AnymeXMenuEntry<T> {
  final T? value;
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Widget? trailing;
  final Color? color;
  final bool isDestructive;
  final VoidCallback? onTap;
  final bool enabled;

  const AnymeXMenuItem({
    this.value,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailingIcon,
    this.trailing,
    this.color,
    this.isDestructive = false,
    this.onTap,
    this.enabled = true,
  });
}

class AnymeXMenuDivider<T> extends AnymeXMenuEntry<T> {
  final double height;
  const AnymeXMenuDivider({this.height = 8.0});
}

class AnymeXMenuGroupHeader<T> extends AnymeXMenuEntry<T> {
  final String title;
  const AnymeXMenuGroupHeader({required this.title});
}

Future<T?> showAnymeXPopupMenu<T>({
  required BuildContext context,
  required List<AnymeXMenuEntry<T>> items,
  Rect? targetRect,
  Offset? position,
  String? title,
  double? width,
  bool barrierDismissible = true,
  ThemeData? theme,
}) {
  HapticFeedback.lightImpact();
  final resolvedTheme = theme ?? Theme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _AnymeXPopupMenuRoute<T>(
      items: items,
      targetRect: targetRect,
      position: position,
      title: title,
      width: width,
      barrierDismissible: barrierDismissible,
      theme: resolvedTheme,
    ),
  );
}

class AnymeXPopupMenu {
  static Future<T?> show<T>({
    required BuildContext context,
    required List<AnymeXMenuEntry<T>> items,
    Rect? targetRect,
    Offset? position,
    String? title,
    double? width,
    bool barrierDismissible = true,
    ThemeData? theme,
  }) {
    return showAnymeXPopupMenu<T>(
      context: context,
      items: items,
      targetRect: targetRect,
      position: position,
      title: title,
      width: width,
      barrierDismissible: barrierDismissible,
      theme: theme,
    );
  }
}

class AnymeXPopupMenuButton<T> extends StatelessWidget {
  final List<AnymeXMenuEntry<T>> items;
  final Widget? child;
  final IconData? icon;
  final String? title;
  final double? width;
  final ValueChanged<T?>? onSelected;
  final String? tooltip;
  final ThemeData? theme;

  const AnymeXPopupMenuButton({
    super.key,
    required this.items,
    this.child,
    this.icon,
    this.title,
    this.width,
    this.onSelected,
    this.tooltip,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) {
        if (child != null) {
          return GestureDetector(
            onTap: () => _openMenu(btnContext),
            behavior: HitTestBehavior.opaque,
            child: child,
          );
        }

        return IconButton(
          icon: Icon(icon ?? Icons.more_vert_rounded),
          tooltip: tooltip,
          onPressed: () => _openMenu(btnContext),
        );
      },
    );
  }

  void _openMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final rect =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final result = await showAnymeXPopupMenu<T>(
      context: context,
      targetRect: rect,
      title: title,
      width: width,
      items: items,
      theme: theme ?? Theme.of(context),
    );
    if (result != null) {
      onSelected?.call(result);
    }
  }
}

class _AnymeXPopupMenuRoute<T> extends PopupRoute<T> {
  final List<AnymeXMenuEntry<T>> items;
  final Rect? targetRect;
  final Offset? position;
  final String? title;
  final double? width;
  @override
  final bool barrierDismissible;
  final ThemeData theme;

  _AnymeXPopupMenuRoute({
    required this.items,
    this.targetRect,
    this.position,
    this.title,
    this.width,
    this.barrierDismissible = true,
    required this.theme,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Theme(
      data: theme,
      child: _AnymeXPopupMenuOverlay<T>(
        items: items,
        targetRect: targetRect,
        position: position,
        title: title,
        width: width,
        animation: animation,
      ),
    );
  }
}

class _AnymeXPopupMenuOverlay<T> extends StatelessWidget {
  final List<AnymeXMenuEntry<T>> items;
  final Rect? targetRect;
  final Offset? position;
  final String? title;
  final double? width;
  final Animation<double> animation;

  const _AnymeXPopupMenuOverlay({
    required this.items,
    this.targetRect,
    this.position,
    this.title,
    this.width,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    final double menuWidth = (width ?? 200.0).clamp(160.0, screenSize.width - 32.0);
    final double maxAllowedMenuHeight = (screenSize.height * 0.55).clamp(200.0, 420.0);

    double? top;
    double? bottom;
    double left = 0;
    double maxHeight = maxAllowedMenuHeight;
    Alignment transformAlignment = Alignment.center;

    if (targetRect != null) {
      final rect = targetRect!;
      final double spaceBelow = screenSize.height - rect.bottom - padding.bottom - 16.0;
      final double spaceAbove = rect.top - padding.top - 16.0;

      final bool showBelow = spaceBelow >= 180.0 || spaceBelow >= spaceAbove;

      if (showBelow) {
        top = (rect.bottom + 6.0).clamp(padding.top + 8.0, screenSize.height - padding.bottom - 60.0);
        bottom = null;
        maxHeight = spaceBelow.clamp(120.0, maxAllowedMenuHeight);
        if (rect.center.dx < screenSize.width * 0.35) {
          left = rect.left;
          transformAlignment = Alignment.topLeft;
        } else if (rect.center.dx > screenSize.width * 0.65) {
          left = rect.right - menuWidth;
          transformAlignment = Alignment.topRight;
        } else {
          left = rect.center.dx - (menuWidth / 2.0);
          transformAlignment = Alignment.topCenter;
        }
      } else {
        bottom = (screenSize.height - rect.top + 6.0).clamp(padding.bottom + 8.0, screenSize.height - padding.top - 60.0);
        top = null;
        maxHeight = spaceAbove.clamp(120.0, maxAllowedMenuHeight);
        if (rect.center.dx < screenSize.width * 0.35) {
          left = rect.left;
          transformAlignment = Alignment.bottomLeft;
        } else if (rect.center.dx > screenSize.width * 0.65) {
          left = rect.right - menuWidth;
          transformAlignment = Alignment.bottomRight;
        } else {
          left = rect.center.dx - (menuWidth / 2.0);
          transformAlignment = Alignment.bottomCenter;
        }
      }
    } else if (position != null) {
      final pos = position!;
      final double spaceBelow = screenSize.height - pos.dy - padding.bottom - 16.0;
      final double spaceAbove = pos.dy - padding.top - 16.0;
      final bool showBelow = spaceBelow >= 180.0 || spaceBelow >= spaceAbove;

      if (showBelow) {
        top = (pos.dy + 6.0).clamp(padding.top + 8.0, screenSize.height - padding.bottom - 60.0);
        bottom = null;
        maxHeight = spaceBelow.clamp(120.0, maxAllowedMenuHeight);
        transformAlignment = pos.dx < screenSize.width / 2 ? Alignment.topLeft : Alignment.topRight;
      } else {
        bottom = (screenSize.height - pos.dy + 6.0).clamp(padding.bottom + 8.0, screenSize.height - padding.top - 60.0);
        top = null;
        maxHeight = spaceAbove.clamp(120.0, maxAllowedMenuHeight);
        transformAlignment = pos.dx < screenSize.width / 2 ? Alignment.bottomLeft : Alignment.bottomRight;
      }
      left = pos.dx < screenSize.width / 2 ? pos.dx : pos.dx - menuWidth;
    } else {
      maxHeight = (screenSize.height * 0.5).clamp(200.0, maxAllowedMenuHeight);
      top = (screenSize.height - maxHeight) / 2.0;
      bottom = null;
      left = (screenSize.width - menuWidth) / 2.0;
      transformAlignment = Alignment.center;
    }

    left = left.clamp(16.0, screenSize.width - menuWidth - 16.0);

    final springCurve = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.175, 0.885, 0.32, 1.275),
      reverseCurve: Curves.easeInCubic,
    );

    final fadeCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: top,
          bottom: bottom,
          left: left,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final scale = Tween<double>(begin: 0.65, end: 1.0).evaluate(springCurve);
              final opacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(fadeCurve);

              return Transform.scale(
                scale: scale,
                alignment: transformAlignment,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: _buildMenuCard(context, menuWidth, maxHeight),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, double menuWidth, double maxHeight) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16.multiplyRadius());

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: menuWidth,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Color.lerp(
                theme.colorScheme.surfaceContainer,
                theme.colorScheme.primaryContainer,
                0.08,
              )!.opaque(0.92, iReallyMeanIt: true),
              borderRadius: radius,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.opaque(0.25, iReallyMeanIt: true),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.opaque(0.18, iReallyMeanIt: true),
                  blurRadius: 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: theme.colorScheme.shadow.opaque(0.06, iReallyMeanIt: true),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: AnymeXText(
                      title!.toUpperCase(),
                      variant: TextVariant.bold,
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant.opaque(0.7, iReallyMeanIt: true),
                      ), translate: false,
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.colorScheme.outlineVariant.opaque(0.2, iReallyMeanIt: true),
                  ),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < items.length; i++) ...[
                          _buildEntry(context, items[i]),
                          if (i < items.length - 1 &&
                              items[i] is AnymeXMenuItem &&
                              items[i + 1] is AnymeXMenuItem)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 12,
                              endIndent: 12,
                              color: theme.colorScheme.outlineVariant.opaque(0.18, iReallyMeanIt: true),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, AnymeXMenuEntry<T> entry) {
    final theme = Theme.of(context);

    if (entry is AnymeXMenuDivider<T>) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Divider(
          height: 0.5,
          thickness: 0.5,
          color: theme.colorScheme.outlineVariant.opaque(0.2, iReallyMeanIt: true),
        ),
      );
    }

    if (entry is AnymeXMenuGroupHeader<T>) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: AnymeXText(
          entry.title.toUpperCase(),
          variant: TextVariant.bold,
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant.opaque(0.65, iReallyMeanIt: true),
          ), translate: false,
        ),
      );
    }

    if (entry is AnymeXMenuItem<T>) {
      final item = entry;
      final Color foregroundColor = item.isDestructive
          ? theme.colorScheme.error
          : (item.color ?? theme.colorScheme.onSurface);

      return InkWell(
        onTap: item.enabled
            ? () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(item.value);
                item.onTap?.call();
              }
            : null,
        splashColor: (item.isDestructive ? theme.colorScheme.error : theme.colorScheme.primary)
            .opaque(0.12, iReallyMeanIt: true),
        highlightColor: (item.isDestructive ? theme.colorScheme.error : theme.colorScheme.primary)
            .opaque(0.06, iReallyMeanIt: true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
          child: Row(
            children: [
              if (item.leadingIcon != null) ...[
                Icon(
                  item.leadingIcon,
                  size: 16,
                  color: item.isDestructive
                      ? theme.colorScheme.error
                      : (item.color ?? theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      item.title,
                      variant: TextVariant.semiBold,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: item.enabled
                            ? foregroundColor
                            : theme.colorScheme.onSurface.opaque(0.38, iReallyMeanIt: true),
                      ), translate: false,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 1),
                      AnymeXText(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 10.0,
                          color: theme.colorScheme.onSurfaceVariant.opaque(0.7, iReallyMeanIt: true),
                        ), translate: false,
                      ),
                    ],
                  ],
                ),
              ),
              if (item.trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(
                  item.trailingIcon,
                  size: 15,
                  color: item.isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant.opaque(0.6, iReallyMeanIt: true),
                ),
              ],
              if (item.trailing != null) ...[
                const SizedBox(width: 6),
                item.trailing!,
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
