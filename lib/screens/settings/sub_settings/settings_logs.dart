import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsLogs extends StatefulWidget {
  const SettingsLogs({super.key});

  @override
  State<SettingsLogs> createState() => _SettingsLogsState();
}

class _SettingsLogsState extends State<SettingsLogs> {

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Logs',
      body: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXSectionBuilder(
                        title: 'Log Capture',
                        children: [
                          Obx(
                            () => AnymeXTile.toggle(
                              icon: HugeIcons.strokeRoundedFile02,
                              title: 'Write log to a file',
                              subtitle:
                                  'When enabled, AnymeX saves logs locally until disabled.',
                              value: settings.writeLogToFile.value,
                              onChanged: (value) =>
                                  settings.saveWriteLogToFile(value),
                            ),
                          ),
                          AnymeXTile(
                            icon: HugeIcons.strokeRoundedShare08,
                            title: 'Share logs',
                            subtitle:
                                'Share the saved log file or copy its contents.',
                            onTap: () async => Logger.share(),
                          ),
                          Obx(
                            () => AnymeXTile(
                              icon: HugeIcons.strokeRoundedFolder01,
                              title: 'Log directory',
                              subtitle: settings
                                      .customLogDirectory.value.isEmpty
                                  ? 'Default (App Documents)'
                                  : settings.customLogDirectory.value,
                              onTap: () async {
                                String? result = await FilePicker.platform
                                    .getDirectoryPath();
                                if (result != null) {
                                  settings.saveCustomLogDirectory(result);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
    );
  }
}
