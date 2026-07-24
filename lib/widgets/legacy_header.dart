import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/screens/search/source_search_page.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:anymex/screens/profile/profile_page.dart';
import 'package:anymex/screens/extensions/ExtensionTesting/extension_test_page.dart';
import 'package:anymex/screens/settings/sub_settings/settings_extensions.dart';

enum PageType { manga, anime, home, novel, library, extensions }

class Header extends StatelessWidget {
  final PageType type;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onSortPressed;

  const Header({
    super.key,
    required this.type,
    this.onSearchPressed,
    this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();
    final greetingController = Get.find<GreetingController>();
    return Builder(builder: (ctx) {
      if (type != PageType.home) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              _profileIcon(context, profileData),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (type == PageType.library) ...[
                    const Text(
                      "Library",
                    ),
                    Text(
                      "All your local shi",
                      style: TextStyle(
                        fontFamily: "Poppins-SemiBold",
                        color: context.colors.primary,
                      ),
                    ),
                  ] else if (type == PageType.extensions) ...[
                    const Text(
                      "Extensions",
                    ),
                    Text(
                      "Manage plugins & sources",
                      style: TextStyle(
                        fontFamily: "Poppins-SemiBold",
                        color: context.colors.primary,
                      ),
                    ),
                  ] else ...[
                    Obx(() => Text(
                          "${greetingController.currentGreeting.value},",
                        )),
                    Text(
                      profileData.profileData.value.name ?? 'Guest',
                      style: TextStyle(
                        fontFamily: "Poppins-SemiBold",
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              if (type == PageType.library) ...[
                Row(
                  children: [
                    if (onSearchPressed != null)
                      AnymexOnTap(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .opaque(0.50),
                          child: IconButton(
                            onPressed: onSearchPressed,
                            icon: Icon(
                              IconlyLight.search,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    if (onSortPressed != null) ...[
                      const SizedBox(width: 8),
                      AnymexOnTap(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .opaque(0.50),
                          child: IconButton(
                            onPressed: onSortPressed,
                            icon: Icon(
                              Icons.sort,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (type == PageType.extensions) ...[
                Row(
                  children: [
                    AnymexOnTap(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .opaque(0.50),
                        child: IconButton(
                          onPressed: () => Get.to(() => const ExtensionTestPage()),
                          icon: Icon(
                            Icons.build_outlined,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnymexOnTap(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .opaque(0.50),
                        child: IconButton(
                          onPressed: () => navigate(() => const SettingsExtensions()),
                          icon: Icon(
                            HugeIcons.strokeRoundedGithub,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                AnymexOnTap(
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .opaque(0.50),
                    child: IconButton(
                      onPressed: () {
                        if (profileData.serviceType.value == ServicesType.extensions) {
                          final itemType = type == PageType.manga
                              ? ItemType.manga
                              : (type == PageType.novel
                                  ? ItemType.novel
                                  : ItemType.anime);
                          navigateWithAnimation(() => SourceSearchPage(
                                initialTerm: '',
                                type: itemType,
                                source: null,
                              ));
                        } else {
                          final hasNovelExts = sourceController
                              .installedNovelExtensions.isNotEmpty;
                          final isSimkl = profileData.serviceType.value ==
                              ServicesType.simkl;
                          if (type == PageType.manga) {
                            if (isSimkl) {
                              navigate(() => const SearchPage(
                                    searchTerm: '',
                                    isManga: false,
                                  ));
                              return;
                            }
                            if (!hasNovelExts) {
                              navigate(() => const SearchPage(
                                    searchTerm: '',
                                    isManga: true,
                                  ));
                              return;
                            }
                            searchTypeSheet(context);
                          } else {
                            navigate(() => const SearchPage(
                                  searchTerm: '',
                                  isManga: false,
                                ));
                          }
                        }
                      },
                      icon: Icon(
                        IconlyLight.search,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
      } else {
        return PlatformBuilder(
          androidBuilder: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                    width: 50,
                    height: 70,
                    child: AnymeXAnimatedLogo(
                      size: 50,
                      autoPlay: true,
                      color: context.colors.inverseSurface,
                    )),
                const Spacer(),
                _profileIcon(context, profileData)
              ],
            ),
          ),
          desktopBuilder: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnymexTextSpans(
                        fontSize: 18,
                        spans: [
                          const AnymexTextSpan(
                              text: 'Hey ', variant: TextVariant.bold),
                          AnymexTextSpan(
                              text:
                                  '${serviceHandler.isLoggedIn.value ? serviceHandler.profileData.value.name : 'Guest'}',
                              color: context.colors.primary,
                              variant: TextVariant.bold),
                          const AnymexTextSpan(
                              text: ', what are we doing today?',
                              variant: TextVariant.bold)
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Find your favourite Anime, Manga, Manhwa or whatever you like!",
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: AnymeXAnimatedLogo(
                      size: 56,
                      autoPlay: true,
                      color: context.colors.inverseSurface,
                    )),
              ],
            ),
          ),
        );
      }
    });
  }

  AnymexOnTap _profileIcon(BuildContext context, ServiceHandler profileData) {
    return AnymexOnTap(
      onTap: () {
        return SettingsSheet.show(context);
      },
      child: GestureDetector(
        onLongPress: () {
          if (profileData.isLoggedIn.value) {
            navigate(() => const ProfilePage());
          }
        },
        child: Obx(() {
          final count =
              Get.find<SourceController>().extensionUpdatesCount.value;
          final avatar = CircleAvatar(
            radius: 24,
            backgroundColor: context.colors.secondaryContainer.opaque(0.50),
            child: profileData.isLoggedIn.value
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: AnymeXImage(
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                      radius: 0,
                      errorImage: '',
                      imageUrl: profileData.profileData.value.avatar ?? '',
                    ),
                  )
                : Icon(IconlyBold.profile,
                    color: context.colors.onSecondaryContainer),
          );
          if (count > 0) {
            return Badge(
              label: Text(count.toString()),
              backgroundColor: context.colors.primary,
              textColor: context.colors.onPrimary,
              child: avatar,
            );
          }
          return avatar;
        }),
      ),
    );
  }
}
