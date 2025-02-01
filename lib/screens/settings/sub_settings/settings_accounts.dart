import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/minor_widgets/custom_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class SettingsAccounts extends StatelessWidget {
  const SettingsAccounts({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceHandler = Get.find<ServiceHandler>();
    final al = serviceHandler.anilistService;
    final mal = serviceHandler.malService;
    final simkl = serviceHandler.simklService;
    return Glow(
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 20.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainer),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                const SizedBox(width: 10),
                const Text("Accounts",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 30),
            ProfileTile(
                serviceIcon:
                    'https://icons.iconarchive.com/icons/simpleicons-team/simple/256/anilist-icon.png',
                service: al),
            ProfileTile(
                serviceIcon:
                    'https://cdn.icon-icons.com/icons2/3913/PNG/512/myanimelist_logo_icon_248409.png',
                service: mal),
            ProfileTile(
                serviceIcon:
                    'https://icon-icons.com/icons2/3915/PNG/512/simkl_logo_icon_249621.png',
                service: simkl),
          ],
        ),
      ),
    ));
  }
}

class ProfileTile extends StatelessWidget {
  final String serviceIcon;
  final OnlineService service;

  const ProfileTile({
    super.key,
    required this.serviceIcon,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
      child: Obx(() {
        final isLoggedIn = service.isLoggedIn.value; // Reactive state
        return Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: CachedNetworkImage(
                imageUrl: serviceIcon,
                color: Theme.of(context).colorScheme.primary,
                httpHeaders: const {'Referer': 'https://icon-icons.com/'},
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoggedIn) ...[
                    AnymexText(
                      text: service.profileData.value.name ?? '',
                      variant: TextVariant.semiBold,
                      size: 16,
                    ),
                  ],
                  InkWell(
                    onTap: () async {
                      await (isLoggedIn ? service.logout() : service.login());
                    },
                    child: AnymexText(
                      text: isLoggedIn ? "LOGOUT" : "LOGIN",
                      color: Theme.of(context).colorScheme.primary,
                      variant: TextVariant.semiBold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 35,
              height: 35,
              child: (isLoggedIn && service.profileData.value.avatar != null)
                  ? NetworkSizedImage(
                      radius: 100,
                      width: 35,
                      height: 35,
                      imageUrl: service.profileData.value.avatar!,
                    )
                  : const Icon(IconlyLight.profile),
            ),
          ],
        );
      }),
    );
  }
}
