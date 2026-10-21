import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';

class DelayRow extends StatelessWidget {
  final String label;
  final Duration delay;
  final ValueChanged<Duration> onChange;

  const DelayRow({
    super.key,
    required this.label,
    required this.delay,
    required this.onChange,
  });

  String _formatSeconds(double seconds) {
    if (seconds == 0) return '0.0 s';
    final prefix = seconds > 0 ? '+' : '';
    return '$prefix${seconds.toStringAsFixed(1)} s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seconds = delay.inMicroseconds / 1000000.0;
    final isOffset = delay != Duration.zero;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOffset
              ? colors.primary.withOpacity(0.4)
              : colors.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOffset
                  ? colors.primary.withOpacity(0.15)
                  : colors.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.timer_outlined,
              size: 18,
              color: isOffset ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  label,
                  variant: TextVariant.semiBold,
                  size: 13,
                  color: colors.onSurface,
                ),
                const SizedBox(height: 2),
                AnymeXText(
                  _formatSeconds(seconds),
                  size: 12,
                  color: isOffset ? colors.primary : colors.onSurfaceVariant,
                  variant:
                      isOffset ? TextVariant.semiBold : TextVariant.regular,
                ),
              ],
            ),
          ),
          if (isOffset)
            AnymexOnTap(
              onTap: () => onChange(Duration.zero),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnymeXText(
                  'Reset',
                  size: 11,
                  color: colors.primary,
                  variant: TextVariant.semiBold,
                ),
              ),
            ),
          _buildButton(
            context,
            icon: Icons.remove_rounded,
            onTap: () {
              final newMicros = delay.inMicroseconds - 100000;
              onChange(Duration(microseconds: newMicros));
            },
          ),
          const SizedBox(width: 6),
          _buildButton(
            context,
            icon: Icons.add_rounded,
            onTap: () {
              final newMicros = delay.inMicroseconds + 100000;
              onChange(Duration(microseconds: newMicros));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final colors = context.colors;
    return AnymexOnTap(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 18, color: colors.onSurface),
      ),
    );
  }
}
