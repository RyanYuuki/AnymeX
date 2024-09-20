// ignore_for_file: prefer_const_constructors, deprecated_member_use, non_constant_identifier_names, must_be_immutable, avoid_print

import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:aurora/components/IconWithLabel.dart';
import 'package:aurora/components/reusable_carousel.dart';
import 'package:aurora/components/character_cards.dart';
import 'package:aurora/database/api.dart';
import 'package:aurora/database/database.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconly/iconly.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';

Color? hexToColor(String hexColor) {
  if (hexColor == '??') {
    return null;
  } else {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class DetailsPage extends StatefulWidget {
  final String id;
  final String? posterUrl;
  final String? tag;
  const DetailsPage({super.key, required this.id, this.posterUrl, this.tag});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool usingConsumet =
      Hive.box('app-data').get('using-consumet', defaultValue: false);
  dynamic data;
  bool isLoading = true;
  dynamic charactersData;
  String? description;

  final String baseUrl =
      'https://goodproxy.goodproxy.workers.dev/fetch?url=https://aniwatch-ryan.vercel.app/anime/info?id=';

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
  }

  Future<void> fetchAnimeData() async {
    try {
      setState(() {
        isLoading = true;
        usingConsumet =
            Hive.box('app-data').get('using-consumet', defaultValue: false);
      });
      if (usingConsumet) {
        await fetchFromConsumet();
      } else {
        await fetchFromAniwatch();
      }
    } catch (e) {
      log('Primary fetch failed: $e, switching API...');
      if (usingConsumet) {
        try {
          await fetchFromAniwatch();
        } catch (e) {
          log('Fallback Aniwatch fetch failed: $e');
        }
      } else {
        try {
          await fetchFromConsumet();
        } catch (e) {
          log('Fallback Consumet fetch failed: $e');
        }
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchFromConsumet() async {
    final tempData = await fetchAnimeDetailsConsumet(widget.id);
    if (tempData != null) {
      setState(() {
        data = conditionDetailPageData(tempData, true);
        description = tempData['description'] ?? 'No description available';
        charactersData = tempData['characters'] ?? [];
        if (Hive.box('login-data')
                .get('PaletteMode', defaultValue: 'Material') ==
            'Banner') {
          Provider.of<ThemeProvider>(context, listen: false)
              .adaptBannerColor(hexToColor(data['color'])!);
        } else {
          Provider.of<ThemeProvider>(context, listen: false)
              .checkAndApplyPaletteMode();
        }
      });
    } else {
      throw Exception('Consumet fetch failed');
    }
  }

  Future<void> fetchFromAniwatch() async {
    final tempData = await fetchAnimeDetailsAniwatch(widget.id);
    if (tempData != null) {
      setState(() {
        data = mergeData(tempData);
      });

      final newResponse = await http.get(Uri.parse(
          'https://goodproxy.goodproxy.workers.dev/fetch?url=https://consumet-api-two-nu.vercel.app/meta/anilist/info/${data['anilistId']}'));

      if (newResponse.statusCode == 200) {
        final characterTemp = jsonDecode(newResponse.body);
        setState(() {
          description = characterTemp['description'] ?? data['description'];
          charactersData = characterTemp['characters'] ?? [];
        });
      } else {
        log('Failed to fetch character data from Consumet: ${newResponse.statusCode}');
      }
    } else {
      throw Exception('Aniwatch fetch failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: CustomScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextScroll(
          data == null ? 'Loading...' : data['name'] ?? '??',
          mode: TextScrollMode.bouncing,
          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
          delayBefore: const Duration(milliseconds: 500),
          pauseBetween: const Duration(milliseconds: 1000),
          textAlign: TextAlign.center,
          selectable: true,
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(IconlyBold.arrow_left),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Column(
              children: [
                Center(
                  child: Poster(tag: widget.tag, poster: widget.posterUrl),
                ),
                const SizedBox(height: 30),
                CircularProgressIndicator(),
              ],
            )
          : Stack(
              children: [
                ListView(
                  children: [
                    Column(
                      children: [
                        Poster(
                          tag: widget.tag,
                          poster: widget.posterUrl,
                        ),
                        const SizedBox(height: 30),
                        Info(context),
                      ],
                    ),
                  ],
                ),
                if (data?['stats']?['episodes']?['sub'] != 0 &&
                        data?['stats']?['episodes']?['sub'] != null ||
                    data?['totalEpisodes'] != 0 &&
                        data?['totalEpisodes'] != null)
                  (FloatingBar(
                    title: data['name'] ?? '??',
                    id: widget.id,
                    usingConsumet: usingConsumet,
                    color: hexToColor(data['color'] ?? '??'),
                  ))
              ],
            ),
    );
  }

  Container Info(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomScheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 170),
                    child: TextScroll(
                      data == null ? 'Loading...' : data['name'] ?? '??',
                      mode: TextScrollMode.endless,
                      velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                      delayBefore: Duration(milliseconds: 500),
                      pauseBetween: Duration(milliseconds: 1000),
                      textAlign: TextAlign.center,
                      selectable: true,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 18,
                    width: 3,
                    color: CustomScheme.inverseSurface,
                  ),
                  const SizedBox(width: 10),
                  iconWithName(
                    backgroundColor: CustomScheme.onPrimaryFixedVariant,
                    icon: Iconsax.star1,
                    TextColor: CustomScheme.inverseSurface ==
                            CustomScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : CustomScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    color: CustomScheme.inverseSurface ==
                            CustomScheme.onPrimaryFixedVariant
                        ? Colors.black
                        : CustomScheme.onPrimaryFixedVariant ==
                                Color(0xffe2e2e2)
                            ? Colors.black
                            : Colors.white,
                    name: data['rating'] ?? data['malscore'],
                    isVertical: false,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: (data?['genres'] as List<dynamic>? ?? [])
                    .take(3)
                    .map<Widget>(
                      (genre) => Container(
                        margin: EdgeInsets.only(right: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: CustomScheme.onPrimaryFixedVariant,
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(
                          genre as String,
                          style: TextStyle(
                              color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface ==
                                      Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant
                                  ? Colors.black
                                  : Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixedVariant ==
                                          Color(0xffe2e2e2)
                                      ? Colors.black
                                      : Colors.white,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.fontSize,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: EdgeInsets.all(7),
                  width: 130,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5)),
                      color: CustomScheme.surfaceContainerHighest),
                  child: Column(
                    children: [
                      Text(
                          data?['totalEpisodes'] ??
                              data?['stats']['episodes']['sub'].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Episodes')
                    ],
                  ),
                ),
                Container(
                  color: CustomScheme.onPrimaryFixed,
                  height: 30,
                  width: 2,
                ),
                Container(
                  width: 130,
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5)),
                      color: CustomScheme.surfaceContainerHighest),
                  child: Column(
                    children: [
                      Text(
                        data?['duration'] ?? '??',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Per Ep')
                    ],
                  ),
                ),
              ])
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: CustomScheme.surfaceContainerHighest,
            ),
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  description?.replaceAll(RegExp(r'<[^>]*>'), '') ??
                      data?['description'].replaceAll(RegExp(r'<[^>]*>'), '') ??
                      'Description Not Found',
                  maxLines: 13,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CharacterCards(
            carouselData: charactersData,
          ),
          ReusableCarousel(
            title: 'Popular',
            carouselData: data?['popularAnimes'],
            tag: 'details-page1',
          ),
          ReusableCarousel(
            title: 'Related',
            carouselData: data?['relatedAnimes'],
            tag: 'details-page2',
          ),
          ReusableCarousel(
            title: 'Recommended',
            carouselData: data?['recommendedAnimes'],
            tag: 'details-page3',
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class FloatingBar extends StatelessWidget {
  final String? title;
  final String? id;
  final bool usingConsumet;
  final Color? color;
  const FloatingBar(
      {super.key,
      this.title,
      this.id,
      required this.usingConsumet,
      this.color});

  @override
  Widget build(BuildContext context) {
    ColorScheme CustomScheme = Theme.of(context).colorScheme;
    final provider = Provider.of<AppData>(context);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .inverseSurface
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 130),
                              child: TextScroll(
                                title!,
                                mode: TextScrollMode.bouncing,
                                velocity:
                                    Velocity(pixelsPerSecond: Offset(20, 0)),
                                delayBefore: Duration(milliseconds: 500),
                                pauseBetween: Duration(milliseconds: 1000),
                                textAlign: TextAlign.center,
                                selectable: true,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                                .colorScheme
                                                .inverseSurface ==
                                            Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant
                                        ? Colors.black
                                        : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryFixedVariant ==
                                                Color(0xffe2e2e2)
                                            ? Colors.black
                                            : Colors.white),
                              ),
                            ),
                            Text(
                              'Episode ${provider.getCurrentEpisodeForAnime(id!) ?? '1'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface ==
                                        Theme.of(context)
                                            .colorScheme
                                            .onPrimaryFixedVariant
                                    ? Colors.black
                                    : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryFixedVariant ==
                                            Color(0xffe2e2e2)
                                        ? Colors.black
                                        : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/watch',
                            arguments: {'id': id});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomScheme.onPrimaryFixedVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.play_circle5,
                            color: CustomScheme.inverseSurface ==
                                    CustomScheme.onPrimaryFixedVariant
                                ? Colors.black
                                : CustomScheme.onPrimaryFixedVariant ==
                                        Color(0xffe2e2e2)
                                    ? Colors.black
                                    : Colors.white, // Icon color
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Watch',
                            style: TextStyle(
                              color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface ==
                                      Theme.of(context)
                                          .colorScheme
                                          .onPrimaryFixedVariant
                                  ? Colors.black
                                  : Theme.of(context)
                                              .colorScheme
                                              .onPrimaryFixedVariant ==
                                          Color(0xffe2e2e2)
                                      ? Colors.black
                                      : Colors.white, // Text color
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.tag,
    required this.poster,
  });
  final String? poster;
  final String? tag;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 30),
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width - 100,
            child: Hero(
              tag: tag!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: poster!,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
