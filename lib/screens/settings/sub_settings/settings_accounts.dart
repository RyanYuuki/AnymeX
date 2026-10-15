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
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_decorated_avatar.dart';
import 'package:anymex/widgets/common/anymex_scaffold.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

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

  Widget _buildProfileCustomizationCard(BuildContext context) {
    final colors = context.colors;
    final commentum = Get.isRegistered<CommentumService>()
        ? Get.find<CommentumService>()
        : null;

    return AnymeXContainer(
      color: colors.surfaceContainerLow.withOpacity(0.4),
      radius: 20,
      border: Border.all(
        color: colors.primary.withOpacity(0.25),
        width: 1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (commentum != null)
                    Obx(() => AnymeXDecoratedAvatar(
                          avatarUrl: commentum.currentUserAvatar,
                          decorationUrl: commentum.currentUserDecoration.value,
                          size: 52,
                          decorationScale: 1.25,
                        ))
                  else
                    const CircleAvatar(
                      radius: 26,
                      child: Icon(Icons.person),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AnymeXText(
                          'Profile Customization',
                          variant: TextVariant.semiBold,
                          size: 16,
                        ),
                        const SizedBox(height: 3),
                        AnymeXText(
                          'Equip decorations, custom banners & manage linked accounts',
                          size: 12,
                          color: colors.onSurfaceVariant,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: colors.outlineVariant.withOpacity(0.2),
            ),
            Row(
              children: [
                if (commentum != null) ...[
                  Expanded(
                    child: InkWell(
                      onTap: () => DecorationClosetSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checkroom_rounded,
                                size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            AnymeXText(
                              'Open Closet',
                              variant: TextVariant.bold,
                              size: 13,
                              color: colors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnymeXContainer(
                    width: 1,
                    height: 24,
                    color: colors.outlineVariant.withOpacity(0.2),
                  ),
                ],
                Expanded(
                  child: InkWell(
                    onTap: () => LeaderboardSheet.show(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              size: 18, color: Color(0xFFFFD700)),
                          const SizedBox(width: 8),
                          AnymeXText(
                            'Leaderboard',
                            variant: TextVariant.bold,
                            size: 13,
                            color: colors.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final services = [
      {
        'serviceIcon': 'anilist.png',
        'service': serviceHandler.anilistService,
        'title': 'Anilist',
      },
      {
        'serviceIcon': 'mal.png',
        'service': serviceHandler.malService,
        'title': 'MyAnimeList',
      },
      {
        'serviceIcon': 'simkl.png',
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
              title: 'Profile & Closet',
              children: [
                _buildProfileCustomizationCard(context),
              ],
            ),
            const SizedBox(height: 16),
            AnymeXSectionBuilder(
              title: 'Tracking Services',
              children: services
                  .map((s) => TrackingServiceCard(
                        serviceIcon: s['serviceIcon'] as String,
                        service: s['service'] as OnlineService,
                        title: s['title'] as String,
                        onLoginSuccess: _autoSyncLinkedAccounts,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingServiceCard extends StatelessWidget {
  final String serviceIcon;
  final OnlineService service;
  final String title;
  final VoidCallback? onLoginSuccess;

  const TrackingServiceCard({
    super.key,
    required this.serviceIcon,
    required this.service,
    required this.title,
    this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return HighlightDecorator(
      title: title,
      child: Obx(() {
        final bool isLogged = service.isLoggedIn.value;

        final String username =
            isLogged ? (service.profileData.value.name ?? "User") : "";
        final String? avatar =
            isLogged ? service.profileData.value.avatar : null;

        return AnymeXContainer(
          color: colors.surfaceContainerLow.withOpacity(0.4),
          radius: 20,
          border: Border.all(
            color: isLogged
                ? (colors.primary).withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (isLogged) {
                  _showServiceOptions(context);
                } else {
                  await service.login(context);
                  onLoginSuccess?.call();
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    _buildServiceIcon(avatar, isLogged),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnymeXText(
                            title,
                            variant: TextVariant.semiBold,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          AnymeXText(
                            isLogged
                                ? 'Connected as $username'
                                : 'Not connected',
                            size: 12,
                            color: isLogged
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    AnymeXContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      color: isLogged
                          ? colors.surfaceContainerHigh
                          : (colors.primary).withOpacity(0.1),
                      radius: 12,
                      child: AnymeXText(
                        isLogged ? "Manage" : "Connect",
                        variant: TextVariant.bold,
                        size: 12,
                        color: isLogged ? colors.onSurface : (colors.primary),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildServiceIcon(String? avatarUrl, bool isLogged) {
    if (isLogged && avatarUrl != null && avatarUrl.isNotEmpty) {
      return AnymeXContainer(
        width: 44,
        height: 44,
        radius: 22,
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          cacheManager: AnymeXCacheManager.instance,
          fit: BoxFit.cover,
        ),
      );
    }

    return AnymeXContainer(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.1),
      radius: 12,
      child: Image.asset(
        'assets/icons/$serviceIcon',
        errorBuilder: (c, o, s) => const Icon(IconlyBold.danger),
      ),
    );
  }

  void _showServiceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnymeXText("Manage $title", variant: TextVariant.bold, size: 18),
            const SizedBox(height: 20),
            if (title.toLowerCase() == 'anilist')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/anilist-icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const AnymeXText('Anilist Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    navigate(() => const SettingsAnilistApi());
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: context.colors.surfaceContainer,
                ),
              ),
            ListTile(
              leading: const Icon(IconlyLight.logout),
              title: const AnymeXText("Log Out"),
              onTap: () {
                service.logout();
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: context.colors.surfaceContainer,
            )
          ],
        ),
      ),
    );
  }
}
