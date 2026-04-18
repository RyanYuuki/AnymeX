import 'package:anymex/database/isar_models/chapter.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/screens/downloads/controller/download_controller.dart';
import 'package:anymex/screens/downloads/controller/download_search_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:hugeicons/hugeicons.dart';

class MangaChapterDownloadConfirm extends StatelessWidget {
  final List<Chapter> chapters;
  final Source source;
  final OfflineMedia media;

  const MangaChapterDownloadConfirm({
    super.key,
    required this.chapters,
    required this.source,
    required this.media,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Chapter> chapters,
    required Source source,
    required OfflineMedia media,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MangaChapterDownloadConfirm(
        chapters: chapters,
        source: source,
        media: media,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final count = chapters.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.onSurface.opaque(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryContainer.opaque(0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(HugeIcons.strokeRoundedDownload04,
                    color: theme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnymexText(
                      text: 'Start Manga Download',
                      variant: TextVariant.bold,
                      size: 16,
                    ),
                    AnymexText(
                      text: media.name ?? '',
                      size: 13,
                      maxLines: 1,
                      color: theme.onSurface.opaque(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surfaceContainer.opaque(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.outline.opaque(0.12)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  theme: theme,
                  icon: HugeIcons.strokeRoundedBook02,
                  label: 'Chapters',
                  value: count.toString(),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme: theme,
                  icon: HugeIcons.strokeRoundedGlobe,
                  label: 'Source',
                  value: source.name ?? 'Unknown',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme: theme,
                  icon: HugeIcons.strokeRoundedFolder01,
                  label: 'Location',
                  value: 'AnymeX/Downloads/Manga',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primary.opaque(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.opaque(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: theme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: AnymexText(
                    text:
                        'Images will be downloaded in full quality. Each chapter is stored in its own folder.',
                    size: 12,
                    color: theme.primary.opaque(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SafeArea(
            child: AnymexButton(
              onTap: () => _startDownload(context),
              color: theme.primary,
              radius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(HugeIcons.strokeRoundedDownload04,
                      size: 20, color: theme.onPrimary),
                  const SizedBox(width: 8),
                  AnymexText(
                    text:
                        'Download $count Chapter${count != 1 ? 's' : ''}',
                    size: 15,
                    variant: TextVariant.semiBold,
                    color: theme.onPrimary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _startDownload(BuildContext context) {
    final downloadController = Get.find<DownloadController>();
    Navigator.pop(context);

    final ctrl = Get.find<DownloadSearchController>();
    ctrl.resetDetail();

    downloadController.enqueueMangaDownloadBatch(
      chapters: chapters,
      source: source,
      media: media,
    );

    snackBar('Downloading ${ chapters.length} chapter${chapters.length != 1 ? 's' : ''}...');
  }

  Widget _buildInfoRow({
    required ColorScheme theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primary),
        const SizedBox(width: 10),
        AnymexText(
          text: label,
          size: 13,
          color: theme.onSurface.opaque(0.6),
        ),
        const Spacer(),
        Flexible(
          child: AnymexText(
            text: value,
            size: 13,
            variant: TextVariant.semiBold,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
