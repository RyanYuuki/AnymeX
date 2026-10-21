import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/anime/widgets/comments/widgets/leaderboard_sheet.dart';
import 'package:anymex/screens/profile/widgets/decoration_closet_sheet.dart';
import 'package:anymex/screens/settings/sub_settings/settings_anilist_api.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsAccounts extends StatefulWidget {
  const SettingsAccounts({super.key});

  @override
  State<SettingsAccounts> createState() => _SettingsAccountsState();
}

class _SettingsAccountsState extends State<SettingsAccounts> {
  @override
  void initState() {
    super.initState();
    _autoSyncLinkedAccounts();
  }

  Future<void> _autoSyncLinkedAccounts() async {
    if (!Get.isRegistered<CommentumService>()) return;
    final commentum = Get.find<CommentumService>();
    if (commentum.currentUserId == null) return;

    final malToken = AuthKeys.malAuthToken.get<String?>();
    final simklToken = AuthKeys.simklAuthToken.get<String?>();
    final anilistToken = AuthKeys.authToken.get<String?>();

    final primary =
        Get.find<ServiceHandler>().serviceType.value.name.toLowerCase();

    if (primary != 'mal' && malToken != null && malToken.isNotEmpty) {
      try {
        await commentum.linkAccount(
          targetClientType: 'mal',
          targetAccessToken: malToken,
        );
      } catch (_) {}
    }

    if (primary != 'simkl' && simklToken != null && simklToken.isNotEmpty) {
      try {
        await commentum.linkAccount(
          targetClientType: 'simkl',
          targetAccessToken: simklToken,
        );
      } catch (_) {}
    }

    if (primary != 'anilist' &&
        anilistToken != null &&
        anilistToken.isNotEmpty) {
      try {
        await commentum.linkAccount(
          targetClientType: 'anilist',
          targetAccessToken: anilistToken,
        );
      } catch (_) {}
    }
  }

  void _showLogoutDialog(
    BuildContext context,
    OnlineService service,
    String title,
  ) {
    AnymeXDialog(
      title: 'Log Out',
      message: 'Are you sure you want to log out from $title?',
      confirmText: 'Log Out',
      cancelText: 'Cancel',
      onConfirm: () => service.logout(),
    ).show(context);
  }

  Widget _buildServiceIcon(
    BuildContext context,
    String? avatarUrl,
    bool isLogged,
    String serviceIcon,
  ) {
    final colors = context.colors;
    if (isLogged && avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          cacheManager: AnymeXCacheManager.instance,
          fit: BoxFit.cover,
          errorWidget: (c, o, s) => Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/$serviceIcon',
              fit: BoxFit.contain,
              color: Colors.white,
              errorBuilder: (c, o, s) => const Icon(Icons.person),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(
        'assets/images/$serviceIcon',
        fit: BoxFit.contain,
        color: colors.primary,
        errorBuilder: (c, o, s) => const Icon(Icons.account_circle_outlined),
      ),
    );
  }

  Widget _buildTrackingServiceTile(
    BuildContext context, {
    required String serviceIcon,
    required OnlineService service,
    required String title,
  }) {
    final colors = context.colors;

    return Obx(() {
      final bool isLogged = service.isLoggedIn.value;
      final String username =
          isLogged ? (service.profileData.value.name ?? "User") : "";
      final String? avatar = isLogged ? service.profileData.value.avatar : null;

      return AnymeXTile(
        leading: _buildServiceIcon(context, avatar, isLogged, serviceIcon),
        title: title,
        subtitle: isLogged ? 'Connected as $username' : 'Not connected',
        subtitleStyle: isLogged
            ? TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w500,
              )
            : null,
        showChevron: !isLogged,
        onTap: isLogged
            ? (title.toLowerCase() == 'anilist'
                ? () => navigate(() => const SettingsAnilistApi())
                : null)
            : () async {
                await service.login(context);
                _autoSyncLinkedAccounts();
              },
        trailing: isLogged
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.toLowerCase() == 'anilist')
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      tooltip: 'Anilist Settings',
                      onPressed: () =>
                          navigate(() => const SettingsAnilistApi()),
                    ),
                  IconButton(
                    icon: Icon(Icons.logout_rounded,
                        size: 20, color: colors.error),
                    tooltip: 'Log Out',
                    onPressed: () => _showLogoutDialog(context, service, title),
                  ),
                ],
              )
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.primary.opaque(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnymeXText(
                  'Connect',
                  variant: TextVariant.bold,
                  size: 12,
                  color: colors.primary,
                ),
              ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();

    final services = [
      {
        'serviceIcon': 'anilist-icon.png',
        'service': serviceHandler.anilistService,
        'title': 'Anilist',
      },
      {
        'serviceIcon': 'mal-icon.png',
        'service': serviceHandler.malService,
        'title': 'MyAnimeList',
      },
      {
        'serviceIcon': 'simkl-icon.png',
        'service': serviceHandler.simklService,
        'title': 'Simkl',
      },
    ];

    services.sort((a, b) =>
        (b['service'] == serviceHandler.onlineService ? 1 : 0)
            .compareTo(a['service'] == serviceHandler.onlineService ? 1 : 0));

    return AnymeXScaffold(
      showHeader: true,
      headerTitle: 'Accounts',
      body: Builder(
        builder: (ctx) => ScrollWrapper(
          comfortPadding: false,
          customPadding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 30.0),
          children: [
            SizedBox(height: AnymeXHeaderScope.of(ctx)),
            AnymeXSectionBuilder(
              title: 'Closet & Community',
              children: [
                AnymeXTile(
                  icon: Icons.checkroom_rounded,
                  title: 'Open Closet',
                  subtitle:
                      'Avatar decorations, nameplates, banners & profile effects',
                  onTap: () => DecorationClosetSheet.show(context),
                ),
                AnymeXTile(
                  icon: Icons.emoji_events_rounded,
                  title: 'Leaderboard',
                  subtitle: 'View user rankings, top contributors & reputation',
                  onTap: () => LeaderboardSheet.show(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnymeXSectionBuilder(
              title: 'Tracking Services',
              children: services
                  .map((s) => _buildTrackingServiceTile(
                        context,
                        serviceIcon: s['serviceIcon'] as String,
                        service: s['service'] as OnlineService,
                        title: s['title'] as String,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
