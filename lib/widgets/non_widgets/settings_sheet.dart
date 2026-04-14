import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/community/forums_page.dart';
import 'package:anymex/screens/downloads/download_screen.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/local_source/local_source_view.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class SettingsSheet extends StatelessWidget {
  SettingsSheet({super.key});

  final serviceHandler = Get.find<ServiceHandler>();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsSheet(),
    );
  }

  void showServiceSelector(BuildContext context) {
    final theme = Theme.of(context);

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
        'desc': 'for movies and series'
      },
      if (serviceHandler.extensionService.installedExtensions.isNotEmpty &&
          serviceHandler.extensionService.installedMangaExtensions.isNotEmpty)
        {
          'type': ServicesType.extensions,
          'name': "Extensions",
          'icon': null,
          'desc': 'Third-party plugins'
        },
    ];

    Get.bottomSheet(
      ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.95,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface
                        .opaque(0.2, iReallyMeanIt: true),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const AnymexText(
                  text: "Choose Provider",
                  size: 20,
                  variant: TextVariant.bold,
                ),
                const SizedBox(height: 5),
                AnymexText(
                  text: "Select your preferred content source",
                  size: 14,
                  color: theme.colorScheme.onSurface
                      .opaque(0.5, iReallyMeanIt: true),
                ),
                const SizedBox(height: 25),
                ...services.map((service) {
                  final isSelected =
                      serviceHandler.serviceType.value == service['type'];
                  final primaryColor = theme.colorScheme.primary;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          serviceHandler.changeService(
                            service['type'] as ServicesType,
                          );
                          Get.back();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.opaque(0.1, iReallyMeanIt: true)
                                : theme.colorScheme.surfaceContainerHighest
                                    .opaque(0.3, iReallyMeanIt: true),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.opaque(0.2,
                                          iReallyMeanIt: true)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: service['icon'] != null
                                    ? Image.asset(
                                        'assets/images/${service['icon']}',
                                        width: 24,
                                        height: 24,
                                        color: isSelected
                                            ? primaryColor
                                            : theme.iconTheme.color,
                                      )
                                    : Icon(
                                        Icons.extension_rounded,
                                        size: 24,
                                        color: isSelected
                                            ? primaryColor
                                            : theme.iconTheme.color,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnymexText(
                                      text: service['name'] as String,
                                      size: 16,
                                      variant: TextVariant.semiBold,
                                      color: isSelected ? primaryColor : null,
                                    ),
                                    if (service['desc'] != null) ...[
                                      const SizedBox(height: 2),
                                      AnymexText(
                                        text: service['desc'] as String,
                                        size: 12,
                                        color: theme.colorScheme.onSurface
                                            .opaque(0.6),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 14,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 16 + bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.outline.opaque(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.onSurface.opaque(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              _buildProfileHeader(context, theme),
              const SizedBox(height: 10),
              _buildMenuSection(context, theme),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ColorScheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.12)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: serviceHandler.isLoggedIn.value &&
                    serviceHandler.serviceType.value == ServicesType.anilist
                ? () {
                    Get.back();
                    navigate(() => const ProfilePage());
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primary.opaque(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.surfaceContainer,
                child: serviceHandler.isLoggedIn.value
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: AnymeXImage(
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          radius: 0,
                          imageUrl:
                              serviceHandler.profileData.value.avatar ?? ''),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: theme.onSurface.opaque(0.7),
                        size: 24,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnymexText(
                  text: serviceHandler.profileData.value.name ?? 'Guest',
                  variant: TextVariant.semiBold,
                  size: 14,
                ),
                if (serviceHandler.serviceType.value != ServicesType.extensions)
                  AnymexOnTap(
                    onTap: () async {
                      if (serviceHandler.isLoggedIn.value) {
                        serviceHandler.logout();
                      } else {
                        await serviceHandler.login(context);
                      }
                      Get.back();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnymexText(
                          text: serviceHandler.isLoggedIn.value
                              ? 'Tap to logout'
                              : 'Tap to login',
                          size: 12,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          serviceHandler.isLoggedIn.value
                              ? Icons.logout_rounded
                              : Icons.login_rounded,
                          size: 12,
                          color: theme.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          AnymexOnTap(
            onTap: () => snackBar('This feature is not available yet.'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest.opaque(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.notification,
                  size: 18, color: theme.onSurface.opaque(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, ColorScheme theme) {
    final items = <_SheetMenuItem>[
      if (serviceHandler.isLoggedIn.value &&
          serviceHandler.serviceType.value == ServicesType.anilist)
        _SheetMenuItem(
          icon: IconlyLight.profile,
          label: 'View Profile',
          onTap: () {
            Get.back();
            navigate(() => const ProfilePage());
          },
        ),
      if (serviceHandler.isLoggedIn.value &&
          serviceHandler.serviceType.value == ServicesType.anilist)
        _SheetMenuItem(
          icon: Icons.forum_rounded,
          label: 'Forums',
          onTap: () {
            Get.back();
            navigate(() => const ForumsPage());
          },
        ),
      _SheetMenuItem(
        icon: HugeIcons.strokeRoundedAiSetting,
        label: 'Change Service',
        onTap: () {
          Get.back();
          showServiceSelector(context);
        },
      ),
      _SheetMenuItem(
        icon: HugeIcons.strokeRoundedDownload04,
        label: 'Downloads',
        onTap: () {
          Get.back();
          navigate(() => const DownloadScreen());
        },
      ),
      _SheetMenuItem(
        icon: Iconsax.document_download,
        label: 'Local Media',
        onTap: () {
          Get.back();
          navigate(() => const WatchOffline());
        },
      ),
      _SheetMenuItem(
        icon: Iconsax.setting,
        label: 'Settings',
        onTap: () {
          Get.back();
          navigate(() => const SettingsPage());
        },
      ),
    ];

    final mobileExtensionItem = _SheetMenuItem(
      icon: Icons.extension_rounded,
      label: 'Extensions',
      onTap: () {
        Get.back();
        navigate(() => const ExtensionScreen());
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainer.opaque(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outline.opaque(0.1)),
      ),
      child: Column(
        children: [
          PlatformBuilder(
            androidBuilder: _buildMenuItem(
              context,
              theme,
              mobileExtensionItem,
              isFirst: true,
              isLast: false,
            ),
            desktopBuilder: const SizedBox.shrink(),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isMobile = MediaQuery.of(context).size.width < 600;
            final effectiveFirst = isMobile ? false : index == 0;
            final isLast = index == items.length - 1;
            return _buildMenuItem(
              context,
              theme,
              item,
              isFirst: effectiveFirst,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    ColorScheme theme,
    _SheetMenuItem item, {
    required bool isFirst,
    required bool isLast,
  }) {
    return AnymexOnTap(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.outline.opaque(0.08),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.primaryContainer.opaque(0.3),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnymexText(
                text: item.label,
                size: 13.5,
                variant: TextVariant.semiBold,
              ),
            ),
            Icon(
              IconlyLight.arrow_right_2,
              size: 14,
              color: theme.onSurface.opaque(0.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}