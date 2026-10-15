import 'package:anymex/controllers/sync/cloud/cloud_sync_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class WebDavPreset {
  final String id;
  final String name;
  final String description;
  final String defaultUrl;
  final String websiteUrl;
  final String usernameHint;
  final List<String> setupGuide;
  final IconData icon;

  const WebDavPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultUrl,
    required this.websiteUrl,
    required this.usernameHint,
    required this.setupGuide,
    required this.icon,
  });
}

const List<WebDavPreset> kWebDavPresets = [
  WebDavPreset(
    id: 'koofr',
    name: 'Koofr',
    description: 'Reliable cloud storage with WebDAV',
    defaultUrl: 'https://app.koofr.net/dav/Koofr/',
    websiteUrl: 'https://koofr.eu',
    usernameHint: 'Koofr account email',
    setupGuide: [
      'Create an account at koofr.eu',
      'Go to Settings ➔ Preferences ➔ Password',
      'Generate an App Password (name it "AnymeX")',
      'Enter your email and the generated password',
    ],
    icon: Icons.cloud_outlined,
  ),
  WebDavPreset(
    id: 'yandex',
    name: 'Yandex Disk',
    description: 'Stable cloud storage endpoint',
    defaultUrl: 'https://webdav.yandex.com',
    websiteUrl: 'https://disk.yandex.com',
    usernameHint: 'Yandex account username',
    setupGuide: [
      'Open disk.yandex.com',
      'In Account Security, create an App Password for "Files (WebDAV)"',
      'Enter your Yandex login and the app password',
    ],
    icon: Icons.storage_rounded,
  ),
  WebDavPreset(
    id: 'hidrive',
    name: 'HiDrive',
    description: 'Secure cloud storage by IONOS',
    defaultUrl: 'https://webdav.hidrive.ionos.com/',
    websiteUrl: 'https://hidrive.ionos.com',
    usernameHint: 'HiDrive username',
    setupGuide: [
      'Open hidrive.ionos.com',
      'In Account Settings, ensure WebDAV access is enabled',
      'Enter your HiDrive credentials below',
    ],
    icon: Icons.folder_shared_outlined,
  ),
];

class SettingsCloudSync extends StatefulWidget {
  const SettingsCloudSync({super.key});

  static void push(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsCloudSync()),
      );

  @override
  State<SettingsCloudSync> createState() => _SettingsCloudSyncState();
}

