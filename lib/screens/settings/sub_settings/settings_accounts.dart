import 'package:anymex/controllers/discord/discord_login.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/storage/anymex_cache_manager.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/settings/sub_settings/settings_anilist_api.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/custom_tiles.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
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
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final services = [
      {
        'service': serviceHandler.anilistService,
        'icon': 'assets/images/anilist-icon.png',
        'title': "Anilist",
        'color': const Color(0xFF02A9FF),
      },
      {
        'service': serviceHandler.malService,
        'icon': 'assets/images/mal-icon.png',
        'title': "MyAnimeList",
        'color': const Color(0xFF2E51A2),
      },
      {
        'service': serviceHandler.simklService,
        'icon': 'assets/images/simkl-icon.png',
        'title': "Simkl",
        'color': const Color(0xFF000000),
      },
    ];

    services.sort((a, b) =>
        (b['service'] == serviceHandler.onlineService ? 1 : 0)
            .compareTo(a['service'] == serviceHandler.onlineService ? 1 : 0));

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            const NestedHeader(title: 'Accounts'),
            Expanded(
              child: ScrollWrapper(
                comfortPadding: false,
                customPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                children: [
                  _buildSectionHeader(context, "Social Presence"),
                  const SizedBox(height: 12),
                  const DiscordTile(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, "Tracking Services"),
                  const SizedBox(height: 12),
                  ...services.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TrackingServiceCard(
                          serviceIcon: s['icon'] as String,
                          service: s['service'] as OnlineService,
                          title: s['title'] as String,
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: AnymexText(
        text: title.toUpperCase(),
        variant: TextVariant.bold,
        color: context.colors.onSurfaceVariant.withOpacity(0.7),
        size: 12,
      ),
    );
  }
}

class DiscordTile extends StatelessWidget {
  const DiscordTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final rpc = DiscordRPCController.instance;
      final isDesktop = !rpc.isMobile;
      final isLoggedIn = rpc.isLoggedIn;
      final userData = isLoggedIn ? rpc.profile.value : null;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLoggedIn
                ? [
                    colors.primary.withOpacity(0.15),
                    colors.surfaceContainer.opaque(0.4),
                  ]
                : [
                    colors.surfaceContainer.opaque(0.4),
                    colors.surfaceContainerHighest.opaque(0.4),
                  ],
          ),
          border: Border.all(
            color: isLoggedIn
                ? colors.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildAvatar(isDesktop ? null : userData?.avatarUrl,
                      isLoggedIn, colors),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: isDesktop
                              ? 'Discord Desktop'
                              : (isLoggedIn
                                  ? (userData?.displayName ?? 'Discord User')
                                  : 'Connect Discord'),
                          variant: TextVariant.bold,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isLoggedIn && rpc.isEnabled
                                    ? const Color(0xFF43B581)
                                    : colors.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnymexText(
                              text: isDesktop
                                  ? (rpc.isConnected
                                      ? 'Connected'
                                      : 'Disconnected')
                                  : (isLoggedIn
                                      ? (rpc.isEnabled
                                          ? 'Rich Presence Active'
                                          : 'Rich Presence Disabled')
                                      : 'Not Connected'),
                              color: isLoggedIn && rpc.isEnabled
                                  ? const Color(0xFF43B581)
                                  : colors.onSurfaceVariant,
                              size: 12,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isDesktop && isLoggedIn)
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context, rpc),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          IconlyBold.logout,
                          color: colors.error,
                          size: 18,
                        ),
                      ),
                    ),
                  if (!isDesktop && !isLoggedIn)
                    GestureDetector(
                      onTap: () => context.showDiscordLogin(
                          (token) => rpc.onLoginSuccess(token)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5865F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AnymexText(
                          text: 'Login',
                          variant: TextVariant.bold,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              if (isDesktop || isLoggedIn) ...[
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: colors.outline.withOpacity(0.12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AnymexText(
                            text: 'Discord Rich Presence',
                            variant: TextVariant.semiBold,
                            size: 14,
                          ),
                          const SizedBox(height: 2),
                          AnymexText(
                            text: 'Share your activity on Discord',
                            size: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: Switch(
                        value: rpc.isEnabled,
                        onChanged: (e) => rpc.setEnabled(e),
                        activeColor: colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvatar(String? url, bool isLoggedIn, dynamic colors) {
    if (isLoggedIn && url != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: colors.surfaceContainerHighest,
          backgroundImage: CachedNetworkImageProvider(
            url,
            cacheManager: AnymeXCacheManager.instance,
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF5865F2).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(IconlyBold.game, color: Color(0xFF5865F2), size: 28),
    );
  }

  void _showLogoutDialog(BuildContext context, DiscordRPCController rpc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surfaceContainer,
        title: const AnymexText(
            text: "Disconnect Discord?", variant: TextVariant.bold),
        content: const AnymexText(
            text: "Your rich presence activity will stop updating."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              rpc.logout();
              Navigator.pop(context);
            },
            child: Text("Disconnect",
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}

class TrackingServiceCard extends StatelessWidget {
  final String serviceIcon;
  final OnlineService service;
  final String title;

  const TrackingServiceCard({
    super.key,
    required this.serviceIcon,
    required this.service,
    required this.title,
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

        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLogged
                  ? (colors.primary).withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isLogged) {
                  _showServiceOptions(context);
                } else {
                  service.login(context);
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
                          AnymexText(
                            text: title,
                            variant: TextVariant.semiBold,
                            size: 16,
                          ),
                          const SizedBox(height: 2),
                          AnymexText(
                            text: isLogged
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isLogged
                            ? colors.surfaceContainerHigh
                            : (colors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnymexText(
                        text: isLogged ? "Manage" : "Connect",
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
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: CachedNetworkImageProvider(
                  avatarUrl,
                  cacheManager: AnymeXCacheManager.instance,
                ),
                fit: BoxFit.cover)),
      );
    }

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
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
            AnymexText(
                text: "Manage $title", variant: TextVariant.bold, size: 18),
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
                  title: const Text('Anilist Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const SettingsAnilistApi());
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: context.colors.surfaceContainer,
                ),
              ),
            ListTile(
              leading: const Icon(IconlyLight.logout),
              title: const Text("Log Out"),
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
