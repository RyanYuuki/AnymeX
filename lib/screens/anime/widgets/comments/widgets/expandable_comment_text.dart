import 'package:anymex/screens/anime/widgets/comments/discord_markdown.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Expandable comment text widget supporting:
/// - Markdown formatting via [DiscordMarkdown]
/// - Tap-to-reveal spoiler banners
/// - Automatic overflow detection
/// - Smooth gradient fade clamp when collapsed (~5 lines)
/// - "Read more" and "Show less" toggle controls
class ExpandableCommentText extends StatefulWidget {
  final String text;
  final bool isSpoiler;
  final ColorScheme colorScheme;
  final TextStyle? baseStyle;
  final double fontSize;
  final int maxCollapsedLines;

  const ExpandableCommentText({
    super.key,
    required this.text,
    required this.colorScheme,
    this.isSpoiler = false,
    this.baseStyle,
    this.fontSize = 14.0,
    this.maxCollapsedLines = 5,
  });

  @override
  State<ExpandableCommentText> createState() => _ExpandableCommentTextState();
}

class _ExpandableCommentTextState extends State<ExpandableCommentText> {
  bool _isRevealed = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colorScheme;

    // 1. If spoiler and not yet revealed, show tap-to-reveal spoiler card
    if (widget.isSpoiler && !_isRevealed) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _isRevealed = true);
        },
        child: AnymeXContainer(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.25),
          ),
          child: Row(
            children: [
              Icon(
                Icons.visibility_off_rounded,
                size: 15,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              AnymeXText(
                'Spoiler — tap to reveal',
                color: colors.onSurfaceVariant,
                size: 12.5,
                variant: TextVariant.semiBold,
                fontStyle: FontStyle.italic,
                maxLines: null,
              ),
            ],
          ),
        ),
      );
    }

    final effectiveStyle = widget.baseStyle ??
        TextStyle(
          fontSize: widget.fontSize,
          height: 1.4,
          color: colors.onSurface.withValues(alpha: 0.9),
        );

    final resolvedLineHeight =
        (effectiveStyle.fontSize ?? widget.fontSize) *
            (effectiveStyle.height ?? 1.4);
    final maxCollapsedHeight = resolvedLineHeight * widget.maxCollapsedLines;

    final markdownWidget = DiscordMarkdown(
      text: widget.text,
      colorScheme: colors,
      fontSize: widget.fontSize,
      baseStyle: effectiveStyle,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 60;

        // Measure text height using TextPainter to detect overflow accurately
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        )..layout(maxWidth: availableWidth);

        final newlineCount = widget.text.split('\n').length;
        final bool isOverflowing =
            textPainter.height > (maxCollapsedHeight + 8) ||
                newlineCount > widget.maxCollapsedLines;

        if (!isOverflowing) {
          return markdownWidget;
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isExpanded)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isExpanded = true);
                  },
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: maxCollapsedHeight),
                    child: ClipRect(
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.65, 1.0],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: markdownWidget,
                      ),
                    ),
                  ),
                )
              else
                markdownWidget,
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isExpanded = !_isExpanded);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: AnymeXText(
                    _isExpanded ? 'Show less' : 'Read more',
                    size: 12,
                    color: colors.primary,
                    variant: TextVariant.semiBold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
