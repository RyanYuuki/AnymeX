import 'dart:math' as math;
import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/models/Anilist/story_group.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

class StoryCircle extends StatelessWidget {
  final StoryGroup group;
  final bool isOwn;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StoryCircle({
    super.key,
    required this.group,
    this.isOwn = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flags = [
      for (final a in group.activities) StorySeenManager.isSeen(a.id)
    ];
    final hasUnseen = group.activities.isEmpty ? false : flags.any((s) => !s);

    final displayName = isOwn ? context.l10n.yourStory : group.user.name;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: hasUnseen ? 1 : 0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    builder: (context, glow, child) {
                      return CustomPaint(
                        size: const Size(70, 70),
                        painter: _RingPainter(
                          flags: flags,
                          startColor: theme.colorScheme.primary,
                          endColor: theme.colorScheme.tertiary,
                          idleColor: theme.colorScheme.outlineVariant.withOpacity(0.4),
                          glow: glow,
                        ),
                      );
                    },
                  ),
                  Hero(
                    tag: 'story-avatar-${group.user.id}',
                    child: ClipOval(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: group.user.avatarUrl != null &&
                                group.user.avatarUrl!.isNotEmpty
                            ? AnymeXImage(
                                imageUrl: group.user.avatarUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (isOwn && group.activities.isEmpty)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 13,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            AnymeXText(
              displayName,
              size: 11,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              color: hasUnseen
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              variant: hasUnseen ? TextVariant.semiBold : TextVariant.regular,
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<bool> flags;
  final Color startColor;
  final Color endColor;
  final Color idleColor;
  final double glow;

  const _RingPainter({
    required this.flags,
    required this.startColor,
    required this.endColor,
    required this.idleColor,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (flags.isEmpty) {
      paint
        ..strokeWidth = 1.6
        ..color = idleColor;
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }

    final count = flags.length;
    final gap = count == 1 ? 0.0 : (count > 12 ? 0.08 : 0.14);
    final sweep = (math.pi * 2 - gap * count) / count;

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [startColor, endColor, startColor],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    double startAt(int i) => -math.pi / 2 + gap / 2 + i * (sweep + gap);

    paint
      ..shader = null
      ..strokeWidth = 2.0
      ..color = idleColor;

    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, startAt(i), sweep, false, paint);
    }

    if (glow <= 0) return;

    canvas.saveLayer(
      rect.inflate(4),
      Paint()..color = Colors.white.withOpacity(glow.clamp(0.0, 1.0)),
    );

    paint
      ..shader = gradient
      ..strokeWidth = 2.8;

    for (var i = 0; i < count; i++) {
      if (!flags[i]) {
        canvas.drawArc(rect, startAt(i), sweep, false, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.glow != glow ||
        oldDelegate.flags.length != flags.length ||
        oldDelegate.startColor != startColor ||
        oldDelegate.endColor != endColor;
  }
}
