import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Media/character.dart';
import 'package:anymex/models/Media/staff.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/header.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';

import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';


import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:anymex/models/Media/voice_actor.dart';

import 'package:anymex/utils/logger.dart';
import 'package:iconsax/iconsax.dart';

import 'package:url_launcher/url_launcher.dart';

void showCharacterStaffSheet(BuildContext context, {required dynamic item, bool isCharacter = true}) {
  final theme = context.colors;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return CharacterStaffSheetContent(item: item, isCharacter: isCharacter);
    },
  );
}

class CharacterStaffSheetContent extends StatefulWidget {
  final dynamic item;
  final bool isCharacter;

  const CharacterStaffSheetContent({
    super.key, 
    required this.item, 
    this.isCharacter = true
  });

  @override
  State<CharacterStaffSheetContent> createState() => _CharacterStaffSheetContentState();
}

class _CharacterStaffSheetContentState extends State<CharacterStaffSheetContent> {
  final _spoilerBuilder = SpoilerElementBuilder();
  late RxBool isFav;
  final RxBool showOnlyOnList = false.obs;
  final RxBool isExpanded = false.obs;
  late Future<dynamic> _detailsFuture;
  final anilistAuth = Get.find<AnilistAuth>();
  final anilistData = Get.find<AnilistData>();

