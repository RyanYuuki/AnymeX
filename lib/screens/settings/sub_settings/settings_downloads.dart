import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsDownloads extends StatelessWidget {
  const SettingsDownloads({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Download Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: getResponsiveValue(context,
                    mobileValue:
                        const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 50.0),
                    desktopValue:
                        const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Column(
                          children: [
                            AnymexExpansionTile(
                              title: 'Common Settings',
                              initialExpanded: true,
                              content: Column(
                                children: [
                                  CustomTile(
                                    padding: 10,
                                    icon: Iconsax.folder_open,
                                    title: 'Download Path',
                                    description:
                                        settings.downloadPath.value.isEmpty
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
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: TextButton(
                                        onPressed: () =>
                                            settings.saveDownloadPath(''),
                                        child: const Text('Reset to Default'),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  CustomSliderTile(
                                    icon: Iconsax.arrow_right_1,
                                    title: 'Global Concurrency Limit',
                                    description:
                                        'Number of active download tasks',
                                    sliderValue: settings
                                        .concurrentDownloads.value
                                        .toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: settings.concurrentDownloads.value
                                        .toString(),
                                    onChanged: (val) {
                                      settings.saveConcurrentDownloads(
                                          val.toInt());
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  CustomSliderTile(
                                    icon: Iconsax.document_download,
                                    title: 'Parallel Chunks per File',
                                    description:
                                        'Speeds up standard file downloads',
                                    sliderValue:
                                        settings.downloadChunks.value.toDouble(),
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: settings.downloadChunks.value
                                        .toString(),
                                    onChanged: (val) {
                                      settings.saveDownloadChunks(val.toInt());
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnymexExpansionTile(
                              title: 'Anime Settings',
                              content: Column(
                                children: [
                                  CustomSliderTile(
                                    icon: Iconsax.video_vertical,
                                    title: 'HLS Parallel Segments',
                                    description:
                                        'Concurrent fragments for HLS streams',
                                    sliderValue: settings
                                        .hlsParallelSegments.value
                                        .toDouble(),
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: settings.hlsParallelSegments.value
                                        .toString(),
                                    onChanged: (val) {
                                      settings.saveHlsParallelSegments(
                                          val.toInt());
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnymexExpansionTile(
                              title: 'Manga Settings',
                              content: Column(
                                children: [
                                  CustomSwitchTile(
                                    icon: Iconsax.image,
                                    title: 'Enable JXL Compression',
                                    description:
                                        'Compresses manga images to JXL (lossless)',
                                    switchValue: settings.enableJxlCompression.value,
                                    onChanged: (val) {
                                      settings.saveEnableJxlCompression(val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
