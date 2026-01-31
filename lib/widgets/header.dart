import 'dart:convert';
import 'dart:typed_data';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/theme.dart';
import 'package:anymex/controllers/ui/greeting.dart';
import 'package:anymex/screens/manga/widgets/search_selector.dart';
import 'package:anymex/screens/search/search_view.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/search_bar.dart';
import 'package:anymex/widgets/custom_widgets/anymex_animated_logo.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/custom_textspan.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex/widgets/non_widgets/settings_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconly/iconly.dart';
import 'package:palette_generator/palette_generator.dart';
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
                color: context.colors.onSecondaryContainer),
      ),
    );
  }
}

bool isBase64Image(String value) {
  if (value.isEmpty) return false;

  if (value.startsWith('data:image')) return true;

  return RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(value);
}

Uint8List base64ToBytes(String base64) {
  final cleaned = base64.contains(',') ? base64.split(',').last : base64;
  return base64Decode(cleaned);
}

class AnymeXImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final String? errorImage;
  final ValueChanged<Color>? onColorExtracted;

  const AnymeXImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.radius = 8,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.color,
    this.errorImage,
    this.onColorExtracted,
  });

  @override
  Widget build(BuildContext context) {
    final isBase64 = isBase64Image(imageUrl);

    if (onColorExtracted != null) {
      _extractDominantColor(isBase64);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: isBase64
          ? Image.memory(
              base64ToBytes(imageUrl),
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              color: color,
              colorBlendMode: color != null ? BlendMode.color : null,
              errorBuilder: (_, __, ___) => _fallback(context),
            )
          : CachedNetworkImage(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              color: color,
              colorBlendMode: color != null ? BlendMode.color : null,
              placeholder: (_, __) => _placeholder(context),
              errorWidget: (_, __, ___) {
                if (errorImage != null && errorImage!.isNotEmpty) {
                  return CachedNetworkImage(
                    imageUrl: errorImage!,
                    width: width,
                    height: height,
                    fit: fit,
                    placeholder: (_, __) => _placeholder(context),
                    errorWidget: (_, __, ___) => _fallback(context),
                  );
                }
                return _fallback(context);
              },
            ),
    );
  }

  Future<void> _extractDominantColor(bool isBase64) async {
    try {
      ImageProvider imageProvider;

      if (isBase64) {
        imageProvider = MemoryImage(base64ToBytes(imageUrl));
      } else {
        imageProvider = CachedNetworkImageProvider(imageUrl);
      }

      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 10,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color;

      if (dominantColor != null) {
        onColorExtracted?.call(dominantColor);
      }
    } catch (e) {}
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .opaque(0.2),
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _fallback(BuildContext context) {
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
                .opaque(0.3),
            context.colors.surfaceContainer.opaque(0.5),
          ],
        ),
      ),
      child: Center(
        child: Text(
          '(╥﹏╥)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .opaque(0.3),
              ),
        ),
      ),
    );
  }
}
