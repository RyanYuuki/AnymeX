import 'package:anymex/screens/anime/misc/barcode_scanner_page.dart';
import 'package:anymex/screens/anime/misc/calendar.dart';
import 'package:anymex/screens/anime/misc/list_exporter.dart';
import 'package:anymex/screens/anime/misc/recommendation.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
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
                SizedBox(
                  height: 170,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.auto_awesome,
                          title: 'AI Picks',
                          description: 'Smart manga suggestions',
                          accentColor: colorScheme.tertiary,
                          onTap: () => navigate(() => const AIRecommendation(
                                isManga: true,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Scanner',
                          description: 'Scan ISBN barcodes',
                          accentColor: colorScheme.tertiary,
                          onTap: () =>
                              navigate(() => const BarcodeScannerPage()),
                        ),
                      ),
                    ],
                  ),
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
        ]),
      ),
    );
  }
}

class NestedHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final bool disablePrefix;
  const NestedHeader(
      {super.key,
      required this.title,
      this.action,
      this.disablePrefix = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.opaque(0.4),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.opaque(0.2, iReallyMeanIt: true),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!disablePrefix && canPop) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: theme.colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .opaque(0.3, iReallyMeanIt: true),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: AnymexText(
              text: title,
              variant: TextVariant.semiBold,
              size: 22,
              isMarquee: true,
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
        ],
      ),
    );
  }
}

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
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
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
