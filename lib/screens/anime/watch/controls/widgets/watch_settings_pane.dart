import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class WatchSettingsPane extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget? tabBar;
  final List<Widget>? actions;
  final Widget child;

  const WatchSettingsPane({
    super.key,
    required this.title,
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
    final topPadding = (MediaQuery.paddingOf(context).top + (isDesktop ? 20 : 12)).clamp(16.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, topPadding, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'Poppins-SemiBold',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: cs.onSurface,
                  ),
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