  @override
  void initState() {
    super.initState();
   
    try {
      if (widget.item != null) {
       
        dynamic item = widget.item;
        bool? initialFav;
        try {
          initialFav = item.isFavourite;
        } catch (e) {
          initialFav = false;
        }
        isFav = (initialFav ?? false).obs;
      } else {
        isFav = false.obs;
      }
    } catch (e) {
      Logger.i("Error initializing isFav: $e");
      isFav = false.obs;
    }

    _detailsFuture = widget.isCharacter 
        ? anilistData.getCharacterDetails(widget.item.id.toString()) 
        : anilistData.getStaffDetails(widget.item.id.toString());
    
   
    _detailsFuture.then((data) {
      if (mounted && data != null) {
        bool? remoteFav = data.isFavourite;
        
       
        bool initialFav = false;
        try {
           initialFav = widget.item.isFavourite ?? false;
        } catch (_) {}

       
        if (isFav.value == initialFav && remoteFav != null) {
          isFav.value = remoteFav;
        }
      }
    }).catchError((e) {
      Logger.i("Error loading details future: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.colors;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: FutureBuilder(
            future: _detailsFuture,
            initialData: widget.item,
            builder: (context, snapshot) {
            final dynamic fullItem = snapshot.data;
            if (snapshot.connectionState == ConnectionState.done && fullItem == null) {
               return const Center(child: Text("Failed to load details"));
            }

            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            
            
            String? initialDescription;
            try {
              initialDescription = (widget.item as dynamic).description;
            } catch (_) {}
            
            String? description = initialDescription;
            if (fullItem is Character || fullItem is Staff) {
               description = (fullItem as dynamic).description ?? initialDescription;
            }
            
         
            List<Media> initialMedia = [];
             try {
              initialMedia = (widget.item as dynamic).media ?? [];
            } catch (_) {}

            List<Media> mediaList = initialMedia;
            if (fullItem is Character || fullItem is Staff) {
              final val = (fullItem as dynamic).media;
              if (val != null) mediaList = val;
            }
            
            final List<VoiceActor> voiceActors = (fullItem is Character) ? fullItem.voiceActors : [];
            final List<Character> rawVoicedCharacters = (!widget.isCharacter && fullItem is Staff && fullItem.characters != null) 
                ? fullItem.characters! 
                : [];
            

            final Set<String> seenCharacterIds = {};
            final List<Character> voicedCharacters = [];
            for (var char in rawVoicedCharacters) {
              if (char.id != null && !seenCharacterIds.contains(char.id)) {
                seenCharacterIds.add(char.id!);
                voicedCharacters.add(char);
              }
            }
            
            String sanitizedDesc = (description ?? 'No information available.')
                .replaceAll('<br>', '\n')
                .replaceAll('<br/>', '\n')
                .replaceAll('<i>', '*')
                .replaceAll('</i>', '*')
                .replaceAll('<b>', '**')
                .replaceAll('</b>', '**');
            
            sanitizedDesc = sanitizedDesc.replaceAll('\n', '\n\n');

            final fullDescription = sanitizedDesc;

            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: widget.item.id.toString(),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AnymeXImage(
                                imageUrl: widget.item.image ?? '',
                                width: 130, 
                                height: 195, 
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AnymexText(
                                      text: widget.item.name ?? 'Unknown',
                                      size: 22,
                                      variant: TextVariant.bold,
                                      maxLines: 2,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final isCharacter = widget.isCharacter;
                                      final type = isCharacter ? 'character' : 'staff';
                                      final url = 'https://anilist.co/$type/${widget.item.id}';
                                      
                                      if (GetPlatform.isDesktop) {
                                        await Clipboard.setData(ClipboardData(text: url));
                                        snackBar("Link copied to clipboard!", duration: 2000);
                                      } else {
                                        Share.share(url);
                                      }
                                    },
                                    icon: Icon(Icons.share, color: theme.primary),
                                  ),
                                ],
                              ),
                              Builder(
                                builder: (context) {
                                  String? nativeName;
                                  if (fullItem is Character || fullItem is Staff) {
                                    nativeName = (fullItem as dynamic).nativeName;
                                  }
                                  
                                  if (nativeName != null) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        AnymexText(
                                          text: nativeName,
                                          size: 16,
                                          color: theme.onSurface.withOpacity(0.7),
                                          variant: TextVariant.semiBold,
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }
                              ),
                              const SizedBox(height: 15),
                              Obx(() => GestureDetector(
                                onTap: () async {
                                  if (!anilistAuth.isLoggedIn.value) {
                                    snackBar("Please login to favorite!");
                                    return;
                                  }
                                  
                                  
                                  bool previousState = isFav.value;
                                  isFav.value = !previousState;
                                  
                                  // Call the API
                                  bool success = await anilistAuth.toggleFavorite(
                                    id: int.parse(widget.item.id.toString()), 
                                    type: widget.isCharacter ? "CHARACTER" : "STAFF"
                                  );

                                  if (!success) {
                                    
                                    isFav.value = previousState;
                                    snackBar("Failed to update AniList");
                                  } else {
                                    snackBar(isFav.value ? "Added to Favorites" : "Removed from Favorites");
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isFav.value 
                                        ? Colors.red.withOpacity(0.2) 
                                        : theme.surfaceContainerHighest.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isFav.value ? Colors.red.withOpacity(0.5) : Colors.transparent,
                                      width: 1,
                                    )
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isFav.value ? Icons.favorite : Icons.favorite_border,
                                        color: isFav.value ? Colors.red : theme.onSurface,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      AnymexText(
                                        text: "${(){
                                          if (fullItem is Character || fullItem is Staff) {
                                            return (fullItem as dynamic).favourites;
                                          }
                                          try { 
                                            return (widget.item as dynamic).favourites; 
                                          } catch(_) { return 0; }
                                        }() ?? 0}",
                                        size: 14,
                                        variant: TextVariant.bold,
                                        color: isFav.value ? Colors.red : theme.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                              Builder(
                                builder: (context) {
                                  List<String>? occupations;
                                  try {
                                    occupations = (fullItem?.primaryOccupations ?? (widget.item as dynamic).primaryOccupations)?.cast<String>();
                                  } catch (_) {}
                                  
                                  if (!widget.isCharacter && occupations != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: AnymexText(
                                        text: occupations.join(", "),
                                        size: 12,
                                        color: theme.primary,
                                        maxLines: 2,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    height: 1, 
                    indent: 20, 
                    endIndent: 20, 
                    color: theme.onSurface.withOpacity(0.1)
                  ),
                  const SizedBox(height: 20),
                  
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isCharacter && fullItem is Character) ...[
                               _buildBioRow("Gender", fullItem.gender),
                               _buildBioRow("Age", fullItem.age),
                               _buildBioRow("Birthday", fullItem.dateOfBirth),
                               _buildBioRow("Blood Type", fullItem.bloodType),
                            ],

                            if (!widget.isCharacter && fullItem is Staff) ...[
                               _buildBioRow("Birth", fullItem.dateOfBirth),
                               _buildBioRow("Age", fullItem.age?.toString()),
                               _buildBioRow("Gender", fullItem.gender),
                               _buildBioRow("Years active", fullItem.yearsActive),
                               _buildBioRow("Hometown", fullItem.homeTown),
                               _buildBioRow("Blood Type", fullItem.bloodType),
                               
                               
                                Builder(
                                 builder: (context) {
                                   if (fullItem.bloodType != null) return const SizedBox.shrink();
                                   
                                   String? bloodType;
                                   final RegExp bloodRegex = RegExp(r"(?:\*\*|__)?Blood Type:?(?:\*\*|__)?\s*([ABO]{1,2})", caseSensitive: false);
                                   final match = bloodRegex.firstMatch(description ?? "");
                                   if (match != null) {
                                     bloodType = match.group(1);
                                   }
                                   
                                   if (bloodType != null) {
                                     return _buildBioRow("Blood Type", bloodType.toUpperCase());
                                   }
                                   return const SizedBox.shrink();
                                 }
                               ),
                            ],
                            

                            if (widget.isCharacter && (fullItem as Character).bloodType == null)
                                Builder(
                                 builder: (context) {
                                   String? bloodType;
                                   final RegExp bloodRegex = RegExp(r"(?:\*\*|__)?Blood Type:?(?:\*\*|__)?\s*([ABO]{1,2})", caseSensitive: false);
                                   final match = bloodRegex.firstMatch(description ?? "");
                                   if (match != null) {
                                     bloodType = match.group(1);
                                   }
                                   
                                   if (bloodType != null) {
                                     return _buildBioRow("Blood Type", bloodType.toUpperCase());
                                   }
                                   return const SizedBox.shrink();
                                 }
                               ),

                              
                               Builder(
                                 builder: (context) {
                                   String? height;
                                   final RegExp heightRegex = RegExp(r"(?:\*\*|__)?Height:?(?:\*\*|__)?\s*(.+?)(\n|$)", caseSensitive: false);
                                   final match = heightRegex.firstMatch(description ?? "");
                                   if (match != null) {
                                     height = match.group(1)?.trim();
                                   }
                                   
                                   if (height != null) {
                                     return _buildBioRow("Height", height);
                                   }
                                   return const SizedBox.shrink();
                                 }
                               ),

                              
                               Builder(
                                 builder: (context) {
                                    final List<String> knownKeys = [
                                      "Occupation", "Affiliation", "Grade", "Species", "Status", "Abilities", 
                                      "Level", "Family", "Cursed Technique", "Weapon", "Bounty", "Devil Fruit", "Nen Type",
                                      "Quirk", "Stand", "Guild"
                                    ];
                                    
                                    List<Widget> extractedRows = [];
                                    String tempDesc = fullDescription;
                                    
                                    for (String key in knownKeys) {
                                      
                                      final RegExp keyRegex = RegExp(r"(?:^|\n)(?:\*\*|__)?(" + RegExp.escape(key) + r"):(?:\*\*|__)?[\t ]*(.+?)(\n|$)", caseSensitive: false);
                                      final match = keyRegex.firstMatch(tempDesc);
                                      
                                      if (match != null) {
                                        String value = match.group(2)?.trim() ?? "";
                                       
                                        bool isValueAnotherKey = knownKeys.any((k) => value.startsWith("__$k") || value.startsWith("**$k"));
                                        
                                        if (value.isNotEmpty && !isValueAnotherKey) {
                                          extractedRows.add(_buildBioRow(key, value));
                                        }
                                      }
                                    }
                                    
                                    return Column(children: extractedRows);
                                 }
                               ),
                               
                               const SizedBox(height: 10),
                            
                         
                          StatefulBuilder(
                            builder: (context, setState) {
                              String displayDesc = fullDescription;
                              
                             
                              final RegExp heightLineRegex = RegExp(r"(?:^|\n)(?:\*\*|__)?Height:?(?:\*\*|__)?[\t ]*.*(\n|$)", caseSensitive: false);
                              displayDesc = displayDesc.replaceAll(heightLineRegex, "\n").trim();

                             
                              final RegExp bloodLineRegex = RegExp(r"(?:^|\n)(?:\*\*|__)?Blood Type:?(?:\*\*|__)?[\t ]*.*(\n|$)", caseSensitive: false);
                              displayDesc = displayDesc.replaceAll(bloodLineRegex, "\n").trim();
                              
                             
                               final List<String> knownKeys = [
                                      "Occupation", "Affiliation", "Grade", "Species", "Status", "Abilities", 
                                      "Level", "Family", "Cursed Technique", "Weapon", "Bounty", "Devil Fruit", "Nen Type",
                                      "Quirk", "Stand", "Guild"
                               ];
                              for (String key in knownKeys) {
                                  final RegExp keyRegex = RegExp(r"(?:^|\n)(?:\*\*|__)?(" + RegExp.escape(key) + r"):(?:\*\*|__)?[\t ]*.+?(\n|$)", caseSensitive: false);
                                  displayDesc = displayDesc.replaceAll(keyRegex, "\n").trim();
                              }

                            
                              final RegExp separatorRegex = RegExp(r"\n\s*[-_]{2,}\s*\n");
                              displayDesc = displayDesc.replaceAll(separatorRegex, "\n\n").trim();
                              
                              return Column(
                                children: [
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: isExpanded.value
                                        ? Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: MarkdownBody(
                                              data: displayDesc,
                                              onTapLink: (text, href, title) {
                                                if (href != null) {
                                                  launchUrl(Uri.parse(href));
                                                }
                                              },
                                              inlineSyntaxes: [SpoilerSyntax()],
                                              builders: {
                                                'spoiler': _spoilerBuilder,
                                              },
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(
                                                  fontSize: 14,
                                                  color: theme.onSurface.withOpacity(0.8),
                                                  fontFamily: 'Poppins',
                                                ),
                                                strong: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.primary,
                                                ),
                                                blockSpacing: 10,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  
                                  Center(
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isExpanded.value = !isExpanded.value;
                                        });
                                      },
                                      icon: Icon(
                                        isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: theme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),

                    const SizedBox(height: 30),

                    if (widget.isCharacter && voiceActors.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AnymexText(
                          text: "Voice Actors",
                          variant: TextVariant.bold,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 220, 
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: voiceActors.length,
                          itemBuilder: (context, index) {
                            final actor = voiceActors[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                    builder: (context) => CharacterStaffSheetContent(
                                      item: actor,
                                      isCharacter: false,
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                       SizedBox(
                                        height: 150,
                                        width: 100,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: AnymeXImage(
                                            imageUrl: actor.image ?? '',
                                            width: 100,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      SizedBox(
                                        height: 32,
                                        child: Center(
                                          child: AnymexText(
                                            text: actor.name ?? 'Unknown',
                                            size: 12,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            variant: TextVariant.bold,
                                          ),
                                        ),
                                      ),
                                      if (actor.language != null) ...[
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.primary.withOpacity(0.2), 
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: AnymexText(
                                            text: actor.language!,
                                            size: 10,
                                            color: theme.primary,
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    
                    if (voicedCharacters.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: AnymexText(
                          text: "Voiced Characters",
                          variant: TextVariant.bold,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200, 
                        child: _buildCharacterList(context, voicedCharacters, theme),
                      ),
                      const SizedBox(height: 30),
                      const SizedBox(height: 30),
                    ],

                    if (mediaList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnymexText(
                              text: widget.isCharacter ? "Appears In" : "Works & Roles",
                              variant: TextVariant.bold,
                              size: 16,
                            ),
                            GestureDetector(
                              onTap: () => showOnlyOnList.value = !showOnlyOnList.value,
                              child: Row(
                                children: [
                                  Obx(() => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: showOnlyOnList.value 
                                            ? theme.primary 
                                            : theme.onSurface.withOpacity(0.4),
                                        width: 2,
                                      ),
                                      color: showOnlyOnList.value 
                                          ? theme.primary 
                                          : Colors.transparent,
                                    ),
                                    child: showOnlyOnList.value 
                                        ? Icon(
                                            Icons.check, 
                                            size: 14, 
                                            color: theme.onPrimary
                                          ) 
                                        : null,
                                  )),
                                  const SizedBox(width: 10),
                                  AnymexText(
                                    text: "On My List",
                                    size: 14,
                                    color: theme.onSurface.withOpacity(0.7),
                                    variant: TextVariant.bold,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        final filteredList = showOnlyOnList.value
                            ? mediaList.where((m) => m.userStatus != null).toList()
                            : mediaList;

                        if (filteredList.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: AnymexText(
                                text: showOnlyOnList.value ? "No media found on your list" : "No media found",
                                variant: TextVariant.semiBold,
                                color: theme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          );
                        }

                        
                        final Map<int, List<Media>> groupedMedia = {};
                        final List<Media> unknownYearMedia = [];

                        for (var item in filteredList) {
                          if (item.seasonYear != null) {
                            if (!groupedMedia.containsKey(item.seasonYear)) {
                              groupedMedia[item.seasonYear!] = [];
                            }
                            groupedMedia[item.seasonYear!]!.add(item);
                          } else {
                            Logger.i("Missing seasonYear for ${item.title} (ID: ${item.id}) - StartDate: ${item.aired}");
                            unknownYearMedia.add(item);
                          }
                        }

                        
                        final sortedYears = groupedMedia.keys.toList()..sort((a, b) => b.compareTo(a));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unknownYearMedia.isNotEmpty) ...[
                               Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(child: Divider(color: theme.primary.withOpacity(0.3))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: AnymexText(
                                            text: "TBA (${unknownYearMedia.length})",
                                            variant: TextVariant.bold,
                                            size: 18,
                                            color: theme.primary,
                                          ),
                                        ),
                                        Expanded(child: Divider(color: theme.primary.withOpacity(0.3))),
                                      ],
                                    ),
                               ),
                               _buildMediaGrid(context, unknownYearMedia, theme),
                            ],
                            ...sortedYears.map((year) {
                              final mediaList = groupedMedia[year]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(child: Divider(color: theme.primary.withOpacity(0.3))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: AnymexText(
                                            text: "$year (${mediaList.length})",
                                            variant: TextVariant.bold,
                                            size: 18,
                                            color: theme.primary,
                                          ),
                                        ),
                                        Expanded(child: Divider(color: theme.primary.withOpacity(0.3))),
                                      ],
                                    ),
                                  ),
                                  _buildMediaGrid(context, mediaList, theme),
                                  const SizedBox(height: 30),
                                ],
                              );
                            }),
                          ],
                        );
                      }),
                    ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ],
      ),
          );
          },
        ),
        );
      },
      );
  }

  Widget _buildCharacterList(BuildContext context, List<Character> characters, dynamic theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        final media = character.media?.firstOrNull;

        return Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            onTap: () {
               showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: context.theme.scaffoldBackgroundColor,
                  builder: (context) => CharacterStaffSheetContent(
                    item: character,
                    isCharacter: true,
                  ),
                );
            },
            child: SizedBox(
              width: 120, 
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnymeXImage(
                        imageUrl: character.image ?? '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnymexText(
                              text: character.name ?? '?',
                              size: 12,
                              color: Colors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              variant: TextVariant.bold,
                            ),
                            if (media != null)
                              AnymexText(
                                text: media.title,
                                size: 10,
                                color: theme.primary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<Media> mediaList, dynamic theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 15, 
        runSpacing: 15,
        alignment: WrapAlignment.start,
        children: mediaList.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final tag = "${item.id}-${widget.isCharacter ? 'char' : 'staff'}-$index";
          
          return SizedBox(
            width: 120,
            child: GestureDetector(
              onTap: () {
                Get.to(() => AnimeDetailsPage(
                  media: item, 
                  tag: tag
                ));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   AspectRatio(
                    aspectRatio: 0.7, 
                    child: Stack(
                      children: [
                        Hero(
                          tag: tag,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).cardColor,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AnymeXImage(
                                imageUrl: item.poster,
                                width: double.infinity, 
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                       
                        if (item.characterRole != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(5, 20, 5, 5),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                    Colors.black,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                              child: Text(
                                item.characterRole?.toUpperCase() ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.primary,
                                  fontSize: 8, 
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3.0,
                                      color: Colors.black.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
    
                        // Rating thing
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Iconsax.star1, size: 10, color: theme.primary),
                                const SizedBox(width: 2),
                                Text(
                                  item.rating.isNotEmpty ? item.rating : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
    
                        // Format
                        if (item.type.isNotEmpty) ...[
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                    item.type.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnymexText(
                    text: item.title,
                    variant: TextVariant.bold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    size: 11,
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
    
}

class SpoilerWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const SpoilerWidget({
    super.key, 
    required this.text,
    this.style,
  });

  @override
  State<SpoilerWidget> createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<SpoilerWidget> {
  bool isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final revealedStyle = widget.style?.copyWith(
      color: theme.colorScheme.onSurface,
      decoration: TextDecoration.none,
      decorationColor: Colors.transparent, 
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          isRevealed = !isRevealed;
        });
      },
      child: isRevealed
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Text(
                widget.text.isNotEmpty ? widget.text : 'Spoilers',
                style: revealedStyle,
              ),
            )
          : Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.eye_slash,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Spoiler",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class SpoilerSyntax extends md.InlineSyntax {
  SpoilerSyntax() : super(r'~!((?:.|\n)*?)!~');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('spoiler', match[1] ?? '');
    parser.addNode(element);
    return true;
  }
}

class SpoilerElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return SpoilerWidget(
      text: element.textContent,
      style: preferredStyle,
    );
  }
}

extension _CharacterStaffSheetExtension on _CharacterStaffSheetContentState {
  Widget _buildBioRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: AnymexText(
              text: "$label:",
              size: 14,
              variant: TextVariant.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnymexText(
              text: value,
              size: 14,
              maxLines: 10,
              variant: TextVariant.semiBold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
