import 'dart:io';

import 'package:anymex/controllers/discord/discord_login.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class SettingsAccounts extends StatelessWidget {
  const SettingsAccounts({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final services = [
      {
        'service': serviceHandler.anilistService,
        'icon': 'assets/icons/anilist-icon.png',
        'title': "Anilist",
        'color': const Color(0xFF02A9FF),
      },
      {
        'service': serviceHandler.malService,
        'icon': 'assets/icons/mal-icon.png',
        'title': "MyAnimeList",
        'color': const Color(0xFF2E51A2),
      },
      {
        'service': serviceHandler.simklService,
        'icon': 'assets/icons/simkl-icon.png',
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
                  if (!Platform.isWindows &&
                      !Platform.isLinux &&
                      !Platform.isMacOS) ...[
                    _buildSectionHeader(context, "Social Presence"),
                    const SizedBox(height: 12),
                    const DiscordTile(),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionHeader(context, "Tracking Services"),
                  const SizedBox(height: 12),
                  ...services.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TrackingServiceCard(
                          serviceIcon: s['icon'] as String,
                          service: s['service'] as OnlineService,
                          title: s['title'] as String,
                          brandColor: s['color'] as Color?,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              if (isLoggedIn) {
                _showLogoutDialog(context, rpc);
              } else {
                context.showDiscordLogin((token) => rpc.onLoginSuccess(token));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildAvatar(userData?.avatarUrl, isLoggedIn, colors),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnymexText(
                          text: isLoggedIn
                              ? (userData?.displayName ?? 'Discord User')
                              : 'Connect Discord',
                          variant: TextVariant.bold,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        AnymexText(
                          text: isLoggedIn
                              ? 'Rich Presence Active'
                              : 'Show what you are watching',
                          color: isLoggedIn
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          size: 12,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLoggedIn
                          ? colors.primary
                          : colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLoggedIn ? IconlyBold.login : IconlyBold.add_user,
                      color: isLoggedIn
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                      size: 20,
                    ),
                  )
                ],
              ),
            ),
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
          backgroundImage: CachedNetworkImageProvider(url),
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
  final Color? brandColor;

  const TrackingServiceCard({
    super.key,
    required this.serviceIcon,
    required this.service,
    required this.title,
    this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Obx(() {
      final bool isLogged = service.isLoggedIn.value;

      final String username =
          isLogged ? (service.profileData.value.name ?? "User") : "";
      final String? avatar = isLogged ? service.profileData.value.avatar : null;

      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLogged
                ? (brandColor ?? colors.primary).withOpacity(0.5)
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLogged
                          ? colors.surfaceContainerHigh
                          : (brandColor ?? colors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnymexText(
                      text: isLogged ? "Manage" : "Connect",
                      variant: TextVariant.bold,
                      size: 12,
                      color: isLogged
                          ? colors.onSurface
                          : (brandColor ?? colors.primary),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildServiceIcon(String? avatarUrl, bool isLogged) {
    if (isLogged && avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
                image: CachedNetworkImageProvider(avatarUrl),
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
