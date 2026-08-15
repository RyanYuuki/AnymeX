import 'dart:io';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SourceSelectorWidget(
          activeSource: activeSource,
          installedSources: installedSources,
          isManga: !isNovel && isManga,
          onSourceSelected: onSourceSelected,
          onSubSourceSelected: onSubSourceSelected,
          onCloudflareBypass: !Platform.isLinux &&
                  (activeSource.baseUrl?.isNotEmpty ?? false)
              ? () => context.openCloudflareBypass(activeSource.baseUrl!)
              : null,
          onPreferencesTap: () => _openSourcePreferences(context),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AnymeXText(
                  text: searchedTitle,
                  variant: TextVariant.semiBold,
                  size: 13,
                  color: searchedTitle.contains('No Match Found')
                      ? colors.error
                      : colors.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
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
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer
                        .opaque(0.4, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.primary.opaque(0.3, iReallyMeanIt: true),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      AnymeXText(
                        text: "Wrong Title?",
                        size: 11,
                        color: colors.primary,
                        variant: TextVariant.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
