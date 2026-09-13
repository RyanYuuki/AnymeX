import 'package:anymex/controllers/security/incognito_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsIncognito extends StatelessWidget {
  const SettingsIncognito({super.key});

  void _showClearSessionDialog(
      BuildContext context, IncognitoController controller) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Clear Incognito Session',
        confirmText: 'Clear Session',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymeXText(
              'Are you sure you want to clear all active in-memory Incognito session data now?',
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            AnymeXText(
              'This will instantly reset temporary resume timestamps for this session.',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.primary,
              ),
            ),
          ],
        ),
        onConfirm: () {
          controller.clearSession(showToast: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IncognitoController>();

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Incognito & Privacy',
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16.0,
            AnymeXHeaderScope.of(ctx),
            16.0,
            30.0,
          ),
          child: Obx(
            () {
              final isActive = controller.isIncognito.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Hero Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.colors.primary.withOpacity(0.12)
                          : context.colors.surfaceContainer.opaque(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? context.colors.primary.withOpacity(0.35)
                            : context.colors.outline.opaque(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? context.colors.primary
                                : context.colors.surfaceContainerHighest
                                    .opaque(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 24,
                            color: isActive
                                ? context.colors.onPrimary
                                : context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnymeXText(
                                isActive
                                    ? 'Private Browsing is Active'
                                    : 'Incognito Mode is Off',
                                variant: TextVariant.bold,
                                size: 15,
                                color: isActive
                                    ? context.colors.primary
                                    : context.colors.onSurface,
                              ),
                              const SizedBox(height: 3),
                              AnymeXText(
                                isActive
                                    ? 'Watch progress, read chapters, and searches will never be saved to disk.'
                                    : 'Enable Incognito to browse anime and manga with complete zero-trace privacy.',
                                size: 12,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Master Switch Section
                  AnymeXSectionBuilder(
                    title: 'Private Browsing',
                    children: [
                      AnymeXTile(
                        icon: Icons.visibility_off_rounded,
                        title: 'Incognito Mode',
                        subtitle: isActive
                            ? 'Private browsing enabled (zero local traces)'
                            : 'Enable private browsing with zero history or tracking',
                        trailing: Switch(
                          value: isActive,
                          onChanged: (val) {
                            controller.toggleIncognito(value: val);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Privacy Controls Section
                  AnymeXSectionBuilder(
                    title: 'Privacy Controls',
                    children: [
                      AnymeXTile(
                        icon: Icons.cloud_off_rounded,
                        title: 'Stop Online Tracking',
                        subtitle:
                            'Block syncing progress to AniList, MyAnimeList & Simkl',
                        trailing: Switch(
                          value: controller.pauseOnlineTracking.value,
                          onChanged: controller.setPauseOnlineTracking,
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.history_toggle_off_rounded,
                        title: "Don't Save Watch & Read History",
                        subtitle:
                            'Do not save episodes or chapters to local database history',
                        trailing: Switch(
                          value: controller.pauseLocalHistory.value,
                          onChanged: controller.setPauseLocalHistory,
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.search_off_rounded,
                        title: "Don't Save Search Queries",
                        subtitle:
                            'Stop saving recent keywords in the search screen',
                        trailing: Switch(
                          value: controller.pauseSearchHistory.value,
                          onChanged: controller.setPauseSearchHistory,
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.hide_image_outlined,
                        title: 'Hide Continue Watching on Home',
                        subtitle:
                            'Hide the Continue Watching card and new releases on Home',
                        trailing: Switch(
                          value: controller.hideHomeRecent.value,
                          onChanged: controller.setHideHomeRecent,
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.sports_esports_rounded,
                        title: 'Pause Discord Rich Presence',
                        subtitle:
                            "Don't broadcast what you watch or read to Discord",
                        trailing: Switch(
                          value: controller.pauseDiscordRpc.value,
                          onChanged: controller.setPauseDiscordRpc,
                        ),
                      ),
                    ],
                  ),

                  // Session Lifecycle Section
                  AnymeXSectionBuilder(
                    title: 'Session & Data',
                    children: [
                      AnymeXTile(
                        icon: Icons.exit_to_app_rounded,
                        title: 'Auto-Exit on App Close',
                        subtitle:
                            'Automatically turn off Incognito and wipe session when app closes',
                        trailing: Switch(
                          value: controller.autoExitOnClose.value,
                          onChanged: controller.setAutoExitOnClose,
                        ),
                      ),
                      AnymeXTile(
                        icon: Icons.delete_sweep_rounded,
                        title: 'Clear Incognito Session Now',
                        subtitle:
                            'Instantly wipe all in-memory temporary session data',
                        onTap: () => _showClearSessionDialog(ctx, controller),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
