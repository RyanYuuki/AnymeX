import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/local_source/local_source_view.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/custom_widgets/anymex_bottomsheet.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class SettingsSheet extends StatelessWidget {
  SettingsSheet({super.key});

  final serviceHandler = Get.find<ServiceHandler>();

  static void show(BuildContext context) {
    AnymexSheet(
      customWidget: SettingsSheet(),
    ).show(context);
  }

  void showServiceSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      if (serviceHandler.extensionService.installedExtensions.length > 2 &&
          serviceHandler.extensionService.installedMangaExtensions.length > 2)
        {
          'type': ServicesType.extensions,
          'name': "Extensions",
          'icon': null,
          'desc': 'Third-party plugins'
        },
    ];

    AnymexSheet.custom(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.opaque(0.2),
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
              color: theme.colorScheme.onSurface.opaque(0.5),
              variant: TextVariant.regular,
            ),
            const SizedBox(height: 25),
            ...services.map((service) {
              final isSelected =
                  serviceHandler.serviceType.value == service['type'];
              final primaryColor = theme.colorScheme.primary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      serviceHandler
                          .changeService(service['type'] as ServicesType);
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.opaque(0.1)
                            : theme.colorScheme.surfaceContainerHighest
                                .opaque(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.opaque(0.2)
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
                                ]
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
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const SizedBox(width: 5),
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colors.surfaceContainer,
                child: serviceHandler.isLoggedIn.value
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            width: 45,
                            height: 45,
                            errorWidget: (context, url, error) =>
                                const Icon(IconlyBold.profile),
                            imageUrl:
                                serviceHandler.profileData.value.avatar ?? ''),
                      )
                    : Icon(
                        Icons.person,
                        color: context.colors.inverseSurface,
                      ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceHandler.profileData.value.name ?? 'Guest'),
                  if (serviceHandler.serviceType.value !=
                      ServicesType.extensions)
                    AnymexOnTap(
                      onTap: () async {
                        if (serviceHandler.isLoggedIn.value) {
                          serviceHandler.logout();
                        } else {
                          await serviceHandler.login(context);
                        }
                        Get.back();
                      },
                      child: Text(
                        serviceHandler.isLoggedIn.value ? 'Logout' : 'Login',
                        style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const Expanded(
                child: SizedBox.shrink(),
              ),
              AnymexOnTap(
                child: IconButton(
                    onPressed: () {
                      snackBar('This feature is not available yet.');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors
                            .surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    icon: const Icon(Iconsax.notification)),
              )
            ]),
            const SizedBox(height: 10),
            if (serviceHandler.isLoggedIn.value &&
                serviceHandler.serviceType.value == ServicesType.anilist)
              AnymexOnTap(
                child: ListTile(
                  leading: const Icon(Iconsax.user),
                  title: const Text('View Profile'),
                  onTap: () {
                    Get.back();
                    navigate(() => const ProfilePage());
                  },
                ),
              ),
            Obx(() {
              final shouldShowExts =
                  sourceController.shouldShowExtensions.value;
              return isMobile && shouldShowExts
                  ? ListTile(
                      leading: const Icon(Icons.extension),
                      title: const Text('Extensions'),
                      onTap: () {
                        Get.back();
                        navigate(() => const ExtensionScreen());
                      },
                    )
                  : const SizedBox.shrink();
            }),
            AnymexOnTap(
              child: ListTile(
                leading: const Icon(HugeIcons.strokeRoundedAiSetting),
                title: const Text('Change Service'),
                onTap: () {
                  Get.back();
                  showServiceSelector(context);
                },
              ),
            ),
            AnymexOnTap(
              child: ListTile(
                leading: const Icon(Iconsax.document_download),
                title: const Text('Local Media'),
                onTap: () {
                  Get.back();
                  navigate(() => const WatchOffline());
                },
              ),
            ),
            AnymexOnTap(
              child: ListTile(
                leading: const Icon(Iconsax.setting),
                title: const Text('Settings'),
                onTap: () {
                  Get.back();
                  navigate(() => const SettingsPage());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
