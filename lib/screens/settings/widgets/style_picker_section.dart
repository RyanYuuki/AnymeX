import 'dart:io';

import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:anymex/l10n/l10n_extension.dart';

class StylePickerSection extends StatefulWidget {
  const StylePickerSection({
    super.key,
    required this.icon,
    required this.title,
    required this.itemCount,
    required this.appliedIndex,
    required this.labelFor,
    required this.descriptionFor,
    required this.previewBuilder,
    required this.onApply,
  });

  final IconData icon;
  final String title;
  final int itemCount;

  final int appliedIndex;
  final String Function(int index) labelFor;
  final String Function(int index) descriptionFor;

  final Widget Function(int index) previewBuilder;

  final ValueChanged<int> onApply;

  @override
  State<StylePickerSection> createState() => _StylePickerSectionState();
}

class _StylePickerSectionState extends State<StylePickerSection> {
  late int _index = widget.appliedIndex.clamp(0, widget.itemCount - 1);
  int _dir = 1;
  double _dragDistance = 0.0;

  void _go(int target) {
    final n = widget.itemCount;
    final next = ((target % n) + n) % n;
    if (next == _index) return;
    setState(() {
      _dir = target > _index ? 1 : -1;
      _index = next;
    });
  }

  void _step(int delta) {
    final n = widget.itemCount;
    setState(() {
      _dir = delta;
      _index = (_index + delta + n) % n;
    });
  }

  Widget _buildPreviewBox(ColorScheme colors) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        _dragDistance += d.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200 || _dragDistance < -40) {
          _step(1);
        } else if (v > 200 || _dragDistance > 40) {
          _step(-1);
        }
        _dragDistance = 0.0;
      },
      onHorizontalDragCancel: () {
        _dragDistance = 0.0;
      },
      child: SizedBox(
        width: double.infinity,
        child: ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.12 * _dir, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: IgnorePointer(
                  child: widget.previewBuilder(_index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isApplied = _index == widget.appliedIndex;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final showArrows = isDesktop && MediaQuery.sizeOf(context).width > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.opaque(0.12, iReallyMeanIt: true),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnymeXText(
                  widget.title,
                  size: 15,
                  variant: TextVariant.bold,
                ),
              ),
              AnymeXText(
                context.l10n.itemOfTotal((_index + 1).toString(), (widget.itemCount).toString()),
                size: 11.5,
                color: colors.onSurface.opaque(0.55, iReallyMeanIt: true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (showArrows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ArrowButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: context.l10n.previousStyle,
                  onTap: () => _step(-1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPreviewBox(colors),
                ),
                const SizedBox(width: 8),
                _ArrowButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: context.l10n.nextStyle,
                  onTap: () => _step(1),
                ),
              ],
            )
          else
            _buildPreviewBox(colors),
          const SizedBox(height: 14),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnymeXText(
                  widget.labelFor(_index),
                  size: 15,
                  variant: TextVariant.bold,
                ),
                if (isApplied) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary.opaque(0.14, iReallyMeanIt: true),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnymeXText(
                      context.l10n.currentLabel,
                      size: 10.5,
                      variant: TextVariant.semiBold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AnymeXText(
                widget.descriptionFor(_index),
                size: 12,
                maxLines: 2,
                color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < widget.itemCount; i++)
                    GestureDetector(
                      onTap: () => _go(i),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? colors.primary
                                : colors.onSurface
                                    .opaque(0.25, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                child: isApplied
                    ? FilledButton.tonalIcon(
                        onPressed: () {},
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(context.l10n.currentStyle),
                      )
                    : FilledButton(
                        onPressed: () => widget.onApply(_index),
                        child: Text(context.l10n.useThisStyle),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.primary.opaque(0.12, iReallyMeanIt: true),
        shape: CircleBorder(
          side: BorderSide(
            color: colors.primary.opaque(0.25, iReallyMeanIt: true),
            width: 0.8,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 22, color: colors.primary),
          ),
        ),
      ),
    );
  }
}
