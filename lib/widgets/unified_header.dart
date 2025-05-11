import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';

class UnifiedHeader extends StatelessWidget {
  final bool isHomePage;
  static const EdgeInsets _defaultHorizontalPadding =
      EdgeInsets.symmetric(horizontal: 20.0);
  static const double _iconAvatarRadius = 24.0;
  const UnifiedHeader({
    super.key,
    this.isHomePage = false,
  });

  @override
  Widget build(BuildContext context) {
    final profileData = Get.find<ServiceHandler>();

    return Obx(() {
      if (isHomePage) {
        return _buildHomePageHeader(context, profileData);
      } else {
        return _buildStandardHeader(context, profileData);
      }
    });
  }

  Widget _buildStandardHeader(
      BuildContext context, ServiceHandler profileData) {
    final greetingController = Get.find<GreetingController>();

    return Padding(
      padding: _defaultHorizontalPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileIcon(context, profileData),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => Text(
                      "${greetingController.currentGreeting.value},",
                    )),
                Text(
                  profileData.profileData.value.name ?? 'Guest',
                  style: TextStyle(
                    fontFamily: "Poppins-SemiBold",
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _buildActions(context, profileData),
        ],
      ),
    );
  }

  Widget _buildHomePageHeader(
      BuildContext context, ServiceHandler profileData) {
    return PlatformBuilder(
      androidBuilder: Padding(
        padding: _defaultHorizontalPadding,
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
              ),
            ),
            const SizedBox(width: 12),
            const AnymexTextSpans(
              fontSize: 24,
              spans: [
                AnymexTextSpan(text: 'AnymeX', variant: TextVariant.bold)
              ],
            ),
            const Spacer(),
            _buildProfileIcon(context, profileData),
          ],
        ),
      ),
      desktopBuilder: Padding(
        padding: _defaultHorizontalPadding,
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
                            '${profileData.isLoggedIn.value ? profileData.profileData.value.name : 'Guest'}',
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
                  "Find your favourite anime, manga, manhwa or whatever you like!",
                  style: TextStyle(),
                ),
              ],
            ),
            const Spacer(),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              child: Image.asset(
                'assets/images/logo_transparent.png',
                color: Theme.of(context).colorScheme.inverseSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ServiceHandler profileData) {
    if (profileData.serviceType.value == ServicesType.extensions) {
      return AnymexOnTap(
        child: CircleAvatar(
          radius: _iconAvatarRadius,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: IconButton(
            tooltip: "Toggle Theme",
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: Icon(Get.theme.brightness == Brightness.light
                ? HugeIcons.strokeRoundedSun03
                : HugeIcons.strokeRoundedMoon01),
          ),
        ),
      );
    } else {
      return getResponsiveValue(
        context,
        mobileValue: AnymexOnTap(
          child: CircleAvatar(
            radius: _iconAvatarRadius,
            backgroundColor: Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withOpacity(0.50),
            child: isHomePage
                ? CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.transparent,
                    child: Image.asset(
                      'assets/images/logo_transparent.png',
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                  )
                : IconButton(
                    tooltip: "Search",
                    onPressed: () {
                      searchTypeSheet(context);
                    },
                    icon: const Icon(IconlyLight.search),
                  ),
          ),
        ),
        desktopValue: TappableSearchBar(
          onSubmitted: () {
            searchTypeSheet(context);
          },
        ),
      );
    }
  }

  Widget _buildProfileIcon(BuildContext context, ServiceHandler profileData) {
    return AnymexOnTap(
      onTap: () {
        return SettingsSheet.show(context);
      },
      child: CircleAvatar(
        radius: _iconAvatarRadius,
        backgroundColor:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.50),
        child: profileData.isLoggedIn.value
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: CachedNetworkImage(
                  width: _iconAvatarRadius * 2 - 4,
                  height: _iconAvatarRadius * 2 - 4,
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
        errorWidget: (context, url, error) {
          if (errorImage != null && errorImage!.isNotEmpty) {
            return CachedNetworkImage(
              width: width,
              height: height,
              fit: BoxFit.cover,
              alignment: alignment,
              imageUrl: errorImage!,
              placeholder: (context, url) => placeHolderWidget(context),
              errorWidget: (context, url, error) => _buildFallbackErrorWidget(),
            );
          } else {
            return _buildFallbackErrorWidget();
          }
        },
      ),
    );
  }

  Widget _buildFallbackErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );
  }
}
