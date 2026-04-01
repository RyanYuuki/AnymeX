import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:anymex/controllers/services/anilist/anilist_auth.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';

void showStudioDetailsSheet(
    BuildContext context, int studioId, String studioName) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: GestureDetector(
              onTap: () {},
              child: Align(
                alignment: Alignment.bottomCenter,
                child: StudioDetailsSheetContent(
                  studioId: studioId,
                  studioName: studioName,
                ),
              ),
            ),
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    ),
  );
}

class StudioDetailsSheetContent extends StatefulWidget {
  final int studioId;
  final String studioName;

  const StudioDetailsSheetContent({
    super.key,
    required this.studioId,
    required this.studioName,
  });

  @override
  State<StudioDetailsSheetContent> createState() =>
      _StudioDetailsSheetContentState();
}

class _StudioDetailsSheetContentState extends State<StudioDetailsSheetContent> {
  Map<String, List<Media>>? _yearMedia;
  int _favouritesCount = 0;
  bool _isLoading = true;
  final RxBool showOnlyOnList = false.obs;
  late RxBool isFav;
  final anilistAuth = Get.find<AnilistAuth>();

  @override
  void initState() {
    super.initState();
    _initFavoriteStatus();
    _loadStudioData();
  }

  void _initFavoriteStatus() {
    final user = anilistAuth.profileData.value;
    if (user.favourites?.studios != null) {
      final isFavorited = user.favourites!.studios
          .any((s) => s.id == widget.studioId.toString());
      isFav = isFavorited.obs;
    } else {
      isFav = false.obs;
    }
  }

  Future<void> _loadStudioData() async {
    try {
      final data = await AnilistData.fetchStudioDetails(widget.studioId);
      if (mounted) {
        setState(() {
          _yearMedia = data.$1;
          _favouritesCount = data.$2;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          child: SingleChildScrollView(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnymexText(
                          text: widget.studioName,
                          variant: TextVariant.bold,
                          size: 20,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          isMarquee: true,
                        ),
                      ),
                      Obx(() => GestureDetector(
                            onTap: () async {
                              if (!anilistAuth.isLoggedIn.value) {
                                snackBar("Please login to favorite!");
                                return;
                              }

                              bool previousState = isFav.value;
                              isFav.value = !previousState;

                              setState(() {
                                if (isFav.value) {
                                  _favouritesCount++;
                                } else {
                                  _favouritesCount--;
                                }
                              });

                              bool success = await anilistAuth.toggleFavorite(
                                  id: widget.studioId, type: "STUDIO");

                              if (!success) {
                                isFav.value = previousState;
                                setState(() {
                                  if (!isFav.value) {
                                    _favouritesCount--;
                                  } else {
                                    _favouritesCount++;
                                  }
                                });
                                snackBar("Failed to update AniList");
                              } else {
                                snackBar(isFav.value
                                    ? "Added to Favorites"
                                    : "Removed from Favorites");
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: isFav.value
                                      ? Colors.red.withOpacity(0.2)
                                      : theme.surfaceContainerHighest
                                          .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isFav.value
                                        ? Colors.red.withOpacity(0.5)
                                        : Colors.transparent,
                                    width: 1,
                                  )),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFav.value
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFav.value
                                        ? Colors.red
                                        : theme.onSurface,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  AnymexText(
                                    text: "$_favouritesCount",
                                    size: 14,
                                    variant: TextVariant.bold,
                                    color: isFav.value
                                        ? Colors.red
                                        : theme.onSurface,
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: theme.onSurface.withOpacity(0.1),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_yearMedia == null || _yearMedia!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: AnymexText(
                        text: 'No media found for this studio',
                        variant: TextVariant.regular,
                        size: 16,
                        color: theme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                else
                  _buildMediaList(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaList(BuildContext context) {
    final theme = context.colors;

    return Obx(() {
      final Map<String, List<Media>> filteredYearMedia = {};

      for (final entry in _yearMedia!.entries) {
        final filteredList = showOnlyOnList.value
            ? entry.value.where((m) => m.userStatus != null).toList()
            : entry.value;

        if (filteredList.isNotEmpty) {
          filteredYearMedia[entry.key] = filteredList;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => showOnlyOnList.value = !showOnlyOnList.value,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
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
                          ? Icon(Icons.check, size: 14, color: theme.onPrimary)
                          : null,
                    ),
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
            ),
          ),
          const SizedBox(height: 20),
          if (filteredYearMedia.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: AnymexText(
                  text: showOnlyOnList.value
                      ? "No media found on your list"
                      : "No media found",
                  variant: TextVariant.semiBold,
                  color: theme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          else
            ...filteredYearMedia.entries.map((entry) {
              final year = entry.key;
              final mediaList = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                            child:
                                Divider(color: theme.primary.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: AnymexText(
                            text: "$year (${mediaList.length})",
                            variant: TextVariant.bold,
                            size: 18,
                            color: theme.primary,
                          ),
                        ),
                        Expanded(
                            child:
                                Divider(color: theme.primary.withOpacity(0.3))),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.start,
                      children: mediaList.map((media) {
                        return _buildMediaCard(context, media);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            }),
        ],
      );
    });
  }

  Widget _buildMediaCard(BuildContext context, Media media) {
    final colorScheme = context.colors;

    return SizedBox(
      width: 120,
      child: GestureDetector(
        onTap: () {
          navigate(
            () => AnimeDetailsPage(
              media: media,
              tag: media.id.toString(),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            AspectRatio(
              aspectRatio: 0.7,
              child: Hero(
                tag: media.id.toString(),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).cardColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          media.poster,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.movie_outlined,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.3),
                              size: 40,
                            ),
                          ),
                        ),
                        // Rating badge
                        if (media.rating != '0.0' && media.rating != '0')
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 2),
                                  AnymexText(
                                    text: media.rating,
                                    variant: TextVariant.bold,
                                    size: 10,
                                    color: Colors.white,
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
            const SizedBox(height: 6),
            // Title
            AnymexText(
              text: media.title,
              variant: TextVariant.semiBold,
              size: 12,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
