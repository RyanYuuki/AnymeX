import 'dart:io' show Platform;
import 'package:anymex/widgets/anymex_widgets/anymex_titlebar.dart';
import 'package:flutter/material.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';

class WatchSettingsPane extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final VoidCallback onClose;
  final Widget? tabBar;
  final List<Widget>? actions;
  final Widget child;

  const WatchSettingsPane({
    super.key,
    required this.title,
    this.subtitle,
    required this.onClose,
    this.tabBar,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final titleBarHeight =
        (Platform.isWindows && !AnymeXTitleBar.isFullScreen.value) ? 40.0 : 0.0;
    final topPadding = (MediaQuery.paddingOf(context).top +
            titleBarHeight +
            (isDesktop ? 16.0 : 10.0))
        .clamp(16.0, 120.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, topPadding, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnymeXText(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Linotte',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: cs.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                ...actions!,
                const SizedBox(width: 8),
              ],
              IconButton(
                onPressed: onClose,
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.close_rounded, color: cs.onSurface),
              ),
            ],
          ),
        ),
        if (tabBar != null) tabBar!,
        Expanded(child: child),
      ],
    );
  }
}
