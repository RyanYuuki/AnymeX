import 'package:anymex/controllers/sync/cloud/cloud_sync_controller.dart';
import 'package:anymex/controllers/sync/gist_sync_controller.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dropdown.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_expansion_tile.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
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

  void _showDisconnectDialog(BuildContext context) {
    AnymeXDialog(
      title: 'Disconnect Cloud Sync?',
      message:
          'Your local library will stay on this device, but automatic syncing will stop until you connect again.',
      confirmText: 'Disconnect',
      cancelText: 'Keep Connected',
      onConfirm: () => controller.disconnect(),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Cloud Sync',
      body: Builder(
        builder: (ctx) => ScrollWrapper(
          comfortPadding: false,
          customPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0),
          children: [
            SizedBox(height: AnymeXHeaderScope.of(ctx)),
            _CloudSyncStatusCard(
              controller: controller,
              onConfigure: () => _openSetupSheet(context),
              onDisconnect: () => _showDisconnectDialog(context),
            ),
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
            AnymeXSectionBuilder(
              title: 'Synced Data',
              children: [
                Obx(() => AnymeXTile.toggle(
                      icon: Icons.video_library_rounded,
                      title: 'Library',
                      subtitle: 'Anime, Manga, Novels, and Custom Lists',
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

class _CloudSyncStatusCard extends StatelessWidget {
  final CloudSyncController controller;
  final VoidCallback onConfigure;
  final VoidCallback onDisconnect;

  const _CloudSyncStatusCard({
    required this.controller,
    required this.onConfigure,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colors = context.colors;
      final connected = controller.isConnected.value;
      final isSyncing = controller.isBusy.value;
      final lastSync = controller.lastSyncTime.value;
      final isGist = controller.selectedProvider.value == 'gist';
      // Read these inside Obx so the card updates correctly.
      final webdavUrl = controller.webdavUrl.value;
      final webdavUsername = controller.webdavUsername.value;

      String providerTitle = 'Not Connected';
      String providerSubtitle = 'Connect a provider to sync across devices';
      IconData providerIcon = Icons.cloud_off_rounded;

      if (connected) {
        if (isGist) {
          final ghUser = SyncKeys.gistGithubUsername.get<String>('');
          providerTitle = 'GitHub Gist';
          providerIcon = Icons.code_rounded;
          providerSubtitle = ghUser.isNotEmpty
              ? 'Connected as @$ghUser'
              : 'Connected with GitHub Gist';
        } else {
          final matched = kWebDavPresets.firstWhere(
            (p) => webdavUrl.toLowerCase().contains(p.id.toLowerCase()),
            orElse: () => kWebDavPresets.first,
          );
          providerTitle = matched.name;
          providerIcon = matched.icon;
          providerSubtitle = webdavUsername.isNotEmpty
              ? webdavUsername
              : matched.defaultUrl;
        }
      }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: connected
              ? colors.primary.opaque(0.35, iReallyMeanIt: true)
              : colors.onSurface.opaque(0.08, iReallyMeanIt: true),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: connected
                        ? colors.primary.opaque(0.12, iReallyMeanIt: true)
                        : colors.surfaceContainerHighest
                            .opaque(0.4, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    providerIcon,
                    size: 22,
                    color: connected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AnymeXText(
                              providerTitle,
                              variant: TextVariant.semiBold,
                              size: 15,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: connected
                                  ? colors.primary
                                      .opaque(0.12, iReallyMeanIt: true)
                                  : colors.error
                                      .opaque(0.12, iReallyMeanIt: true),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AnymeXText(
                              connected ? 'ACTIVE' : 'IDLE',
                              size: 10,
                              variant: TextVariant.bold,
                              color: connected ? colors.primary : colors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        providerSubtitle,
                        size: 12,
                        color: connected
                            ? colors.primary
                            : colors.onSurface
                                .opaque(0.45, iReallyMeanIt: true),
                        maxLines: 1,
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
                    'Last synced ${lastSync.day}/${lastSync.month}/${lastSync.year} at ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}',
                    size: 12,
                    color: colors.onSurface.opaque(0.45, iReallyMeanIt: true),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (connected) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSyncing ? null : () => controller.syncNow(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSyncing)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colors.onPrimary),
                          ),
                        )
                      else
                        Icon(Icons.sync_rounded,
                            color: colors.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      AnymeXText(
                        isSyncing ? 'Syncing...' : 'Sync Now',
                        variant: TextVariant.bold,
                        color: colors.onPrimary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AnymexOnTap(
                      onTap: onConfigure,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest
                              .opaque(0.4, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.outlineVariant
                                .opaque(0.5, iReallyMeanIt: true),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune_rounded,
                                size: 18, color: colors.onSurface),
                            const SizedBox(width: 8),
                            const AnymeXText('Configure',
                                variant: TextVariant.semiBold, size: 13),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnymexOnTap(
                      onTap: onDisconnect,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.error.opaque(0.08, iReallyMeanIt: true),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                colors.error.opaque(0.25, iReallyMeanIt: true),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 18, color: colors.error),
                            const SizedBox(width: 8),
                            AnymeXText('Disconnect',
                                variant: TextVariant.semiBold,
                                size: 13,
                                color: colors.error),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfigure,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_link_rounded,
                          color: colors.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      AnymeXText(
                        'Connect Cloud Provider',
                        variant: TextVariant.bold,
                        color: colors.onPrimary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    });
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

  List<DropdownItem> get _providerItems => [
        DropdownItem(
          value: 'gist',
          text: 'GitHub Gist',
          subtitle: 'Free · anymex_progress.json in your Gist',
          leadingIcon: Icon(
            Icons.code_rounded,
            size: 18,
            color: Get.theme.colorScheme.primary,
          ),
        ),
        ...kWebDavPresets.map(
          (p) => DropdownItem(
            value: p.id,
            text: p.name,
            subtitle: p.description,
            leadingIcon: Icon(
              p.icon,
              size: 18,
              color: Get.theme.colorScheme.primary,
            ),
          ),
        ),
      ];

  DropdownItem _providerItemFor(String id) {
    return _providerItems.firstWhere(
      (e) => e.value == id,
      orElse: () => _providerItems.first,
    );
  }

  void _showPresetInfo(BuildContext context, WebDavPreset preset) {
    final colors = Theme.of(context).colorScheme;
    AnymeXDialog(
      title: preset.name,
      confirmText: 'Visit Site',
      cancelText: 'Close',
      onConfirm: () {
        launchUrl(Uri.parse(preset.websiteUrl),
            mode: LaunchMode.externalApplication);
      },
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnymeXText(
            preset.description,
            size: 13,
            color: colors.onSurfaceVariant,
            maxLines: 10,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer.opaque(0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.outlineVariant.opaque(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        'SERVER ENDPOINT',
                        size: 10,
                        variant: TextVariant.bold,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        preset.defaultUrl,
                        size: 12.5,
                        color: colors.onSurface,
                        maxLines: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnymeXText(
                        'Configure Cloud Sync',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnymeXText(
                        'Choose a provider to sync your library',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final isGist =
                      selectedProviderId.value == 'gist';
                  final preset = isGist
                      ? null
                      : kWebDavPresets.firstWhere(
                          (e) => e.id == selectedProviderId.value,
                          orElse: () => kWebDavPresets.first,
                        );
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (preset != null)
                        IconButton(
                          tooltip: '${preset.name} info',
                          onPressed: () =>
                              _showPresetInfo(context, preset),
                          icon: const Icon(Icons.info_outline_rounded),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.opaque(0.2),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              children: [
                Obx(() => AnymeXDropdown(
                      label: 'CLOUD PROVIDER',
                      icon: Icons.cloud_outlined,
                      items: _providerItems,
                      selectedItem:
                          _providerItemFor(selectedProviderId.value),
                      onChanged: (item) =>
                          selectedProviderId.value = item.value,
                    )),
                const SizedBox(height: 12),
                Obx(() {
                  if (selectedProviderId.value == 'gist') {
                    return _buildGistConfig(context);
                  }
                  final preset = kWebDavPresets.firstWhere(
                    (p) => p.id == selectedProviderId.value,
                    orElse: () => kWebDavPresets.first,
                  );
                  return _buildWebDavConfig(context, preset);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGistConfig(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final isLogged = gistCtrl.isLoggedIn.value;
      final ghUser = gistCtrl.githubUsername.value ??
          SyncKeys.gistGithubUsername.get<String>('');
      final avatar = gistCtrl.githubAvatarUrl.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.opaque(0.4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant.opaque(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (avatar != null && avatar.isNotEmpty)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.opaque(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: AnymeXImage(
                              imageUrl: avatar,
                              width: 44,
                              height: 44,
                              radius: 22,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.opaque(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.code_rounded,
                              size: 22, color: theme.colorScheme.primary),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymeXText(
                              isLogged && ghUser.isNotEmpty
                                  ? '@$ghUser'
                                  : 'GitHub Gist Storage',
                              variant: TextVariant.semiBold,
                              size: 15,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            AnymeXText(
                              'anymex_progress.json in your Gist',
                              size: 12,
                              color: isLogged
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      if (isLogged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.primary.opaque(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AnymeXText(
                            'LINKED',
                            size: 10,
                            variant: TextVariant.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnymeXText(
                    'Syncs your library, watched episodes, read chapters, source mappings, and preferences directly to your personal GitHub Gist.',
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    maxLines: 10,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isLogged) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.controller.isBusy.value
                    ? null
                    : () async {
                        final ok = await widget.controller.connectGist();
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: widget.controller.isBusy.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary),
                        ),
                      )
                    : AnymeXText(
                        'Use This GitHub Account',
                        variant: TextVariant.bold,
                        color: theme.colorScheme.onPrimary,
                        size: 15,
                      ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: gistCtrl.isAuthenticating.value
                    ? null
                    : () async {
                        await gistCtrl.login(context);
                        if (gistCtrl.isLoggedIn.value) {
                          await widget.controller.connectGist();
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: gistCtrl.isAuthenticating.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded,
                              size: 20, color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          AnymeXText(
                            'Sign In with GitHub',
                            variant: TextVariant.bold,
                            color: theme.colorScheme.onPrimary,
                            size: 15,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: theme.colorScheme.outlineVariant.opaque(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: AnymeXText('or Personal Token',
                      size: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
                Expanded(
                    child: Divider(
                        color: theme.colorScheme.outlineVariant.opaque(0.3))),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              context,
              controller: tokenController,
              hint: 'ghp_xxxxxxxxxxxxxxxxxxxx',
              icon: Icons.key_rounded,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                        'https://github.com/settings/tokens/new?scopes=gist&description=AnymeX%20Sync'),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: AnymeXText(
                  'Generate Token on GitHub',
                  size: 12,
                  variant: TextVariant.semiBold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.controller.isBusy.value
                    ? null
                    : () async {
                        final token = tokenController.text.trim();
                        if (token.isEmpty) return;
                        final ok = await widget.controller
                            .connectGist(token: token);
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .opaque(0.5, iReallyMeanIt: true),
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.opaque(0.5),
                    ),
                  ),
                  elevation: 0,
                ),
                child: widget.controller.isBusy.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AnymeXText(
                        'Connect with Token',
                        variant: TextVariant.bold,
                        size: 15,
                      ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildWebDavConfig(BuildContext context, WebDavPreset preset) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnymeXExpansionTile(
          title: 'Setup Guide · ${preset.name}',
          subtitle: '${preset.setupGuide.length} quick steps',
          icon: Icons.info_outline_rounded,
          initialExpanded: true,
          content: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Column(
              children: preset.setupGuide.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.opaque(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: AnymeXText(
                          '${e.key + 1}',
                          size: 11,
                          variant: TextVariant.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnymeXText(
                          e.value,
                          size: 12.5,
                          color: theme.colorScheme.onSurfaceVariant,
                          maxLines: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildField(
          context,
          controller: userController,
          hint: preset.usernameHint,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 10),
        Obx(() => _buildField(
              context,
              controller: passController,
              hint: 'App password',
              icon: Icons.lock_outline_rounded,
              obscureText: !isPasswordVisible.value,
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => isPasswordVisible.toggle(),
              ),
            )),
        const SizedBox(height: 14),
        Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.controller.isBusy.value
                    ? null
                    : () async {
                        final user = userController.text.trim();
                        final pass = passController.text.trim();
                        if (user.isEmpty || pass.isEmpty) return;
                        final ok =
                            await widget.controller.saveWebDavConfig(
                          url: preset.defaultUrl,
                          username: user,
                          password: pass,
                        );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: widget.controller.isBusy.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary),
                        ),
                      )
                    : AnymeXText(
                        'Save & Connect',
                        variant: TextVariant.bold,
                        color: theme.colorScheme.onPrimary,
                        size: 15,
                      ),
              ),
            )),
      ],
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface.opaque(0.3, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.opaque(0.2, iReallyMeanIt: true),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.opaque(0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffixIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: suffixIcon,
            )
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }
}
