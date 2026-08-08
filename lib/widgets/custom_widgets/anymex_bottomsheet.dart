import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:flutter/material.dart';

class AnymexSheet extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? contentWidget;
  final Widget? customWidget;
  final bool showDragHandle;

  const AnymexSheet({
    super.key,
    this.title,
    this.message,
    this.contentWidget,
    this.customWidget,
    this.showDragHandle = false,
  });

  static Future<T?> custom<T>(
    Widget widget,
    BuildContext context, {
    bool showDragHandle = false,
  }) =>
      AnymexSheet(
        customWidget: widget,
        showDragHandle: showDragHandle,
      ).show<T>(context);

  Future<T?> show<T>(
    BuildContext context,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AnymexSheet(
        title: title,
        message: message,
        contentWidget: contentWidget,
        customWidget: customWidget,
        showDragHandle: showDragHandle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset + bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
                Container(
                  width: 36,
                  height: 3.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              if (customWidget != null)
                customWidget!
              else ...[
                if (title != null) ...[
                  AnymexText(text: title!, size: 18, variant: TextVariant.bold),
                  const SizedBox(height: 10),
                ],
                contentWidget ??
                    (message != null
                        ? AnymexText(
                            text: message!,
                            textAlign: TextAlign.center,
                            size: 14)
                        : const SizedBox.shrink()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget loginSheetHelper({
  required BuildContext context,
  required String title,
  required String serviceName,
  bool showTokenOption = false,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.login_rounded,
              color: colors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      const Divider(height: 20, thickness: 1),
      const SizedBox(height: 8),
      AnymexOnTap(
        onTap: () => Navigator.pop(context, 'browser_internal'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outline.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.open_in_new_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Internal Browser',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Login inside the app (Recommended)',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      AnymexOnTap(
        onTap: () => Navigator.pop(context, 'browser_external'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outline.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.explore_outlined,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'External Browser',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Login using your default browser',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
      if (showTokenOption) ...[
        const SizedBox(height: 12),
        AnymexOnTap(
          onTap: () => Navigator.pop(context, 'token'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outline.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key_rounded,
                  color: colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login with Token',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manually paste OAuth access token',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 8),
    ],
  );
}
