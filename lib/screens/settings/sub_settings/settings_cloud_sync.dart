import 'package:anymex/controllers/sync/cloud/cloud_sync_controller.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_button.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
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
    id: 'infinicloud',
    name: 'InfiniCLOUD',
    description: 'High capacity cloud storage',
    defaultUrl: 'https://<your-id>.infini-cloud.net/dav/',
    websiteUrl: 'https://infini-cloud.net',
    usernameHint: 'Connection ID from My Page',
    setupGuide: [
      'Create an account at infini-cloud.net',
      'Go to "My Page" and enable "Apps Connection"',
      'Copy your Connection URL and Connection ID',
      'Generate an App Password and enter below',
    ],
    icon: Icons.cloud_outlined,
  ),
  WebDavPreset(
    id: 'koofr',
    name: 'Koofr',
    description: 'Reliable general cloud storage',
    defaultUrl: 'https://app.koofr.net/dav/Koofr/',
    websiteUrl: 'https://koofr.eu',
    usernameHint: 'Koofr account email',
    setupGuide: [
      'Create an account at koofr.eu',
      'Go to Settings ➔ Preferences ➔ Password',
      'Generate an App Password (name it "AnymeX")',
      'Enter your email and the generated password',
    ],
    icon: Icons.dns_outlined,
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
    description: 'Secure cloud storage',
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
  WebDavPreset(
    id: 'custom',
    name: 'Custom WebDAV',
    description: 'Nextcloud, ownCloud, or NAS',
    defaultUrl: '',
    websiteUrl: '',
    usernameHint: 'Username or email',
    setupGuide: [
      'Enter the full WebDAV URL provided by your server',
      'Nextcloud format: https://domain/remote.php/dav/files/USER/',
      'Enter your server login credentials',
    ],
    icon: Icons.settings_ethernet_rounded,
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

  void _openSetupSheet(BuildContext context, [WebDavPreset? preset]) {
    AnymeXSheet.custom(
      _WebDavConfigSheet(
        controller: controller,
        initialPreset: preset ?? kWebDavPresets[1],
      ),
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
                            connected
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_off_rounded,
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
                                    connected ? 'WebDAV Synced' : 'Not Connected',
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
                                connected
                                    ? (controller.statusMessage.value.isNotEmpty
                                        ? controller.statusMessage.value
                                        : controller.webdavUrl.value)
                                    : 'Connect a cloud provider to sync across devices',
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
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
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
                          IconButton.filledTonal(
                            tooltip: 'Configure Account',
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            onPressed: () => _openSetupSheet(context),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Disconnect',
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            onPressed: () => controller.disconnect(),
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

            // Provider List
            AnymeXSectionBuilder(
              title: 'Providers',
              children: kWebDavPresets.map((preset) {
                final isCurrent = controller.webdavUrl.value.isNotEmpty &&
                    controller.webdavUrl.value.contains(preset.id);

                return _ProviderCard(
                  preset: preset,
                  isCurrent: isCurrent,
                  onTap: () => _openSetupSheet(context, preset),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

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

class _ProviderCard extends StatelessWidget {
  final WebDavPreset preset;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.preset,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AnymeXContainer(
        radius: 16,
        color: colors.surfaceContainerLow.withOpacity(0.4),
        border: Border.all(
          color: isCurrent
              ? colors.primary.withOpacity(0.4)
              : colors.outline.withOpacity(0.06),
          width: 1,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  AnymeXContainer(
                    padding: const EdgeInsets.all(10),
                    radius: 12,
                    color: colors.primary.withOpacity(0.08),
                    child: Icon(preset.icon, color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymeXText(
                          preset.name,
                          variant: TextVariant.semiBold,
                          size: 15,
                        ),
                        const SizedBox(height: 2),
                        AnymeXText(
                          preset.description,
                          size: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                  AnymeXContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    radius: 8,
                    color: isCurrent
                        ? colors.primary.withOpacity(0.15)
                        : colors.surfaceContainerHighest.withOpacity(0.4),
                    child: AnymeXText(
                      isCurrent ? 'Active' : 'Configure',
                      variant: TextVariant.bold,
                      size: 12,
                      color: isCurrent ? colors.primary : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebDavConfigSheet extends StatefulWidget {
  final CloudSyncController controller;
  final WebDavPreset initialPreset;

  const _WebDavConfigSheet({
    required this.controller,
    required this.initialPreset,
  });

  @override
  State<_WebDavConfigSheet> createState() => _WebDavConfigSheetState();
}

class _WebDavConfigSheetState extends State<_WebDavConfigSheet> {
  late final Rx<WebDavPreset> selectedPreset;
  late final TextEditingController urlController;
  late final TextEditingController userController;
  late final TextEditingController passController;
  final isPasswordVisible = false.obs;

  @override
  void initState() {
    super.initState();
    selectedPreset = widget.initialPreset.obs;
    urlController = TextEditingController(
      text: widget.controller.webdavUrl.value.isNotEmpty
          ? widget.controller.webdavUrl.value
          : widget.initialPreset.defaultUrl,
    );
    userController =
        TextEditingController(text: widget.controller.webdavUsername.value);
    passController =
        TextEditingController(text: widget.controller.webdavPassword.value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnymeXText(
                'Configure WebDAV',
                variant: TextVariant.bold,
                size: 18,
              ),
              const Spacer(),
              Obx(() {
                final website = selectedPreset.value.websiteUrl;
                if (website.isEmpty) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse(website),
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const AnymeXText('Visit Site', size: 12),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),

          // Provider selector chips
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kWebDavPresets.map((p) {
                    final isSel = selectedPreset.value.id == p.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(p.name),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) {
                            selectedPreset.value = p;
                            if (p.defaultUrl.isNotEmpty) {
                              urlController.text = p.defaultUrl;
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              )),

          const SizedBox(height: 12),

          // Setup Guide Box
          Obx(() {
            final p = selectedPreset.value;
            return AnymeXContainer(
              padding: const EdgeInsets.all(12),
              radius: 12,
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnymeXText(
                    'Setup Guide for ${p.name}',
                    variant: TextVariant.bold,
                    size: 12,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 6),
                  ...p.setupGuide.asMap().entries.map((e) {
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
            );
          }),

          const SizedBox(height: 14),

          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: 'Server WebDAV URL',
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Obx(() => TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: 'Username or Email',
                  hintText: selectedPreset.value.usernameHint,
                  prefixIcon:
                      const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )),
          const SizedBox(height: 10),
          Obx(() => TextField(
                controller: passController,
                obscureText: !isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Password or App Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => isPasswordVisible.toggle(),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )),

          const SizedBox(height: 18),

          Obx(() => AnymeXButton(
                height: 44,
                borderRadius: BorderRadius.circular(12),
                onTap: widget.controller.isBusy.value
                    ? () {}
                    : () async {
                        final url = urlController.text.trim();
                        final user = userController.text.trim();
                        final pass = passController.text.trim();

                        if (url.isEmpty || user.isEmpty || pass.isEmpty) {
                          return;
                        }

                        final ok = await widget.controller.saveWebDavConfig(
                          url: url,
                          username: user,
                          password: pass,
                        );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: widget.controller.isBusy.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const AnymeXText(
                        'Save & Connect',
                        variant: TextVariant.bold,
                      ),
              )),
        ],
      ),
    );
  }
}
