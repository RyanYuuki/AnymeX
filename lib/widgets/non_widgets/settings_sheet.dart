import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/extensions/ExtensionScreen.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/settings/settings.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SettingsSheet(),
    );
  }

  void showServiceSelector(BuildContext context) {
    final services = [
      {
        'type': ServicesType.anilist,
        'name': "AniList",
        'icon':
            'https://icons.iconarchive.com/icons/simpleicons-team/simple/256/anilist-icon.png',
      },
      {
        'type': ServicesType.mal,
        'name': "MyAnimeList",
        'icon':
            'https://cdn.icon-icons.com/icons2/3913/PNG/512/myanimelist_logo_icon_248409.png',
      },
      {
        'type': ServicesType.simkl,
        'name': "Simkl",
        'icon':
            'https://icon-icons.com/icons2/3915/PNG/512/simkl_logo_icon_249621.png',
      },
      if (serviceHandler.extensionService.isExtensionsServiceAllowed.value)
        {
          'type': ServicesType.extensions,
          'name': "Extensions",
          'icon': null,
        },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnymexText(
              text: "Select Service",
              size: 16,
              variant: TextVariant.semiBold,
            ),
            ...services.map((service) => ListTile(
                  leading: service['icon'] != null
                      ? CachedNetworkImage(
                          httpHeaders: const {
                            'Referer': 'https://icon-icons.com/'
                          },
                          color: Theme.of(context).colorScheme.primary,
                          imageUrl: service['icon'] as String,
                          width: 30,
                        )
                      : Icon(
                          Icons.extension,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  title: AnymexText(
                    text: service['name'] as String,
                    variant: TextVariant.semiBold,
                    color: serviceHandler.serviceType.value == service['type']
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onTap: () {
                    serviceHandler
                        .changeService(service['type'] as ServicesType);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const SizedBox(width: 5),
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              child: serviceHandler.isLoggedIn.value
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(IconlyBold.profile),
                          imageUrl:
                              serviceHandler.profileData.value.avatar ?? ''),
                    )
                  : Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(serviceHandler.profileData.value.name ?? 'Guest'),
                TVWrapper(
                  onTap: () {
                    if (serviceHandler.isLoggedIn.value) {
                      serviceHandler.logout();
                    } else {
                      serviceHandler.login();
                    }
                    Get.back();
                  },
                  child: Text(
                    serviceHandler.isLoggedIn.value ? 'Logout' : 'Login',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Expanded(
              child: SizedBox.shrink(),
            ),
            TVWrapper(
              child: IconButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  icon: const Icon(Iconsax.notification)),
            )
          ]),
          const SizedBox(height: 10),
          if (serviceHandler.isLoggedIn.value &&
              serviceHandler.serviceType.value == ServicesType.anilist)
            TVWrapper(
              child: ListTile(
                leading: const Icon(Iconsax.user),
                title: const Text('View Profile'),
                onTap: () {
                  Get.back();
                  Get.to(() => const ProfilePage());
                },
              ),
            ),
          if (isMobile)
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Extensions'),
              onTap: () {
                Get.back();
                Get.to(() => const ExtensionScreen());
              },
            ),
          TVWrapper(
            child: ListTile(
              leading: const Icon(HugeIcons.strokeRoundedAiSetting),
              title: const Text('Change Service'),
              onTap: () {
                Get.back();
                showServiceSelector(context);
              },
            ),
          ),
          TVWrapper(
            child: ListTile(
              leading: const Icon(Iconsax.document_download),
              title: const Text('Downloads (WIP)'),
              onTap: () {
                serviceHandler.simklService.fetchUserMovieList();
                Get.back();
              },
            ),
          ),
          TVWrapper(
            child: ListTile(
              leading: const Icon(Iconsax.setting),
              title: const Text('Settings'),
              onTap: () {
                Get.back();
                Get.to(() => const SettingsPage());
              },
            ),
          ),
        ],
      ),
    );
  }
}
