import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Set<LogicalKeyboardKey> _modifierOnlyKeys = {
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

/// Opens a modal that captures the next key press and returns it, or `null`
/// if the user cancels. [validate] is called for every non-modifier key
/// press; return an error message to reject it and keep listening, or
/// `null` to accept and close the dialog.
Future<LogicalKeyboardKey?> showShortcutCaptureDialog(
  BuildContext context, {
  required String actionLabel,
  required String? Function(LogicalKeyboardKey key) validate,
}) {
  return showDialog<LogicalKeyboardKey>(
    context: context,
    builder: (context) => _ShortcutCaptureDialog(
      actionLabel: actionLabel,
      validate: validate,
    ),
  );
}

class _ShortcutCaptureDialog extends StatefulWidget {
  final String actionLabel;
  final String? Function(LogicalKeyboardKey key) validate;

  const _ShortcutCaptureDialog({
    required this.actionLabel,
    required this.validate,
  });

  @override
  State<_ShortcutCaptureDialog> createState() => _ShortcutCaptureDialogState();
}

class _ShortcutCaptureDialogState extends State<_ShortcutCaptureDialog> {
  final FocusNode _focusNode = FocusNode();
  String? _error;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final key = event.logicalKey;
    if (_modifierOnlyKeys.contains(key)) return KeyEventResult.handled;

    final error = widget.validate(key);
    if (error != null) {
      setState(() => _error = error);
      return KeyEventResult.handled;
    }

    Navigator.of(context).pop(key);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnymeXText(
                'Set shortcut',
                size: 16,
                variant: TextVariant.bold,
              ),
              const SizedBox(height: 4),
              AnymeXText(
                widget.actionLabel,
                size: 14,
                color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .opaque(0.6, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _error != null
                        ? colors.error.opaque(0.6, iReallyMeanIt: true)
                        : colors.primary.opaque(0.3, iReallyMeanIt: true),
                  ),
                ),
                child: Center(
                  child: AnymeXText(
                    _error ?? 'Press any key…',
                    size: 14,
                    textAlign: TextAlign.center,
                    color: _error != null ? colors.error : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
