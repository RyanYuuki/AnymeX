import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
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
        'icon': 'anilist-icon.png',
        'title': "Anilist"
      },
      {
        'service': serviceHandler.malService,
        'icon': 'mal-icon.png',
        'title': "MyAnimeList"
      },
      {
        'service': serviceHandler.simklService,
        'icon': 'simkl-icon.png',
        'title': "Simkl"
      },
    ];

    services.sort((a, b) =>
        (b['service'] == serviceHandler.onlineService ? 1 : 0)
            .compareTo(a['service'] == serviceHandler.onlineService ? 1 : 0));

    return Glow(
      child: Scaffold(
        body: ScrollWrapper(
          comfortPadding: false,
          customPadding: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 20.0),
          children: [
            Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                        .withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Accounts",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 30),
            for (var s in services)
              ProfileTile(
                serviceIcon: s['icon'] as String,
                service: s['service'] as OnlineService,
                title: s['title'] as String,
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final String serviceIcon;
  final OnlineService service;
  final String title;

  const ProfileTile({
    super.key,
    required this.serviceIcon,
    required this.service,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final isLoggedIn = service.isLoggedIn.value;
      final userData = isLoggedIn ? service.profileData.value : null;
      final isPrimary = serviceHandler.onlineService == service;
      final fallback = Image.asset(
        'assets/images/$serviceIcon',
        color: colorScheme.primary,
      );

      if (isPrimary && isLoggedIn) {
        return AnymexExpansionTile(
            title: 'Primary',
            initialExpanded: true,
            content: Column(
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            strokeAlign: BorderSide.strokeAlignOutside,
                            width: 3,
                            color: colorScheme.primary)),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                          imageUrl: userData!.avatar!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                10.height(),
                AnymexText(
                  text: userData.name!,
                  variant: TextVariant.semiBold,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.secondaryContainer.withOpacity(0.6),
                        colorScheme.surfaceContainerHighest.withOpacity(0.5)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      AnymexIconWrapper(
                        child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 16,
                            child: fallback),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnymexText(
                          text: 'Connected to $title',
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          service.logout();
                        },
                        child: const AnymexIconWrapper(
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 16,
                            child: Icon(
                              IconlyLight.logout,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ));
      }

      return AnymexExpansionTile(
        content: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.secondaryContainer.withOpacity(0.6),
                    colorScheme.surfaceContainerHighest.withOpacity(0.5)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  isLoggedIn
                      ? Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                  width: 3,
                                  color: colorScheme.primary)),
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: CachedNetworkImage(
                                height: 50,
                                width: 50,
                                imageUrl: userData?.avatar ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : AnymexIconWrapper(
                          child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 16,
                              child: fallback),
                        ),
                  const SizedBox(width: 10),
                  isLoggedIn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymexText(
                              text: userData!.name ?? 'Guest',
                              variant: TextVariant.semiBold,
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 130,
                              child: AnymexText(
                                text: 'Connected to $title',
                                color: Theme.of(context).colorScheme.primary,
                                maxLines: 2,
                              ),
                            )
                          ],
                        )
                      : AnymexText(
                          text: 'Connect to $title',
                        ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      isLoggedIn ? service.logout() : service.login();
                    },
                    child: AnymexIconWrapper(
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 16,
                        child: Icon(
                          isLoggedIn ? IconlyLight.logout : IconlyLight.login,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: title,
        initialExpanded: service.isLoggedIn.value,
      );
    });
  }
}
