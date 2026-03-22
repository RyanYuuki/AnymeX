import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsLogs extends StatelessWidget {
  const SettingsLogs({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<Settings>();

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Logs'),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: getResponsiveValue(context,
                      mobileValue:
                          const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                      desktopValue:
                          const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymexExpansionTile(
                        title: 'Logs',
                        initialExpanded: true,
                        content: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.colors.outline
                                      .withValues(alpha: 0.18),
                                ),
                              ),
                              child: Text(
                                'Turn this on only when you need to report a bug. '
                                'After enabling it, reproduce the issue and then use the share button below to send the saved log file.',
                                style: TextStyle(
                                  color: context.colors.onSurface
                                      .withValues(alpha: 0.78),
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ),
                            Obx(
                              () => CustomSwitchTile(
                                icon: HugeIcons.strokeRoundedFile02,
                                title: 'Write log to a file',
                                description:
                                    'Off by default. When enabled, AnymeX saves logs locally until you turn it off again.',
                                switchValue: settings.writeLogToFile.value,
                                onChanged: (value) =>
                                    settings.saveWriteLogToFile(value),
                              ),
                            ),
                            CustomTile(
                              icon: HugeIcons.strokeRoundedShare08,
                              title: 'Share logs',
                              description:
                                  'Share the saved log file or copy its contents when available.',
                              onTap: () async => Logger.share(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
