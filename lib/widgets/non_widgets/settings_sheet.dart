import 'package:anymex/l10n/l10n_extension.dart';
import 'dart:io';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/downloads/download_screen.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/local_source/local_source_view.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/notifications/notification_screen.dart';
import 'package:anymex/screens/notifications/notification_controller.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_section_builder.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_tile.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:anymex/screens/watchium/watchium_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:iconsax/iconsax.dart';

class SettingsSheet extends StatelessWidget {
  SettingsSheet({super.key});

  final serviceHandler = Get.find<ServiceHandler>();

  static void show(BuildContext context) {
    AnymeXSheet(
      showDragHandle: true,
      customWidget: SettingsSheet(),
    ).show(context);
  }

  void showServiceSelector(BuildContext context) {
    final colors = context.colors;

    final services = [
      {
        'type': ServicesType.anilist,
        'name': "AniList",
        'icon': 'anilist-icon.png',
        'desc': 'Track anime & manga'
      },
      {
        'type': ServicesType.mal,
        'name': "MyAnimeList",
        'icon': 'mal-icon.png',
        'desc': 'The largest database of anime & manga'
      },
      {
        'type': ServicesType.simkl,
        'name': "Simkl",
        'icon': 'simkl-icon.png',
        'desc': 'Track movies, series & anime'
      },
      {
        'type': ServicesType.extensions,
        'name': "Extensions",
        'icon': null,
        'desc': 'Third-party community plugins'
      },
    ];

    AnymeXSheet(
      showDragHandle: true,
      headerIcon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            HugeIcons.strokeRoundedAiSetting,
            size: 20,
            color: colors.primary,
          ),
        ),
      ),
      heroTitle: "Content Source",
      heroSubtitle: "Select your preferred tracking and media provider",
      customWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: services.asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;
          final isSelected =
              serviceHandler.serviceType.value == service['type'];

          final isFirst = index == 0;
          final isLast = index == services.length - 1;
          final double topRadius = isFirst ? 16 : 4;
          final double bottomRadius = isLast ? 16 : 4;
          final radius = BorderRadius.vertical(
            top: Radius.circular(topRadius),
            bottom: Radius.circular(bottomRadius),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: AnymeXTile(
              style: TileStyle.modern,
              borderRadius: radius,
              backgroundColor: isSelected
                  ? colors.surfaceContainerHighest.opaque(0.65, iReallyMeanIt: true)
                  : colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
              leading: service['icon'] != null
                  ? Image.asset(
                      'assets/images/${service['icon']}',
                      width: 22,
                      height: 22,
                      color: Colors.white,
                    )
                  : const Icon(
                      Icons.extension_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
              title: service['name'] as String,
              subtitle: service['desc'] as String,
              showChevron: !isSelected,
              trailing: isSelected
                  ? Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: colors.onPrimary,
                      ),
                    )
                  : null,
              onTap: () {
                serviceHandler.changeService(
                  service['type'] as ServicesType,
                );
                Get.back();
              },
            ),
          );
        }).toList(),
      ),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(context),
        const SizedBox(height: 14),
        _buildQuickStatusCard(context),
        const SizedBox(height: 14),
        _buildTileGroup(context),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final colors = context.colors;
    final isLoggedIn = serviceHandler.isLoggedIn.value;
    final userName = serviceHandler.profileData.value.name ?? 'Guest';
    final avatar = serviceHandler.profileData.value.avatar;

    return Row(
      children: [
        GestureDetector(
          onTap: isLoggedIn &&
                  serviceHandler.serviceType.value == ServicesType.anilist
              ? () {
                  Get.back();
                  navigate(() => const ProfilePage());
                }
              : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
            ),
            child: Center(
              child: isLoggedIn && avatar != null && avatar.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: AnymeXImage(
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                        radius: 0,
                        imageUrl: avatar,
                      ),
                    )
                  : Icon(
                      Icons.person_outline_rounded,
                      color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
                      size: 24,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnymeXText(
                userName,
                size: 19,
                variant: TextVariant.bold,
                color: colors.onSurface,
              ),
              const SizedBox(height: 4),
              if (serviceHandler.serviceType.value != ServicesType.extensions)
                AnymexOnTap(
                  onTap: () async {
                    if (isLoggedIn) {
                      serviceHandler.logout();
                    } else {
                      await serviceHandler.login(context);
                    }
                    Get.back();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
                        size: 13,
                        color: isLoggedIn ? colors.error : colors.primary,
                      ),
                      const SizedBox(width: 5),
                      AnymeXText(
                        isLoggedIn ? 'Logout' : 'Login',
                        size: 12,
                        variant: TextVariant.semiBold,
                        color: isLoggedIn ? colors.error : colors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AnymexOnTap(
          onTap: () {
            Navigator.pop(context);
            if (!Get.isRegistered<NotificationController>()) {
              Get.put(NotificationController());
            } else {
              final controller = Get.find<NotificationController>();
              if (controller.anilistNotifications.isEmpty) {
                controller.loadAnilistNotifications();
              }
            }
            Get.to(() => const NotificationScreen());
          },
          child: Obx(() {
            int unread = 0;
            if (Get.isRegistered<AnilistAuth>()) {
              unread += Get.find<AnilistAuth>().unreadAnilistCount.value;
            }
            if (Get.isRegistered<CommentumService>()) {
              unread +=
                  Get.find<CommentumService>().unreadNotificationCount.value;
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer.opaque(0.45, iReallyMeanIt: true),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Iconsax.notification,
                      size: 17,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickStatusCard(BuildContext context) {
    final colors = context.colors;
    final currentService = serviceHandler.serviceType.value.name.toUpperCase();
    final isLoggedIn = serviceHandler.isLoggedIn.value;

    return AnymeXTile(
      icon: HugeIcons.strokeRoundedAiSetting,
      title: currentService,
      subtitle: 'CURRENT PROVIDER',
      borderRadius: BorderRadius.circular(16),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLoggedIn
                  ? colors.primary.opaque(0.15, iReallyMeanIt: true)
                  : colors.surfaceContainerHighest.opaque(0.5, iReallyMeanIt: true),
              borderRadius: BorderRadius.circular(6),
            ),
            child: AnymeXText(
              isLoggedIn ? 'Active' : 'Guest',
              size: 10,
              variant: TextVariant.bold,
              color: isLoggedIn
                  ? colors.primary
                  : colors.onSurface.opaque(0.6, iReallyMeanIt: true),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      onTap: () {
        Get.back();
        showServiceSelector(context);
      },
    );
  }

  Widget _buildTileGroup(BuildContext context) {
    final colors = context.colors;
    final extensionCount =
        Get.find<SourceController>().extensionUpdatesCount.value;

    return AnymeXSectionBuilder(
      margin: EdgeInsets.zero,
      children: [
        if (serviceHandler.isLoggedIn.value &&
            serviceHandler.serviceType.value == ServicesType.anilist)
          AnymeXTile(
            icon: IconlyLight.profile,
            title: context.l10n.viewProfile,
            subtitle: 'Profile stats & user activities',
            onTap: () {
              Get.back();
              navigate(() => const ProfilePage());
            },
          ),
        if ((Platform.isAndroid || Platform.isIOS) ||
            (kDebugMode &&
                (Platform.isWindows || Platform.isMacOS || Platform.isLinux)))
          AnymeXTile(
            icon: Icons.extension_rounded,
            title: 'Extensions',
            subtitle: 'Manage sources & plugins',
            trailing: extensionCount > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnymeXText(
                      '$extensionCount Updates',
                      size: 11,
                      variant: TextVariant.bold,
                      color: colors.onError,
                    ),
                  )
                : null,
            onTap: () {
              Get.back();
              navigate(() => const ExtensionScreen());
            },
          ),
        AnymeXTile(
          icon: HugeIcons.strokeRoundedDownload04,
          title: 'Downloads',
          subtitle: 'Saved offline episodes & chapters',
          onTap: () {
            Get.back();
            navigate(() => const DownloadScreen());
          },
        ),
        AnymeXTile(
          icon: Iconsax.document_download,
          title: 'Local Media',
          subtitle: 'Watch video files from device storage',
          onTap: () {
            Get.back();
            navigate(() => const WatchOffline());
          },
        ),
        AnymeXTile(
          icon: Icons.people_rounded,
          title: context.l10n.watchTogether,
          subtitle: 'Sync watch party with friends',
          onTap: () {
            Get.back();
            navigate(() => const WatchiumPage());
          },
        ),
        Obx(() => AnymeXTile.toggle(
              icon: settingsController.isIncognito.value
                  ? Iconsax.eye_slash
                  : Iconsax.eye,
              title: 'Incognito Mode',
              subtitle: 'Pause watch history and sync',
              value: settingsController.isIncognito.value,
              onChanged: (_) {
                settingsController.toggleIncognito();
                snackBar(
                  settingsController.isIncognito.value
                      ? 'Incognito mode enabled. History & sync paused.'
                      : 'Incognito mode disabled.',
                );
              },
            )),
        AnymeXTile(
          icon: Iconsax.setting,
          title: 'Settings',
          subtitle: 'Appearance, player & network',
          onTap: () {
            Get.back();
            navigate(() => const SettingsPage());
          },
        ),
      ],
    );
  }
}
