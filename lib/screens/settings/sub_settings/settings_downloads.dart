import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

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
      headerTitle: 'Download Settings',
      body: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 30.0),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXSectionBuilder(
                          title: 'Storage & Path',
                          children: [
                            AnymeXTile(
                              icon: Iconsax.folder_open,
                              title: 'Download Path',
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
                                title: 'Reset Download Path',
                                subtitle: 'Restore to default internal storage',
                                showChevron: false,
                                onTap: () => settings.saveDownloadPath(''),
                              ),
                          ],
                        ),
                        AnymeXSectionBuilder(
                          title: 'Concurrency & Limits',
                          children: [
                            AnymeXTile.slider(
                              icon: Iconsax.arrow_right_1,
                              title: 'Global Concurrency Limit',
                              subtitle: 'Number of active download tasks',
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
                              title: 'HLS Parallel Segments',
                              subtitle:
                                  'Parallel segments for video downloader',
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
                              title: 'Download Chunks',
                              subtitle: 'Number of parallel chunks per download',
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
                      ],
                    ),
                  ),
                )
    );
  }
}
