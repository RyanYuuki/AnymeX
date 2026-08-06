import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/screens/profile/widgets/user_media_list_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/marquee_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DesktopStatsGrid extends StatelessWidget {
  final Profile user;

  const DesktopStatsGrid({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final anime = user.stats?.animeStats;
    final manga = user.stats?.mangaStats;
    final days = anime?.minutesWatched != null
        ? (int.tryParse(anime!.minutesWatched!) ?? 0) ~/ 1440
        : 0;
    final meanScore = anime?.meanScore ?? '0';

    // first fav poster for each cat
    final animeThumbs = user.favourites?.anime
            .where((f) => f.cover != null)
            .take(1)
            .map((f) => f.cover!)
            .toList() ??
        [];
    final mangaThumbs = user.favourites?.manga
            .where((f) => f.cover != null)
            .take(1)
            .map((f) => f.cover!)
            .toList() ??
        [];

    final userId = int.tryParse(user.id ?? '') ?? 0;

    final items = [
      _StatCard(
        label: 'ANIME',
        value: anime?.animeCount ?? '0',
        sub: 'entries',
        color: context.theme.colorScheme.primary,
        thumbnails: animeThumbs,
        onTap: () => navigate(
          () => UserMediaListPage(
            userId: userId,
            type: 'ANIME',
            userName: user.name ?? 'User',
            favourites: user.favourites?.anime,
            sectionOrder: user.animeSectionOrder,
          ),
        ),
      ),
      _StatCard(
        label: 'DAYS',
        value: days.toString(),
        sub: 'watched',
        color: context.theme.colorScheme.onSurface,
      ),
      _StatCard(
        label: 'MEAN',
        value: meanScore,
        sub: 'score',
        color: context.theme.colorScheme.primary,
      ),
      _StatCard(
        label: 'CHAPTERS',
        value: manga?.chaptersRead ?? '0',
        sub: 'read',
        color: context.theme.colorScheme.primary,
        thumbnails: mangaThumbs,
        onTap: () => navigate(
          () => UserMediaListPage(
            userId: userId,
            type: 'MANGA',
            userName: user.name ?? 'User',
            favourites: user.favourites?.manga,
            sectionOrder: user.mangaSectionOrder,
          ),
        ),
      ),
      _StatCard(
        label: 'VOLUMES',
        value: manga?.volumesRead ?? '0',
        sub: 'read',
        color: context.theme.colorScheme.onSurface,
      ),
      _StatCard(
        label: 'MEAN',
        value: manga?.meanScore ?? '0',
        sub: 'score',
        color: context.theme.colorScheme.primary,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1140),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final hasThumbs =
                item.thumbnails != null && item.thumbnails!.isNotEmpty;
            final isClickable = item.onTap != null;

            bool isHovered = false;
            return StatefulBuilder(
              builder: (context, setLocalState) {
                return MouseRegion(
                  cursor: isClickable
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  onEnter: isClickable
                      ? (_) => setLocalState(() => isHovered = true)
                      : null,
                  onExit: isClickable
                      ? (_) => setLocalState(() => isHovered = false)
                      : null,
                  child: GestureDetector(
                    onTap: item.onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.surfaceContainerHigh
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHovered
                              ? context.theme.colorScheme.primary
                                  .withOpacity(0.9)
                              : context.theme.colorScheme.outlineVariant
                                  .withOpacity(0.15),
                          width: isHovered ? 2.5 : 1.0,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        boxShadow: hasThumbs
                            ? [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isHovered ? 0.7 : 0.45),
                                  blurRadius: isHovered ? 24 : 20,
                                  spreadRadius: isHovered ? 4 : 2,
                                  offset: const Offset(0, 8),
                                ),
                                if (isHovered)
                                  BoxShadow(
                                    color: context.theme.colorScheme.primary
                                        .withOpacity(0.4),
                                    blurRadius: 28,
                                    spreadRadius: 6,
                                  ),
                              ]
                            : (isHovered
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: context.theme.colorScheme.primary
                                          .withOpacity(0.35),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null),
                      ),
                      child: Stack(
                        children: [
                          if (hasThumbs)
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: item.thumbnails!.first,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          if (hasThumbs)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MarqueeText(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: hasThumbs
                                        ? Colors.white.withOpacity(0.7)
                                        : context
                                            .theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: MarqueeText(
                                      item.value,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Poppins-Bold',
                                        color: hasThumbs
                                            ? Colors.white
                                            : item.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                MarqueeText(
                                  item.sub,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasThumbs
                                        ? Colors.white.withOpacity(0.8)
                                        : context
                                            .theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (hasThumbs && item.onTap != null)
                            Positioned(
                              right: 8,
                              top: 6,
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                size: 14,
                                color: isHovered
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.7),
                                shadows: isHovered
                                    ? [
                                        Shadow(
                                          color: Colors.white.withOpacity(0.8),
                                          blurRadius: 8,
                                        ),
                                        Shadow(
                                          color: context
                                              .theme.colorScheme.primary
                                              .withOpacity(0.6),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class HighlightCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;
  final String? imageUrl;

  const HighlightCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.compact = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableHighlightCard(
      label: label,
      value: value,
      icon: icon,
      color: color,
      onTap: onTap,
      compact: compact,
      imageUrl: imageUrl,
    );
  }
}

class ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const ScoreCard({
    super.key,
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: MarqueeText(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
                color: context.theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value%',
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: context.theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: context.theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins-SemiBold',
          ),
        ),
      ],
    );
  }
}

class _StatCard {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final List<String>? thumbnails;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.thumbnails,
    this.onTap,
  });
}

class _PressableHighlightCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;
  final String? imageUrl;

  const _PressableHighlightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.compact = false,
    this.imageUrl,
  });

  @override
  State<_PressableHighlightCard> createState() =>
      _PressableHighlightCardState();
}

class _PressableHighlightCardState extends State<_PressableHighlightCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = widget.compact ? 24.0 : 18.0;
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.88 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(radius),
          elevation: _isPressed ? 0 : (widget.imageUrl != null ? 4 : 1),
          shadowColor:
              colors.shadow.withOpacity(widget.imageUrl != null ? 0.3 : 0.15),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              if (_isPressed != pressed) {
                setState(() => _isPressed = pressed);
              }
            },
            borderRadius: BorderRadius.circular(radius),
            splashColor: widget.color.withOpacity(0.08),
            highlightColor: widget.color.withOpacity(0.05),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: widget.imageUrl != null
                      ? (_isPressed
                          ? colors.primary.withOpacity(0.8)
                          : colors.outlineVariant.withOpacity(0.15))
                      : colors.outlineVariant.withOpacity(0.3),
                  width: widget.imageUrl != null && _isPressed ? 1.5 : 1,
                ),
                boxShadow: widget.imageUrl != null && _isPressed
                    ? [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  if (widget.imageUrl != null)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (widget.imageUrl != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: widget.compact ? 8 : 20,
                      horizontal: widget.compact ? 14 : 18,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.icon,
                            color: widget.imageUrl != null
                                ? Colors.white.withOpacity(0.9)
                                : widget.color,
                            size: widget.compact ? 18 : 28,
                          ),
                          SizedBox(height: widget.compact ? 4 : 10),
                          Text(
                            widget.value,
                            style: TextStyle(
                              fontSize: widget.compact ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins-Bold',
                              color: widget.imageUrl != null
                                  ? Colors.white
                                  : colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: widget.compact ? 10 : 12,
                              fontWeight: FontWeight.w500,
                              color: widget.imageUrl != null
                                  ? Colors.white.withOpacity(0.8)
                                  : colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.imageUrl != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 14,
                        color: _isPressed
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        shadows: _isPressed
                            ? [
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
