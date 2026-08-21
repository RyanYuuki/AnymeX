import 'dart:io';
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/screens/anime/misc/calendar.dart';
import 'package:anymex/screens/anime/misc/list_exporter.dart';
import 'package:anymex/screens/anime/misc/recommendation.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_header.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

class OtherFeaturesPage extends StatelessWidget {
  const OtherFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnymeXScaffold(
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
                    AnymeXText(
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
                          accentColor: colorScheme.primary,
                          onTap: () => navigate(() => const Calendar()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.auto_awesome,
                          title: 'AI Picks',
                          description: 'Personalized recommendations',
                          accentColor: colorScheme.primary,
                          onTap: () => navigate(() => const AIRecommendation(
                                isManga: false,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.file_upload_rounded,
                  title: 'List Exporter',
                  description: 'Export your Anime list',
                  accentColor: colorScheme.primary,
                  isFullWidth: true,
                  onTap: () =>
                      navigate(() => const ListExporterPage(isManga: false)),
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
                    AnymeXText(
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
                  description: 'Smart manga suggestions',
                  accentColor: colorScheme.tertiary,
                  isFullWidth: true,
                  onTap: () => navigate(() => const AIRecommendation(
                        isManga: true,
                      )),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.file_upload_rounded,
                  title: 'List Exporter',
                  description: 'Export your Manga list',
                  accentColor: colorScheme.tertiary,
                  isFullWidth: true,
                  onTap: () =>
                      navigate(() => const ListExporterPage(isManga: true)),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ])
);
  }
}

typedef NestedHeader = AnymeXHeader;

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? accentColor;
  final bool isFullWidth;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.accentColor,
    this.isFullWidth = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final effectiveAccent = accentColor ?? cs.primary;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
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
                    color: effectiveAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveAccent,
                    size: isFullWidth ? 28 : 24,
                  ),
                ),
                SizedBox(height: isFullWidth ? 16 : 12),
                AnymeXText(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                AnymeXText(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.8),
                    height: 1.3,
                  ),
                  maxLines: isFullWidth ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
