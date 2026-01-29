import 'dart:io';

import 'package:anymex/controllers/discord/discord_login.dart';
import 'package:anymex/controllers/discord/discord_rpc.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/screens/settings/sub_settings/widgets/account_tile.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/custom_expansion_tile.dart';
import 'package:anymex/widgets/custom_widgets/custom_icon_wrapper.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/scroll_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:anymex/screens/other_features.dart';

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
        body: Column( // Changed from ScrollWrapper to Column
          children: [
            const NestedHeader(title: 'Accounts'), // Add NestedHeader
            Expanded( // Wrap scrollable content in Expanded
              child: ScrollWrapper(
                comfortPadding: false,
                customPadding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0), // Changed top from 50.0 to 20.0
                children: [
            if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS)
              const DiscordTile(),
            for (var s in services)
              ProfileTile(
                serviceIcon: s['icon'] as String,
                service: s['service'] as OnlineService,
                title: s['title'] as String,
              ),
          ],
        ),
      ),
          ]
        )
      )
      );
  }
}

class DiscordTile extends StatelessWidget {
  const DiscordTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final rpc = DiscordRPCController.instance;
      final isLoggedIn = rpc.isLoggedIn;
      final userData = isLoggedIn ? rpc.profile.value : null;

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
                                imageUrl: userData?.avatarUrl ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : const AnymexIconWrapper(
                          child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 16,
                              child: Icon(
                                IconlyLight.profile,
                              )),
                        ),
                  const SizedBox(width: 10),
                  isLoggedIn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnymexText(
                              text: userData?.displayName ?? 'Loading...',
                              variant: TextVariant.semiBold,
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 130,
                              child: AnymexText(
                                text: 'Connected to Discord',
                                color: Theme.of(context).colorScheme.primary,
                                maxLines: 2,
                              ),
                            )
                          ],
                        )
                      : const AnymexText(
                          text: 'Connect to Discord',
                        ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      isLoggedIn
                          ? rpc.logout()
                          : context.showDiscordLogin(
                              (token) => rpc.onLoginSuccess(token));
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
        title: 'Discord',
        initialExpanded: true,
      );
    });
  }
}
