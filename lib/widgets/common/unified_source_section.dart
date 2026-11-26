import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/wrongtitle_modal.dart';
import 'package:anymex/screens/extensions/ExtensionSettings/ExtensionSettings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/common/cloudflare_webview.dart';
import 'package:anymex/widgets/common/source_selector.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex_extension_runtime_bridge/Services/CloudStream/CloudStreamSourceMethods.dart';
import 'package:flutter/material.dart';

class UnifiedSourceSection extends StatelessWidget {
  final Media media;
  final String searchedTitle;
  final Source activeSource;
  final List<Source> installedSources;
  final Function(Source) onSourceSelected;
  final Function(Source)? onSubSourceSelected;
  final Function(DMedia) onWrongTitleMapped;

  const UnifiedSourceSection({
    super.key,
    required this.media,
    required this.searchedTitle,
    required this.activeSource,
    required this.installedSources,
    required this.onSourceSelected,
    this.onSubSourceSelected,
    required this.onWrongTitleMapped,
  });

  void _openSourcePreferences(BuildContext context) async {
    if (activeSource is CloudStreamSource) {
      if ((activeSource as CloudStreamSource).hasSettings) {
        await CloudStreamSourceMethods(activeSource as CloudStreamSource)
            .openNativeSettings();
      }
      return;
    }
    navigate(() => SourcePreferenceScreen(source: activeSource));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isNovel = media.mediaType == ItemType.novel;
    final isManga = media.mediaType == ItemType.manga;

    final isError = searchedTitle.contains('No Match') ||
        searchedTitle.contains('Error') ||
        searchedTitle.contains('Failed') ||
        searchedTitle.contains('No Source') ||
        searchedTitle.contains('No Episodes') ||
        searchedTitle.contains('No Chapters');

    String prefix = '';
    String titleText = '';
    bool isTitleMarquee = false;

    if (isError) {
      prefix = '';
      titleText = searchedTitle;
      isTitleMarquee = false;
    } else if (searchedTitle.toLowerCase().startsWith('searching:')) {
      prefix = 'Searching:';
      titleText = searchedTitle.substring('searching:'.length).trim();
      isTitleMarquee = titleText.isNotEmpty;
    } else if (searchedTitle.toLowerCase().startsWith('finding:')) {
      prefix = 'Finding:';
      titleText = searchedTitle.substring('finding:'.length).trim();
      isTitleMarquee = titleText.isNotEmpty;
    } else {
      final clean = searchedTitle
          .replaceFirst(
              RegExp(r'^(Matched:\s*|Found:\s*)', caseSensitive: false), '')
          .trim();
      if (clean.isNotEmpty) {
        prefix = 'Found:';
        titleText = clean;
        isTitleMarquee = true;
      } else {
        prefix = '';
        titleText = '';
        isTitleMarquee = false;
      }
    }

    return SourceSelectorWidget(
      activeSource: activeSource,
      installedSources: installedSources,
      isManga: !isNovel && isManga,
      onSourceSelected: onSourceSelected,
      onSubSourceSelected: onSubSourceSelected,
      onCloudflareBypass: (activeSource.baseUrl?.isNotEmpty ?? false)
          ? () => context.openCloudflareBypass(activeSource.baseUrl!)
          : null,
      onPreferencesTap: () => _openSourcePreferences(context),
      bottomWidget: Row(
        children: [
          if (prefix.isNotEmpty) ...[
            AnymeXText(
              prefix,
              variant: TextVariant.semiBold,
              size: 12.5,
              color: colors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: AnymeXText(
              titleText,
              variant: TextVariant.semiBold,
              size: 12.5,
              color: isError ? colors.error : colors.primary,
              isMarquee: isTitleMarquee,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showWrongTitleModal(
                context,
                media.title,
                onWrongTitleMapped,
                isManga: !isNovel && isManga,
                isNovel: isNovel,
                mediaId: media.id.toString(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 5),
                  AnymeXText(
                    context.l10n.wrongTitle,
                    size: 12,
                    color: colors.primary,
                    variant: TextVariant.semiBold,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
