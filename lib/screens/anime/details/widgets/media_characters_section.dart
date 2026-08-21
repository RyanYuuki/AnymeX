import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/widgets/character_staff_sheet.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/utils/ui_extensions/sizing.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:flutter/material.dart';

Widget buildCharactersSection(BuildContext context, Media media) {
  final characters = media.characters ?? [];
  if (characters.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnymeXText('Characters${media.mediaType.isManga ? '' : ' & Voice Actors'}',
          size: 16,
          variant: TextVariant.bold,
          color: context.colors.primary,
        ),
      ),
      SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            return buildCharacterCard(context, characters[index]);
          },
        ),
      ),
    ],
  ).bottomSpacing(16);
}

Widget buildCharacterCard(BuildContext context, Character character) {
  final colors = context.colors;
  final vaList = character.voiceActors;
  final va = vaList.isNotEmpty ? vaList.first : null;
  final charImage = character.image ?? '';

  return GestureDetector(
    onTap: () {
      showCharacterStaffSheet(context, item: character, isCharacter: true);
    },
    child: Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.opaque(0.3, iReallyMeanIt: true),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.onSurface.opaque(0.08, iReallyMeanIt: true),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 55,
                  height: 80,
                  child: AnymeXImage(
                    imageUrl: charImage,
                  ),
                ),
              ),
              if (character.favourites != null && character.favourites! > 0)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 8,
                          color: context.colors.primary,
                        ),
                        const SizedBox(width: 2),
                        AnymeXText(character.favourites.toString(),
                          size: 8,
                          color: Colors.white,
                          variant: TextVariant.bold,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnymeXText(character.name ?? 'Unknown',
                  size: 13,
                  variant: TextVariant.bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AnymeXText(character.role ?? 'Main',
                  size: 11,
                  color: colors.onSurface.opaque(0.6, iReallyMeanIt: true),
                ),
                if (va != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.mic_rounded, size: 12, color: colors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AnymeXText(va.name ?? 'Unknown VA',
                          size: 11,
                          variant: TextVariant.semiBold,
                          color: colors.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (va != null && (va.image ?? '').isNotEmpty) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 70,
                child: AnymeXImage(
                  imageUrl: va.image!,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
