import 'dart:convert';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel/carousel_data.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/big_carousel.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/future_reusable_carousel.dart';
import 'package:anymex/widgets/common/reusable_carousel.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher_string.dart';

Widget buildSection(String title, dynamic data,
    {DataVariant variant = DataVariant.regular,
    bool isLoading = false,
    ItemType type = ItemType.anime,
    Source? source}) {
  if (data is Stream) {
    return StreamBuilder(
      stream: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildLoader(title);
        }
        return ReusableCarousel(
          data: snapshot.data ?? [],
          title: title,
          type: type,
          variant: variant,
          isLoading: isLoading,
          source: source,
        );
      },
    );
  }
  return ReusableCarousel(
    data: data,
    title: title,
    type: type,
    variant: variant,
    isLoading: isLoading,
    source: source,
  );
}

Widget buildUnderratedSection(String title, List<UnderratedMedia> data,
    {ItemType type = ItemType.anime}) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _UnderratedCarousel(
    title: title,
    data: data,
    type: type,
  );
}

Widget buildLoader(String title) {
  return ReusableCarousel(
    data: const [],
    title: title,
    isLoading: true,
  );
}

Container buildChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
    decoration: BoxDecoration(
      color: Get.theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(10),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: AnymexText(
        text: label,
        variant: TextVariant.bold,
        color: Get.theme.colorScheme.onPrimary,
        size: 14,
      ),
    ),
  );
}

Widget buildBigCarousel(List<Media> data, bool isManga, {CarouselType? type}) {
  return BigCarousel(
      data: data,
      carouselType:
          type ?? (isManga ? CarouselType.manga : CarouselType.anime));
}

Widget buildMangaSection(String title, List<Media> data,
    {bool isAnilist = false}) {
  return ReusableCarousel(
    data: data,
    title: title,
    type: ItemType.manga,
    variant: isAnilist ? DataVariant.anilist : DataVariant.regular,
  );
}

Widget buildUnderratedMangaSection(String title, List<UnderratedMedia> data) {
  if (data.isEmpty) return const SizedBox.shrink();
  return _UnderratedCarousel(
    title: title,
    data: data,
    type: ItemType.manga,
  );
}

Widget buildFutureSection(
  String title,
  Future<List<dynamic>> future, {
  DataVariant variant = DataVariant.regular,
  ItemType type = ItemType.anime,
  Source? source,
  Widget? errorWidget,
  Widget? emptyWidget,
}) {
  return FutureReusableCarousel(
    future: future,
    title: title,
    variant: variant,
    type: type,
    source: source,
    errorWidget: errorWidget,
    emptyWidget: emptyWidget,
  );
}

class _UnderratedCarousel extends StatelessWidget {
  final String title;
  final List<UnderratedMedia> data;
  final ItemType type;

