import 'package:anymex/screens/anime/misc/calendar.dart';
import 'package:anymex/screens/anime/misc/recommendation.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:flutter/material.dart';

class OtherFeaturesPage extends StatelessWidget {
  const OtherFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Glow(
      child: Scaffold(
        body: Column(children: [
          const NestedHeader(title: 'Other Features'),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Anime',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Calendar',
                          description: 'Track airing schedules',
                          color: colorScheme.secondaryContainer,
                          onColor: colorScheme.onSecondaryContainer,
                          onTap: () => navigate(() => const Calendar()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.auto_awesome,
                          title: 'AI Picks',
                          description: 'Personalized recommendations',
                          color: colorScheme.secondaryContainer,
                          onColor: colorScheme.onSecondaryContainer,
                          onTap: () => navigate(() => const AIRecommendation(
                                isManga: false,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: colorScheme.tertiary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Manga',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FeatureCard(
                  icon: Icons.auto_awesome,
                  title: 'AI Picks',
                  description:
                      'Discover your next favorite manga with AI-powered suggestions',
                  color: colorScheme.tertiaryContainer,
                  onColor: colorScheme.onTertiaryContainer,
                  isFullWidth: true,
                  onTap: () => navigate(() => const AIRecommendation(
                        isManga: true,
                      )),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class NestedHeader extends StatelessWidget {
  final String title;
  const NestedHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: theme.colorScheme.onSurface,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color onColor;
  final bool isFullWidth;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onColor,
    this.isFullWidth = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isFullWidth ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: onColor,
                  size: isFullWidth ? 32 : 28,
                ),
              ),
              SizedBox(height: isFullWidth ? 16 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isFullWidth ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: onColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: isFullWidth ? 14 : 13,
                  color: onColor.withOpacity(0.8),
                  height: 1.3,
                ),
                maxLines: isFullWidth ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
