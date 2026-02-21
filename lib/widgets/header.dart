import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

enum PageType { manga, anime, home }

class Header extends StatelessWidget {
  final PageType type;
  const Header({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();
    final greetingController = Get.find<GreetingController>();
    return Obx(() {
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
                  Obx(() => Text(
                        "${greetingController.currentGreeting.value},",
                      )),
                  Text(profileData.profileData.value.name ?? 'Guest',
                      style: TextStyle(
                          fontFamily: "Poppins-SemiBold",
                          color: context.colors.primary)),
                ],
              ),
              const Spacer(),
              if (profileData.serviceType.value == ServicesType.extensions) ...[
                AnymexOnTap(
                    child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      context.colors.secondaryContainer,
                  child: IconButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              context.colors.secondaryContainer),
                      onPressed: () {
                        Provider.of<ThemeProvider>(context, listen: false)
                            .toggleTheme();
                      },
                      icon: Icon(Get.theme.brightness == Brightness.light
                          ? HugeIcons.strokeRoundedSun03
                          : HugeIcons.strokeRoundedMoon01)),
                )),
              ] else ...[
                getResponsiveValue(context,
                    mobileValue: AnymexOnTap(
                      child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .opaque(0.50),
                          child: IconButton(
                              onPressed: () {
                                final hasNovelExts = sourceController
                                    .installedNovelExtensions.isNotEmpty;
                                if (type == PageType.manga) {
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
                              },
                              icon: const Icon(IconlyLight.search))),
                    ), desktopValue: TappableSearchBar(
                  onSubmitted: () {
                    if (type == PageType.manga) {
                      searchTypeSheet(context);
                    } else {
                      navigate(() => const SearchPage(
                            searchTerm: '',
                            isManga: false,
                          ));
                    }
                  },
                )),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnymexTextSpans(
                      fontSize: 24,
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                        "Find your favourite Anime, Manga, Manhwa or whatever you like!",
                        style: TextStyle())
                  ],
                ),
                const Spacer(),
                CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    child: AnymeXAnimatedLogo(
                      size: 80,
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
      child: CircleAvatar(
        radius: 24,
        backgroundColor:
            context.colors.secondaryContainer.opaque(0.50),
        child: profileData.isLoggedIn.value
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: AnymeXImage(
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  radius: 0,
                  errorImage: '',
                  imageUrl:
                      profileData.profileData.value.avatar ?? '',
                ),
              )
            : Icon(IconlyBold.profile,
                color: context.colors.onSecondaryContainer),
      ),
    );
  }
}
