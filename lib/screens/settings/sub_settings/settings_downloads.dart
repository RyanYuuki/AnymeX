import 'package:anymex/l10n/l10n_extension.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:anymex/database/kv_helper.dart';

class SettingsDownloads extends StatefulWidget {
  const SettingsDownloads({super.key});

  @override
  State<SettingsDownloads> createState() => _SettingsDownloadsState();
}

class _SettingsDownloadsState extends State<SettingsDownloads> {

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: context.l10n.downloadSettings,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXSectionBuilder(
                          title: context.l10n.storagePath,
                          children: [
                            AnymeXTile(
                              icon: Iconsax.folder_open,
                              title: context.l10n.downloadPath,
                              subtitle: settings.downloadPath.value.isEmpty
                                  ? 'Default (Internal Storage)'
                                  : settings.downloadPath.value,
                              onTap: () async {
                                String? result = await FilePicker.platform
                                    .getDirectoryPath();
                                if (result != null) {
                                  settings.saveDownloadPath(result);
                                }
                              },
                            ),
                            if (settings.downloadPath.value.isNotEmpty)
                              AnymeXTile(
                                icon: Icons.refresh_rounded,
                                title: context.l10n.resetDownloadPath,
                                subtitle: context.l10n.restoreToDefaultInternalStorage,
                                showChevron: false,
                                onTap: () => settings.saveDownloadPath(''),
                              ),
                          ],
                        ),
                        AnymeXSectionBuilder(
                          title: context.l10n.concurrencyLimits,
                          children: [
                            AnymeXTile.slider(
                              icon: Iconsax.arrow_right_1,
                              title: context.l10n.globalConcurrencyLimit,
                              subtitle: context.l10n.numberOfActiveDownloadTasks,
                              value: settings.concurrentDownloads.value.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              valueTransformer: (v) => v.toInt().toString(),
                              onChanged: (v) =>
                                  settings.saveConcurrentDownloads(v.toInt()),
                            ),
                            AnymeXTile.slider(
                              icon: Iconsax.video,
                              title: context.l10n.hlsParallelSegments,
                              subtitle:
                                  context.l10n.parallelSegmentsForVideoDownloader,
                              value: settings.hlsParallelSegments.value
                                  .toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              valueTransformer: (v) => v.toInt().toString(),
                              onChanged: (v) =>
                                  settings.saveHlsParallelSegments(v.toInt()),
                            ),
                            AnymeXTile.slider(
                              icon: Iconsax.document_download,
                              title: context.l10n.downloadChunks,
                              subtitle: context.l10n.numberOfParallelChunksPerDownload,
                              value: settings.downloadChunks.value
                                  .toDouble(),
                              min: 1,
                              max: 8,
                              divisions: 7,
                              valueTransformer: (v) => v.toInt().toString(),
                              onChanged: (v) =>
                                  settings.saveDownloadChunks(v.toInt()),
                            ),
                          ],
                        ),
                        AnymeXSectionBuilder(
                          title: 'Notifications',
                          children: [
                            AnymeXTile.toggle(
                              icon: Icons.notifications_active_outlined,
                              title: 'Download Notifications',
                              subtitle:
                                  'Show rich notification with poster art when download completes',
                              value: KvHelper.get<bool>(
                                  'download_notifications_enabled',
                                  defaultVal: true),
                              onChanged: (v) {
                                KvHelper.set(
                                    'download_notifications_enabled', v);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
      ),
    );
  }
}
