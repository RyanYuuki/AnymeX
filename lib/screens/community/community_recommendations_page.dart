import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/underrated_service.dart';
import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/models_convertor/carousel_mapper.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/profile/user_profile_page.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/common/cards/base_card.dart';
import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:anymex/widgets/custom_widgets/anymex_progress.dart';
import 'package:anymex/widgets/custom_widgets/custom_text.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/media_items/media_peek_popup.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CommunityRecommendationsPage extends StatefulWidget {
  final List<UnderratedMedia> data;
  final ItemType type;
  final String title;

  const CommunityRecommendationsPage({
    super.key,
    required this.data,
    required this.type,
    this.title = 'Community Recommendations',
  });

  @override
  State<CommunityRecommendationsPage> createState() =>
      _CommunityRecommendationsPageState();
}

class _CommunityRecommendationsPageState
    extends State<CommunityRecommendationsPage> {
  final Map<String, VoteResult?> _votes = {};
  final Map<String, String?> _userVotes = {};
  final Map<String, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    if (UnderratedService.votingEnabled) {
      for (final item in widget.data) {
        _loadVotes(item);
      }
    }
  }

  String _mediaType(UnderratedMedia item) {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return widget.type == ItemType.manga ? 'manga' : 'anime';
  }

  String _mediaId(UnderratedMedia item) {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  Future<void> _loadVotes(UnderratedMedia item) async {
    final id = _mediaId(item);
    final serviceHandler = Get.find<ServiceHandler>();
    final profile = serviceHandler.onlineService.profileData.value;
    final serviceType = serviceHandler.serviceType.value;

    int? anilistId;
    int? malId;
    int? simklId;

    if (serviceType == ServicesType.anilist) {
      anilistId = int.tryParse(profile.id ?? '');
    } else if (serviceType == ServicesType.mal) {
      malId = int.tryParse(profile.id ?? '');
    } else if (serviceType == ServicesType.simkl) {
      simklId = int.tryParse(profile.id ?? '');
    }

    final result = await UnderratedService.fetchVotes(
      _mediaType(item), id,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
    );
    if (mounted) {
      setState(() {
        _votes[id] = result;
        if (result != null) {
          _userVotes[id] = result.userVote;
        }
      });
    }
  }

  Future<void> _castVote(UnderratedMedia item, String direction) async {
    final id = _mediaId(item);
    if (_loading[id] == true) return;

    final serviceHandler = Get.find<ServiceHandler>();
    final profile = serviceHandler.onlineService.profileData.value;
    final serviceType = serviceHandler.serviceType.value;

    int? anilistId;
    int? malId;
    int? simklId;
    String displayName = 'User';

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

    setState(() => _loading[id] = true);

    final result = await UnderratedService.castVote(
      mediaType: _mediaType(item),
      mediaId: id,
      direction: direction,
      anilistUserId: anilistId,
      malUserId: malId,
      simklUserId: simklId,
      displayName: displayName,
    );

    if (mounted) {
      setState(() {
        _loading[id] = false;
        if (result != null) {
          _votes[id] = result;
          _userVotes[id] = result.userVote;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = getPlatform(context);
    final cardStyle = CardStyle.values[settingsController.cardStyle];
    final cardHeight = getCardHeight(cardStyle, isDesktop);
    final crossAxisCount = isDesktop ? 4 : 3;

    return Glow(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: AnymexText(
            text: widget.title,
            variant: TextVariant.semiBold,
            color: context.colors.primary,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnymexText(
                text: '${widget.data.length}',
                color: context.colors.primary.withOpacity(0.6),
                variant: TextVariant.semiBold,
              ),
            ),
          ],
        ),
        body: widget.data.isEmpty
            ? const Center(child: AnymexProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: cardHeight +
                      (UnderratedService.votingEnabled ? 38 : 0),
                ),
                itemCount: widget.data.length,
                itemBuilder: (context, index) {
                  final item = widget.data[index];
                  final id = _mediaId(item);
                  return _SeeAllCard(
                    item: item,
                    type: widget.type,
                    cardStyle: cardStyle,
                    isDesktop: isDesktop,
                    votes: _votes[id],
                    userVote: _userVotes[id],
                    isLoading: _loading[id] == true,
                    onVote: (dir) => _castVote(item, dir),
                  );
                },
              ),
      ),
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  final UnderratedMedia item;
  final ItemType type;
  final CardStyle cardStyle;
  final bool isDesktop;
  final VoteResult? votes;
  final String? userVote;
  final bool isLoading;
  final void Function(String direction) onVote;

  const _SeeAllCard({
    required this.item,
    required this.type,
    required this.cardStyle,
    required this.isDesktop,
    required this.votes,
    required this.userVote,
    required this.isLoading,
    required this.onVote,
  });

  String get _mediaType {
    final id = item.media.id;
    if (id.endsWith('*MOVIE')) return 'movie';
    if (id.endsWith('*SERIES')) return 'show';
    return type == ItemType.manga ? 'manga' : 'anime';
  }

  String get _mediaId {
    final id = item.media.id;
    if (id.contains('*')) return id.split('*').first;
    return id;
  }

  void _navigateToDetails() {
    final media = item.media;
    final tag = 'community-all-${media.id}';
    if (type == ItemType.manga) {
      navigate(() => MangaDetailsPage(media: media, tag: tag));
    } else {
      navigate(() => AnimeDetailsPage(media: media, tag: tag));
    }
  }

  void _showPeekPopup(BuildContext context) {
    final serviceType = Get.find<ServiceHandler>().serviceType.value;
    MediaPeekPopup.show(
      context,
      item.media,
      type,
      'community-all-${item.media.id}',
      author: item.usernameFor(serviceType),
      avatarUrl: item.avatarFor(serviceType),
      reason: item.reason,
      anilistUserId: item.anilistUserId,
      malUserId: item.malUserId,
      anilistUsername: item.anilistUsername,
      malUsername: item.malUsername,
      voteMediaType: _mediaType,
      voteMediaId: _mediaId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceHandler = Get.find<ServiceHandler>();
    final serviceType = serviceHandler.serviceType.value;
    final author = item.usernameFor(serviceType);
    final avatarUrl = item.avatarFor(serviceType);
    final carouselData = item.toCarouselData(isManga: type == ItemType.manga);
    final tag = 'community-all-${carouselData.id}-${item.media.hashCode}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _navigateToDetails,
            onLongPress: () => _showPeekPopup(context),
            child: Stack(
              children: [
                MediaCardGate(
                  itemData: carouselData,
                  tag: tag,
                  variant: DataVariant.underrated,
                  cardStyle: cardStyle,
                  type: type,
                ),
                if (author != null && author.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _AuthorBadge(
                      item: item,
                      author: author,
                      avatarUrl: avatarUrl,
                      serviceType: serviceType,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (UnderratedService.votingEnabled)
          _VoteBar(
            votes: votes,
            userVote: userVote,
            isLoading: isLoading,
            onVote: onVote,
          ),
      ],
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  final UnderratedMedia item;
  final String author;
  final String? avatarUrl;
  final ServicesType serviceType;
  final ThemeData theme;

  const _AuthorBadge({
    required this.item,
    required this.author,
    required this.avatarUrl,
    required this.serviceType,
    required this.theme,
  });

  void _navigateToAuthor() {
    final isAnilist = serviceType == ServicesType.anilist;
    if (isAnilist && item.anilistUserId != null) {
      navigate(() => UserProfilePage(userId: item.anilistUserId!));
    } else if (item.malUsername != null && item.malUsername!.isNotEmpty) {
      launchUrlString('https://myanimelist.net/profile/${item.malUsername}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToAuthor,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        padding:
            const EdgeInsets.only(left: 3, right: 10, top: 3, bottom: 3),
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
                  avatarUrl: avatarUrl, fallbackLabel: author, size: 24),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: AutoSizeText(
                author,
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
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final VoteResult? votes;
  final String? userVote;
  final bool isLoading;
  final void Function(String direction) onVote;

  const _VoteBar({
    required this.votes,
    required this.userVote,
    required this.isLoading,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.opaque(0.6),
        border: Border(
          top: BorderSide(color: colors.outline.withOpacity(0.08)),
        ),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: colors.primary,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: _VoteBtn(
                      icon: Icons.thumb_up_rounded,
                      count: votes?.upvotes ?? 0,
                      active: userVote == 'up',
                      isUpvote: true,
                      onTap: () => onVote('up'),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: colors.outline.withOpacity(0.12),
                  ),
                  Expanded(
                    child: _VoteBtn(
                      icon: Icons.thumb_down_rounded,
                      count: votes?.downvotes ?? 0,
                      active: userVote == 'down',
                      isUpvote: false,
                      onTap: () => onVote('down'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _VoteBtn extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;
  final bool isUpvote;
  final VoidCallback onTap;

  const _VoteBtn({
    required this.icon,
    required this.count,
    required this.active,
    required this.isUpvote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final activeColor =
        isUpvote ? colors.primary : colors.error;
    final activeBgColor = isUpvote
        ? colors.primary.opaque(0.12, iReallyMeanIt: true)
        : colors.error.opaque(0.12, iReallyMeanIt: true);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: active ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 13,
                  color: active ? activeColor : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: active ? activeColor : colors.onSurfaceVariant,
                  fontFamily: 'Poppins-SemiBold',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackLabel;
  final double size;

  const _AuthorAvatar(
      {required this.avatarUrl,
      required this.fallbackLabel,
      required this.size});

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