  const _UnderratedCarousel({
    required this.title,
    required this.data,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardHeight = getCardHeight(
        CardStyle.values[settingsController.cardStyle], getPlatform(context));

    if (data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: "Poppins-SemiBold",
                fontSize: 17,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 15, top: 5, bottom: 10),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return _UnderratedCard(
                  item: item,
                  type: type,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderratedCard extends StatefulWidget {
  final UnderratedMedia item;
  final ItemType type;

  const _UnderratedCard({
    required this.item,
    required this.type,
  });

  @override
  State<_UnderratedCard> createState() => _UnderratedCardState();
}

class _UnderratedCardState extends State<_UnderratedCard> {
  VoteResult? _votes;
  String? _userVote; // 'up', 'down', or null
  bool _votingLoading = false;

  @override
  void initState() {
    super.initState();
    if (UnderratedService.votingEnabled) _loadVotes();
  }

  String get _mediaType {
    final id = widget.item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return widget.type == ItemType.manga ? 'manga' : 'anime';
  }

  String get _mediaId {
    final id = widget.item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  Future<void> _loadVotes() async {
    final result =
        await UnderratedService.fetchVotes(_mediaType, _mediaId);
    if (mounted) setState(() => _votes = result);
  }

  Future<void> _castVote(String direction) async {
    if (_votingLoading) return;
    final serviceHandler = Get.find<ServiceHandler>();
    final onlineService = serviceHandler.onlineService;

    // get user identity
    int? anilistId;
    int? malId;
    int? simklId;
    String displayName = 'User';

    final profile = onlineService.profileData.value;
    final serviceType = serviceHandler.serviceType.value;

    if (serviceType == ServicesType.anilist) {
      anilistId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    } else if (serviceType == ServicesType.mal) {
      malId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    } else if (serviceType == ServicesType.simkl) {
      simklId = int.tryParse(profile.id ?? '');
      displayName = profile.name ?? 'User';
    }

    if (anilistId == null && malId == null && simklId == null) return;

    setState(() => _votingLoading = true);

    // toggle: if already voted same direction, remove vote
    final effectiveDirection =
        _userVote == direction ? 'remove' : direction;

    final result = await UnderratedService.castVote(
      mediaType: _mediaType,
      mediaId: _mediaId,
      direction: effectiveDirection == 'remove' ? direction : direction,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
      displayName: displayName,
    );

    if (mounted) {
      setState(() {
        _votingLoading = false;
        if (result != null) {
          _votes = result;
          _userVote = _userVote == direction ? null : direction;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final cardWidth = isDesktop ? 160.0 : 118.0;
    final carouselData =
        widget.item.toCarouselData(isManga: widget.type == ItemType.manga);
    final tag =
        'underrated-${carouselData.id}-${widget.item.media.hashCode}';

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      onLongPress: () => _showPeekPopup(context),
      child: SizedBox(
        width: cardWidth,
        child: Stack(
          children: [
            MediaCardGate(
              itemData: carouselData,
              tag: tag,
              variant: DataVariant.underrated,
              cardStyle: CardStyle.values[settingsController.cardStyle],
              type: widget.type,
            ),
            if (widget.item.author != null &&
                widget.item.author!.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: _buildAuthorBadge(context, theme),
              ),
            // Vote buttons — only shown if BOT_BASE_URL + BOT_API_SECRET are set
            if (UnderratedService.votingEnabled)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildVoteBar(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteBar(ThemeData theme) {
    final upvotes = _votes?.upvotes ?? 0;
    final downvotes = _votes?.downvotes ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.88),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: _votingLoading
          ? const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _VoteButton(
                  icon: Icons.thumb_up_rounded,
                  count: upvotes,
                  active: _userVote == 'up',
                  activeColor: Colors.green,
                  onTap: () => _castVote('up'),
                ),
                _VoteButton(
                  icon: Icons.thumb_down_rounded,
                  count: downvotes,
                  active: _userVote == 'down',
                  activeColor: Colors.red,
                  onTap: () => _castVote('down'),
                ),
              ],
            ),
    );
  }

  Widget _buildAuthorBadge(BuildContext context, ThemeData theme) {
    final serviceHandler = Get.find<ServiceHandler>();
    final serviceType = serviceHandler.serviceType.value;
    final isAnilist = serviceType == ServicesType.anilist;
    final author = widget.item.usernameFor(serviceType);
    final avatarUrl = widget.item.avatarFor(serviceType);
    final hasAuthor = author != null && author.isNotEmpty;

    final badge = Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.only(
        left: 3,
        right: 10,
        top: 3,
        bottom: 3,
      ),
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.85),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: _AuthorAvatar(
              avatarUrl: avatarUrl,
              fallbackLabel: author,
              size: 24,
            ),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: AutoSizeText(
              author ?? 'Unknown',
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'Poppins-SemiBold',
                color: theme.colorScheme.onSecondaryContainer,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );

    if (!hasAuthor) return badge;

    return GestureDetector(
      onTap: () => _navigateToAuthorProfile(context, isAnilist),
      behavior: HitTestBehavior.opaque,
      child: badge,
    );
  }

  Future<void> _navigateToAuthorProfile(
      BuildContext context, bool isAnilist) async {
    if (isAnilist && widget.item.anilistUserId != null) {
      navigate(() => UserProfilePage(userId: widget.item.anilistUserId!));
    } else if (widget.item.malUsername != null &&
        widget.item.malUsername!.isNotEmpty) {
      launchUrlString(
          'https://myanimelist.net/profile/${widget.item.malUsername}');
    }
  }

  void _showPeekPopup(BuildContext context) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    MediaPeekPopup.show(
      context,
      widget.item.media,
      widget.type,
      'underrated-${widget.item.media.id}',
      author: widget.item.usernameFor(serviceType),
      avatarUrl: widget.item.avatarFor(serviceType),
      reason: widget.item.reason,
      anilistUserId: widget.item.anilistUserId,
      malUserId: widget.item.malUserId,
      anilistUsername: widget.item.anilistUsername,
      malUsername: widget.item.malUsername,
    );
  }

  void _navigateToDetails(BuildContext context) {
    final media = widget.item.media;
    final tag = 'underrated-${media.id}';
    if (widget.type == ItemType.manga) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MangaDetailsPage(media: media, tag: tag),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailsPage(media: media, tag: tag),
        ),
      );
    }
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? activeColor : theme.colorScheme.onSurface.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontFamily: 'Poppins-SemiBold',
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackLabel;
  final double size;

  const _AuthorAvatar({
    required this.avatarUrl,
    required this.fallbackLabel,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasAvatar
          ? AnymeXImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              radius: size / 2,
            )
          : Center(
              child: Text(
                (fallbackLabel?.trim().isNotEmpty == true
                        ? fallbackLabel!.trim()[0]
                        : '?')
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}
