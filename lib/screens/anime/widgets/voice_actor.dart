import 'dart:math' show Random;
import 'package:anymex/controllers/settings/methods.dart';
import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/staff.dart';
import 'package:anymex/screens/anime/widgets/character_staff_sheet.dart';

import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';


class CharactersCarousel extends StatelessWidget {
  final List<Character> characters;
  final bool isManga;
  const CharactersCarousel(
      {super.key, required this.characters, this.isManga = false});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (characters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text("Characters",
              style: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  fontSize: isDesktop ? 20 : 17,
                  color: context.colors.primary)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: isDesktop ? 290 : 210,
          child: ListView.builder(
            itemCount: characters.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
            itemBuilder: (BuildContext context, int index) {
              final itemData = characters[index];
              final tag = generateTag('${itemData.name}-$index');

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                constraints: BoxConstraints(maxWidth: isDesktop ? 150 : 108),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {

                      showCharacterStaffSheet(context,
                          item: itemData, isCharacter: true);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Hero(
                              tag: tag,
                              child: AnymeXImage(
                                imageUrl: itemData.image ??
                                    'https://s4.anilist.co/file/anilistcdn/character/large/default.jpg',
                                radius: 12.multiplyRoundness(),
                                height: isDesktop ? 210 : 160,
                                width: double.infinity,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.heart5,
                                      size: 16,
                                      color: context.colors.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      itemData.favourites.toString(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: "Poppins-Bold",
                                          fontStyle: FontStyle.italic,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inverseSurface
                                              .opaque(0.9)),
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          itemData.name ?? '??',
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontFamily: "Poppins-SemiBold"),
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (!isManga) ...[
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text("Voice Actors",
                style: TextStyle(
                    fontFamily: "Poppins-SemiBold",
                    fontSize: 18,
                    color: context.colors.primary)),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: isDesktop ? 290 : 230,
            child: ListView.builder(
            itemCount: characters.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20),
              itemBuilder: (BuildContext context, int index) {
                final character = characters[index];
                final characterName = character.name;
                final itemData = (character.voiceActors.isNotEmpty)
                    ? character.voiceActors[0]
                    : null;
                final tag =
                    generateTag('${itemData?.name ?? 'No Voice Actor'}-$index');

                return GestureDetector(
                  onTap: () {
                    if (itemData != null) {
                      showCharacterStaffSheet(context,
                          item: itemData, isCharacter: false);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    constraints: BoxConstraints(maxWidth: isDesktop ? 150 : 108),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(16.multiplyRoundness()),
                          child: Stack(
                            children: [
                              Hero(
                                tag: tag,
                                child: AnymeXImage(
                                  imageUrl: itemData?.image ??
                                      'https://s4.anilist.co/file/anilistcdn/character/large/default.jpg',
                                  radius: 0,
                                  height: isDesktop ? 210 : 160,
                                  width: double.infinity,
                                ),
                              ),
                              if (itemData != null)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Iconsax.microphone5,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          characterName ?? '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: "Poppins-Bold",
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inverseSurface
                                                  .opaque(0.9)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                        ),
                                        const SizedBox(width: 3),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          itemData?.name ?? 'No Voice Actor',
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontFamily: "Poppins-SemiBold"),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]
      ],
    );
  }
}

class StaffCarousel extends StatelessWidget {
  final List<Staff> staff;
  const StaffCarousel({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) return const SizedBox.shrink();
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text("Staff",
              style: TextStyle(
                  fontFamily: "Poppins-SemiBold",
                  fontSize: 18,
                  color: context.colors.primary)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: isDesktop ? 290 : 210,
          child: ListView.builder(
            itemCount: staff.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
            itemBuilder: (BuildContext context, int index) {
              final itemData = staff[index];
              final tag = generateTag('${itemData.name}-$index');

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                constraints: BoxConstraints(maxWidth: isDesktop ? 150 : 108),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {

                      showCharacterStaffSheet(context,
                          item: itemData, isCharacter: false);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Hero(
                              tag: tag,
                              child: AnymeXImage(
                                imageUrl: itemData.image ??
                                    'https://s4.anilist.co/file/anilistcdn/staff/large/default.jpg',
                                radius: 12.multiplyRoundness(),
                                height: isDesktop ? 210 : 160,
                                width: double.infinity,
                              ),
                            ),
                            if (itemData.role != null)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(10, 4, 5, 2),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Text(
                                    itemData.role!,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: "Poppins-Bold",
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inverseSurface
                                            .opaque(0.9)),
                                  ),
                                ),
                              )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          itemData.name ?? '??',
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              fontFamily: "Poppins-SemiBold"),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (itemData.primaryOccupations != null &&
                            itemData.primaryOccupations!.isNotEmpty)
                          Text(
                            itemData.primaryOccupations!.join(", "),
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 10,
                                color: context.colors.onSurface.withOpacity(0.7),
                                fontFamily: "Poppins"),
                            overflow: TextOverflow.ellipsis,
                          )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String generateTag(String url) {
  final randomNum = Random().nextInt(10000);
  return '$url-$randomNum';
}
