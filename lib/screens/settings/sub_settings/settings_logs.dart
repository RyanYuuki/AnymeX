import 'package:anymex/l10n/l10n_extension.dart';
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
      headerTitle: context.l10n.logs,
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.0, AnymeXHeaderScope.of(ctx), 16.0, 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXSectionBuilder(
                        title: context.l10n.logCapture,
                        children: [
                          Obx(
                            () => AnymeXTile.toggle(
                              icon: HugeIcons.strokeRoundedFile02,
                              title: context.l10n.writeLogToAFile,
                              subtitle:
                                  context.l10n.whenEnabledAnymexSavesLogsLocally,
                              value: settings.writeLogToFile.value,
                              onChanged: (value) =>
                                  settings.saveWriteLogToFile(value),
                            ),
                          ),
                          AnymeXTile(
                            icon: HugeIcons.strokeRoundedShare08,
                            title: context.l10n.shareLogs,
                            subtitle:
                                context.l10n.shareTheSavedLogFileOr,
                            onTap: () async => Logger.share(),
                          ),
                          Obx(
                            () => AnymeXTile(
                              icon: HugeIcons.strokeRoundedFolder01,
                              title: context.l10n.logDirectory,
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
      ),
    );
  }
}