class _SettingsCloudSyncState extends State<SettingsCloudSync> {
  late final CloudSyncController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<CloudSyncController>()
        ? Get.find<CloudSyncController>()
        : Get.put(CloudSyncController());
  }

  void _openSetupSheet(BuildContext context) {
    AnymeXSheet.custom(
      _CloudSyncConfigSheet(controller: controller),
      context,
      showDragHandle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Cloud Sync',
      body: Builder(
        builder: (ctx) => ScrollWrapper(
          comfortPadding: false,
          customPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0),
          children: [
            SizedBox(height: AnymeXHeaderScope.of(ctx)),

            // Hero Status Card
            Obx(() {
              final connected = controller.isConnected.value;
              final isSyncing = controller.isBusy.value;
              final lastSync = controller.lastSyncTime.value;
              final isGist = controller.selectedProvider.value == 'gist';

              String providerLabel = 'Not Connected';
              IconData providerIcon = Icons.cloud_off_rounded;
              String providerDesc = 'Connect a provider to sync across devices';

              if (connected) {
                if (isGist) {
                  final ghUser =
                      SyncKeys.gistGithubUsername.get<String>('');
                  providerLabel = 'GitHub Gist Synced';
                  providerIcon = Icons.code_rounded;
                  providerDesc = ghUser.isNotEmpty
                      ? 'Connected as @$ghUser · anymex_progress.json'
                      : 'Connected with GitHub Gist';
                } else {
                  final matchedPreset = kWebDavPresets.firstWhere(
                    (p) => controller.webdavUrl.value.contains(p.id),
                    orElse: () => kWebDavPresets.first,
                  );
                  providerLabel = '${matchedPreset.name} Synced';
                  providerIcon = matchedPreset.icon;
                  providerDesc = controller.webdavUsername.value.isNotEmpty
                      ? '${controller.webdavUsername.value} · ${matchedPreset.defaultUrl}'
                      : matchedPreset.defaultUrl;
                }
              }

              return AnymeXContainer(
                padding: const EdgeInsets.all(20),
                radius: 20,
                color: colors.surfaceContainerLow.withOpacity(0.5),
                border: Border.all(
                  color: connected
                      ? colors.primary.withOpacity(0.4)
                      : colors.outline.withOpacity(0.1),
                  width: 1,
                ),
                enableGlow: connected,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnymeXContainer(
                          padding: const EdgeInsets.all(12),
                          radius: 14,
                          color: connected
                              ? colors.primary.withOpacity(0.12)
                              : colors.surfaceContainerHighest.withOpacity(0.5),
                          child: Icon(
                            connected ? providerIcon : Icons.cloud_off_rounded,
                            color: connected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  AnymeXText(
                                    providerLabel,
                                    variant: TextVariant.bold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  AnymeXContainer(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    radius: 6,
                                    color: connected
                                        ? colors.primary.withOpacity(0.15)
                                        : colors.error.withOpacity(0.12),
                                    child: AnymeXText(
                                      connected ? 'ACTIVE' : 'IDLE',
                                      size: 10,
                                      variant: TextVariant.bold,
                                      color: connected
                                          ? colors.primary
                                          : colors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              AnymeXText(
                                providerDesc,
                                size: 12,
                                maxLines: 1,
                                color: colors.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (connected && lastSync != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          AnymeXText(
                            'Last updated: ${lastSync.day}/${lastSync.month}/${lastSync.year} at ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}',
                            size: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        if (connected) ...[
                          Expanded(
                            child: AnymeXButton(
                              height: 42,
                              borderRadius: BorderRadius.circular(12),
                              onTap: isSyncing
                                  ? () {}
                                  : () => controller.syncNow(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSyncing)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.onPrimary,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.sync_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  AnymeXText(
                                    isSyncing ? 'Syncing...' : 'Sync Now',
                                    variant: TextVariant.bold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnymeXContainer(
                            radius: 12,
                            color: colors.surfaceContainerHighest.withOpacity(0.5),
                            child: IconButton(
                              tooltip: 'Configure Provider',
                              icon: Icon(Icons.tune_rounded,
                                  size: 20, color: colors.onSurface),
                              onPressed: () => _openSetupSheet(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnymeXContainer(
                            radius: 12,
                            color: colors.surfaceContainerHighest.withOpacity(0.5),
                            child: IconButton(
                              tooltip: 'Disconnect',
                              icon: Icon(Icons.logout_rounded,
                                  size: 20, color: colors.error),
                              onPressed: () => controller.disconnect(),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: AnymeXButton(
                              height: 42,
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openSetupSheet(context),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_link_rounded, size: 18),
                                  SizedBox(width: 8),
                                  AnymeXText(
                                    'Connect Cloud Provider',
                                    variant: TextVariant.bold,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Sync Triggers
            AnymeXSectionBuilder(
              title: 'Sync Automation',
              children: [
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.bolt_rounded,
                      title: 'Sync on App Launch',
                      subtitle:
                          'Automatically pulls updates when opening AnymeX',
                      value: controller.autoSyncOnLaunch.value,
                      onChanged: (v) {
                        controller.autoSyncOnLaunch.value = v;
                      },
                    )),
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.exit_to_app_rounded,
                      title: 'Sync on Exit',
                      subtitle:
                          'Pushes latest progress before closing or minimizing',
                      value: controller.autoSyncOnExit.value,
                      onChanged: (v) {
                        controller.autoSyncOnExit.value = v;
                      },
                    )),
              ],
            ),

            const SizedBox(height: 16),

            // Items to Sync
            AnymeXSectionBuilder(
              title: 'Synced Data',
              children: [
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.video_library_rounded,
                      title: 'Library',
                      subtitle:
                          'Anime, Manga, Novels, and Custom Lists',
                      value: controller.syncLibrary.value,
                      onChanged: (v) {
                        controller.syncLibrary.value = v;
                      },
                    )),
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.history_rounded,
                      title: 'Watch & Reading History',
                      subtitle:
                          'Timestamps, completed episodes, and chapters',
                      value: controller.syncHistory.value,
                      onChanged: (v) {
                        controller.syncHistory.value = v;
                      },
                    )),
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.tune_rounded,
                      title: 'App Settings & Preferences',
                      subtitle: 'Player, theme, subtitles, and layout options',
                      value: controller.syncSettings.value,
                      onChanged: (v) {
                        controller.syncSettings.value = v;
                      },
                    )),
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.query_stats_rounded,
                      title: 'Watch & Read Statistics',
                      subtitle: 'Daily minutes watched and chapter stats',
                      value: controller.syncStats.value,
                      onChanged: (v) {
                        controller.syncStats.value = v;
                      },
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudSyncConfigSheet extends StatefulWidget {
  final CloudSyncController controller;

  const _CloudSyncConfigSheet({required this.controller});

  @override
  State<_CloudSyncConfigSheet> createState() => _CloudSyncConfigSheetState();
}

class _CloudSyncConfigSheetState extends State<_CloudSyncConfigSheet> {
  late final RxString selectedProviderId;
  late final TextEditingController userController;
  late final TextEditingController passController;
  late final TextEditingController tokenController;
  final isPasswordVisible = false.obs;

  GistSyncController get gistCtrl => Get.isRegistered<GistSyncController>()
      ? Get.find<GistSyncController>()
      : Get.put(GistSyncController());

  @override
  void initState() {
    super.initState();
    selectedProviderId = (widget.controller.selectedProvider.value.isNotEmpty
            ? widget.controller.selectedProvider.value
            : 'gist')
        .obs;

    userController =
        TextEditingController(text: widget.controller.webdavUsername.value);
    passController =
        TextEditingController(text: widget.controller.webdavPassword.value);
    tokenController = TextEditingController(
      text: SyncKeys.gistGithubToken.get<String>(''),
    );
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AnymeXText(
                    'Configure Cloud Sync',
                    variant: TextVariant.bold,
                    size: 18,
                  ),
                  const Spacer(),
                  Obx(() {
                    if (selectedProviderId.value == 'gist') {
                      return const SizedBox.shrink();
                    }
                    final p = kWebDavPresets.firstWhere(
                      (preset) => preset.id == selectedProviderId.value,
                      orElse: () => kWebDavPresets.first,
                    );
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        launchUrl(Uri.parse(p.websiteUrl),
                            mode: LaunchMode.externalApplication);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 14, color: colors.primary),
                            const SizedBox(width: 4),
                            AnymeXText('Visit Site',
                                size: 12, color: colors.primary),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 14),

              // Themed Provider Selector Pills
              Obx(() => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildProviderPill(
                          id: 'gist',
                          name: 'GitHub Gist',
                          icon: Icons.code_rounded,
                          colors: colors,
                        ),
                        ...kWebDavPresets.map((p) => _buildProviderPill(
                              id: p.id,
                              name: p.name,
                              icon: p.icon,
                              colors: colors,
                            )),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // Dynamic content based on selected provider
              Obx(() {
                if (selectedProviderId.value == 'gist') {
                  return _buildGistConfig(colors);
                } else {
                  final preset = kWebDavPresets.firstWhere(
                    (p) => p.id == selectedProviderId.value,
                    orElse: () => kWebDavPresets.first,
                  );
                  return _buildWebDavConfig(preset, colors);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderPill({
    required String id,
    required String name,
    required IconData icon,
    required ColorScheme colors,
  }) {
    final isSel = selectedProviderId.value == id;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => selectedProviderId.value = id,
        child: AnymeXContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          radius: 12,
          color: isSel
              ? colors.primary.withOpacity(0.18)
              : colors.surfaceContainerHighest.withOpacity(0.35),
          border: Border.all(
            color: isSel
                ? colors.primary.withOpacity(0.7)
                : colors.outline.withOpacity(0.1),
            width: isSel ? 1.4 : 1,
          ),
          enableGlow: isSel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSel ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              AnymeXText(
                name,
                variant: isSel ? TextVariant.bold : TextVariant.regular,
                size: 13,
                color: isSel ? colors.primary : colors.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGistConfig(ColorScheme colors) {
    return Obx(() {
      final isLogged = gistCtrl.isLoggedIn.value;
      final ghUser = gistCtrl.githubUsername.value ??
          SyncKeys.gistGithubUsername.get<String>('');
      final avatar = gistCtrl.githubAvatarUrl.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXContainer(
            padding: const EdgeInsets.all(14),
            radius: 14,
            color: colors.surfaceContainerHighest.withOpacity(0.3),
            border: Border.all(color: colors.outline.withOpacity(0.1)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (avatar != null && avatar.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AnymeXImage(
                          url: avatar,
                          width: 32,
                          height: 32,
                        ),
                      )
                    else
                      AnymeXContainer(
                        padding: const EdgeInsets.all(6),
                        radius: 8,
                        color: colors.primary.withOpacity(0.12),
                        child: Icon(Icons.code_rounded,
                            size: 20, color: colors.primary),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(
                            isLogged
                                ? 'Connected as @$ghUser'
                                : 'GitHub Gist Storage',
                            variant: TextVariant.bold,
                            size: 14,
                          ),
                          const SizedBox(height: 2),
                          AnymeXText(
                            'Stores your data securely in anymex_progress.json',
                            size: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnymeXText(
                  'Syncs your library, watched episodes, read chapters, source mappings, and preferences directly to your personal GitHub Gist.',
                  size: 12,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (isLogged) ...[
            AnymeXButton(
              height: 44,
              borderRadius: BorderRadius.circular(12),
              onTap: widget.controller.isBusy.value
                  ? () {}
                  : () async {
                      final ok = await widget.controller.connectGist();
                      if (ok && mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: widget.controller.isBusy.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : const AnymeXText(
                      'Use This GitHub Account & Save',
                      variant: TextVariant.bold,
                    ),
            ),
          ] else ...[
            AnymeXButton(
              height: 44,
              borderRadius: BorderRadius.circular(12),
              onTap: gistCtrl.isAuthenticating.value
                  ? () {}
                  : () async {
                      await gistCtrl.login(context);
                      if (gistCtrl.isLoggedIn.value) {
                        await widget.controller.connectGist();
                        if (mounted) Navigator.of(context).pop();
                      }
                    },
              child: gistCtrl.isAuthenticating.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 18),
                        SizedBox(width: 8),
                        AnymeXText(
                          'Sign In with GitHub',
                          variant: TextVariant.bold,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Divider(color: colors.outline.withOpacity(0.15))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: AnymeXText('or Personal Token',
                      size: 11, color: colors.onSurfaceVariant),
                ),
                Expanded(child: Divider(color: colors.outline.withOpacity(0.15))),
              ],
            ),
            const SizedBox(height: 12),
            _buildThemedTextField(
              controller: tokenController,
              label: 'GitHub Personal Access Token (PAT)',
              hint: 'ghp_xxxxxxxxxxxxxxxxxxxx',
              icon: Icons.key_rounded,
              colors: colors,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  launchUrl(
                    Uri.parse(
                        'https://github.com/settings/tokens/new?scopes=gist&description=AnymeX%20Sync'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: AnymeXText(
                  'Generate Token on GitHub ➔',
                  size: 11,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnymeXButton(
              height: 44,
              borderRadius: BorderRadius.circular(12),
              onTap: widget.controller.isBusy.value
                  ? () {}
                  : () async {
                      final token = tokenController.text.trim();
                      if (token.isEmpty) return;
                      final ok =
                          await widget.controller.connectGist(token: token);
                      if (ok && mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: const AnymeXText(
                'Connect with Token',
                variant: TextVariant.bold,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildWebDavConfig(WebDavPreset preset, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Setup Guide Box
        AnymeXContainer(
          padding: const EdgeInsets.all(12),
          radius: 12,
          color: colors.surfaceContainerHighest.withOpacity(0.3),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnymeXText(
                'Setup Guide for ${preset.name}',
                variant: TextVariant.bold,
                size: 12,
                color: colors.primary,
              ),
              const SizedBox(height: 6),
              ...preset.setupGuide.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        '${e.key + 1}. ',
                        size: 11,
                        variant: TextVariant.bold,
                        color: colors.primary,
                      ),
                      Expanded(
                        child: AnymeXText(
                          e.value,
                          size: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Automated Endpoint Pill
        AnymeXContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          radius: 12,
          color: colors.surfaceContainerLow.withOpacity(0.5),
          border: Border.all(color: colors.outline.withOpacity(0.1)),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymeXText('Server Endpoint (Automated)',
                        size: 10, color: colors.onSurfaceVariant),
                    const SizedBox(height: 1),
                    AnymeXText(
                      preset.defaultUrl,
                      size: 12,
                      variant: TextVariant.bold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildThemedTextField(
          controller: userController,
          label: 'Username or Email',
          hint: preset.usernameHint,
          icon: Icons.person_outline_rounded,
          colors: colors,
        ),

        const SizedBox(height: 10),

        Obx(() => _buildThemedTextField(
              controller: passController,
              label: 'Password or App Password',
              hint: 'Generated app password',
              icon: Icons.lock_outline_rounded,
              obscureText: !isPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible.value
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: () => isPasswordVisible.toggle(),
              ),
              colors: colors,
            )),

        const SizedBox(height: 18),

        Obx(() => AnymeXButton(
              height: 44,
              borderRadius: BorderRadius.circular(12),
              onTap: widget.controller.isBusy.value
                  ? () {}
                  : () async {
                      final user = userController.text.trim();
                      final pass = passController.text.trim();

                      if (user.isEmpty || pass.isEmpty) return;

                      final ok = await widget.controller.saveWebDavConfig(
                        url: preset.defaultUrl,
                        username: user,
                        password: pass,
                      );
                      if (ok && mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: widget.controller.isBusy.value
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : const AnymeXText(
                      'Save & Connect',
                      variant: TextVariant.bold,
                    ),
            )),
      ],
    );
  }

  Widget _buildThemedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colors,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return AnymeXContainer(
      radius: 14,
      color: colors.surfaceContainerHighest.withOpacity(0.35),
      border: Border.all(color: colors.outline.withOpacity(0.15)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Linotte',
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'Linotte',
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  color: colors.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 13,
                  fontFamily: 'Linotte',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }
}
