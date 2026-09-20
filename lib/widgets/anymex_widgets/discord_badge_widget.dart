import 'package:anymex/database/comments/model/discord_badge.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiscordBadgeWidget extends StatelessWidget {
  final DiscordBadge badge;
  final double size;
  final bool interactive;
  final EdgeInsetsGeometry padding;

  const DiscordBadgeWidget({
    super.key,
    required this.badge,
    this.size = 16.0,
    this.interactive = true,
    this.padding = const EdgeInsets.only(right: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    Widget badgeIcon;

    if (badge.isSvg) {
      badgeIcon = SvgPicture.network(
        badge.iconUrl,
        width: size,
        height: size,
        placeholderBuilder: (_) => SizedBox(
          width: size,
          height: size,
        ),
      );
    } else {
      badgeIcon = CachedNetworkImage(
        imageUrl: badge.iconUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => SizedBox(
          width: size,
          height: size,
        ),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    final content = Padding(
      padding: padding,
      child: Tooltip(
        message: badge.name,
        waitDuration: const Duration(milliseconds: 300),
        child: badgeIcon,
      ),
    );

    if (!interactive) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showBadgeDetails(context, badge),
      child: content,
    );
  }

  static void showBadgeDetails(BuildContext context, DiscordBadge badge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: colorScheme.outlineVariant.opaque(0.2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.opaque(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.badgeColor.withOpacity(0.12),
                  border: Border.all(
                    color: badge.badgeColor.withOpacity(0.35),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: badge.isSvg
                    ? SvgPicture.network(
                        badge.iconUrl,
                        width: 40,
                        height: 40,
                      )
                    : CachedNetworkImage(
                        imageUrl: badge.iconUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(height: 16),
              AnymeXText(
                badge.name,
                size: 18,
                variant: TextVariant.bold,
                color: colorScheme.onSurface,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge.badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badge.badgeColor.withOpacity(0.3),
                  ),
                ),
                child: AnymeXText(
                  badge.id.toUpperCase(),
                  size: 11,
                  variant: TextVariant.semiBold,
                  color: badge.badgeColor,
                ),
              ),
              const SizedBox(height: 16),
              AnymeXText(
                badge.description,
                size: 13,
                color: colorScheme.onSurfaceVariant,
                textAlign: TextAlign.center,
                maxLines: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

class DiscordBadgesRow extends StatelessWidget {
  final List<DiscordBadge>? badges;
  final String? role;
  final bool isOp;
  final double size;
  final bool interactive;

  const DiscordBadgesRow({
    super.key,
    this.badges,
    this.role,
    this.isOp = false,
    this.size = 15.0,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayBadges = <DiscordBadge>[];

    if (badges != null && badges!.isNotEmpty) {
      displayBadges.addAll(badges!);
    } else if (role != null && role != 'user') {
      final roleBadge = DiscordBadge.getRoleBadge(role);
      if (roleBadge != null) {
        displayBadges.add(roleBadge);
      }
    }

    if (isOp) {
      displayBadges.add(DiscordBadge.opBadge);
    }

    if (displayBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: displayBadges
          .map(
            (b) => DiscordBadgeWidget(
              badge: b,
              size: size,
              interactive: interactive,
            ),
          )
          .toList(),
    );
  }
}

