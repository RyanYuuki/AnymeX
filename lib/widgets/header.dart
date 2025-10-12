import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              const Spacer(),
              if (profileData.serviceType.value == ServicesType.extensions) ...[
                AnymexOnTap(
                    child: CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: IconButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer),
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
                              .withOpacity(0.50),
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
                    child: Image.asset(
                      'assets/images/logo_transparent.png',
                      fit: BoxFit.cover,
                      color: Theme.of(context).colorScheme.inverseSurface,
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
                            color: Theme.of(context).colorScheme.primary,
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
                    child: Image.asset(
                      'assets/images/logo_transparent.png',
                      color: Theme.of(context).colorScheme.inverseSurface,
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
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.50),
        child: profileData.isLoggedIn.value
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      const Icon(IconlyBold.profile),
                  imageUrl: profileData.profileData.value.avatar ?? '',
                ),
              )
            : Icon(IconlyBold.profile,
                color: Theme.of(context).colorScheme.onSecondaryContainer),
      ),
    );
  }
}

class NetworkSizedImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final double? height;
  final double width;
  final Alignment alignment;
  final String? errorImage;
  final Color? color;
  const NetworkSizedImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.height,
    required this.width,
    this.alignment = Alignment.center,
    this.errorImage,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          width: width,
          height: height,
          fit: BoxFit.cover,
          alignment: alignment,
          color: color,
          colorBlendMode: color != null ? BlendMode.color : null,
          imageUrl: imageUrl,
          placeholder: (context, url) => placeHolderWidget(context),
          errorWidget: (context, url, error) {
            if (errorImage != null && errorImage!.isNotEmpty) {
              return CachedNetworkImage(
                width: width,
                height: height,
                fit: BoxFit.cover,
                alignment: alignment,
                imageUrl: errorImage!,
                placeholder: (context, url) => placeHolderWidget(context),
                errorWidget: (context, url, error) =>
                    _buildFallbackErrorWidget(context),
              );
            } else {
              return _buildFallbackErrorWidget(context);
            }
          },
        ));
  }

  Widget _buildFallbackErrorWidget(context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '(╥﹏╥)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
              ),
        ),
      ),
    );
  }
}
