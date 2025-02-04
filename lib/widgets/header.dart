import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class Header extends StatelessWidget {
  final bool isHomePage;
  const Header({super.key, this.isHomePage = false});

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();
    return Obx(() {
      if (!isHomePage) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              const SizedBox(width: 10),
              _profileIcon(context, profileData),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Good Night,"),
                  Text(profileData.profileData.value.name ?? 'Guest',
                      style: const TextStyle(fontFamily: "Poppins-SemiBold")),
                ],
              ),
              const Spacer(),
              getResponsiveValue(context,
                  mobileValue: TVWrapper(
                    child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withOpacity(0.5),
                        child: IconButton(
                            onPressed: () {
                              searchTypeSheet(context, "");
                            },
                            icon: const Icon(IconlyLight.search))),
                  ), desktopValue: TappableSearchBar(
                onSubmitted: () {
                  searchTypeSheet(context, "");
                },
              ))
              // CircleAvatar(
              //   radius: 24,
              //   backgroundColor:
              //       Theme.of(context).colorScheme.secondaryContainer,
              //   child: IconButton(
              //       style: ElevatedButton.styleFrom(
              //           backgroundColor:
              //               Theme.of(context).colorScheme.secondaryContainer),
              //       onPressed: () {
              //         provider.toggleTheme();
              //       },
              //       icon: Icon(Get.theme.brightness == Brightness.light
              //           ? HugeIcons.strokeRoundedSun03
              //           : HugeIcons.strokeRoundedMoon01)),
              // )
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
                    Text(
                        "Hey ${profileData.profileData.value.name ?? "Guest"}, What are we doing today?",
                        style: const TextStyle(
                            fontFamily: "Poppins-Bold", fontSize: 24)),
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

  TVWrapper _profileIcon(BuildContext context, ServiceHandler profileData) {
    return TVWrapper(
      onTap: () {
        return SettingsSheet.show(context);
      },
      child: CircleAvatar(
        radius: 24,
        backgroundColor:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        child: profileData.isLoggedIn.value
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  width: 50,
                  height: 50,
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
  const NetworkSizedImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.height,
    required this.width,
    this.alignment = Alignment.center,
    this.errorImage,
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
          imageUrl: imageUrl,
          placeholder: (context, url) => placeHolderWidget(context),
          errorWidget: (context, url, error) => CachedNetworkImage(
            width: width,
            height: height,
            fit: BoxFit.cover,
            alignment: alignment,
            imageUrl: errorImage ?? '',
          ),
        ));
  }
}
